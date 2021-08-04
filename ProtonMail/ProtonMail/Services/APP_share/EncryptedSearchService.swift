//
//  EncryptedSearchService.swift
//  ProtonMail
//
//  Created by Ralph Ankele on 05.07.21.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import Foundation
import CoreData
import SwiftSoup
import SQLite
//import ProtonCore_Crypto
import Crypto

import CryptoKit


public class EncryptedSearchService {
    //instance of Singleton
    static let shared = EncryptedSearchService()
    
    //set initializer to private - Singleton
    private init(){
        let users: UsersManager = sharedServices.get()
        user = users.firstUser!
        //TODO is the firstUser correct? Should we select user by ID?
        
        messageService = user.messageService
        
        searchIndex = EncryptedSearchIndexService.shared.createSearchIndex()!
        EncryptedSearchIndexService.shared.createSearchIndexTable()
        
        //self.conversationStateService = user.conversationStateService
    }
    
    internal var user: UserManager!
    internal var messageService: MessageDataService
    var totalMessages: Int = 0
    var limitPerRequest: Int = 1
    var lastMessageTimeIndexed: Int = 0     //stores the time of the last indexed message in case of an interrupt, or to fetch more than the limit of messages per request
    var processedMessages: Int = 0
    
    var isInit: Bool = true
    var isRefresh: Bool = false
    
    internal var searchIndex: Connection
    //private let conversationStateService: ConversationStateService
    
    /*var viewMode: ViewMode {
        //TODO check what I actually need from here
        let singleMessageOnlyLabels: [Message.Location] = [.draft, .sent]
        if let location = Message.Location.init(rawValue: labelID),
           singleMessageOnlyLabels.contains(location),
           self.conversationStateService.viewMode == .conversation {
            return .singleMessage
        }
        return self.conversationStateService.viewMode
    }*/
}

extension EncryptedSearchService {
    //function to build the search index needed for encrypted search
    func buildSearchIndex(_ viewModel: SettingsEncryptedSearchViewModel) -> Bool {
        //Run code in the background
        DispatchQueue.global(qos: .userInitiated).async {
            NSLog("Check total number of messages on the backend")
            self.getTotalMessages() {
                print("Total messages: ", self.totalMessages)
                
                //if search index already build, and there are no new messages we can return here
                if self.isInit == false && self.isRefresh == true {
                    return
                }
                
                self.downloadAllMessagesAndBuildSearchIndex(){
                    //Search index build -> update progress bar to finished?
                    print("Finished building search index!")
                    //viewController.viewModel.isEncryptedSearch = true  //set toogle button to on
                    viewModel.isEncryptedSearch = true
                    return
                }
            }
        }
        DispatchQueue.main.async {
            //do something in parallel to building the search index
        }
        return false
    }
    
    // Checks the total number of messages on the backend
    func getTotalMessages(completionHandler: @escaping () -> Void) -> Void {
        self.messageService.fetchMessages(byLabel: Message.Location.allmail.rawValue, time: 0, forceClean: false, isUnread: false) { _, response, error in
            if error == nil {
                //print(response)
                self.totalMessages = response!["Total"] as! Int
                self.limitPerRequest = response!["Limit"] as! Int
            } else {
                NSLog("Error when parsing total # of messages: %@", error!)
            }
            completionHandler()
        }
    }
    
    // Downloads Messages and builds Search Index
    func downloadAllMessagesAndBuildSearchIndex(completionHandler: @escaping () -> Void) -> Void {
        var messageIDs: NSMutableArray = []
        var messages: NSMutableArray = []   //Array containing all messages of a user
        var completeMessages: NSMutableArray = []
        
        //1. download all messages locally
        NSLog("Downloading messages locally...")
        self.fetchMessages(Message.Location.allmail.rawValue){ids in
            messageIDs = ids
            print("# of message ids: ", messageIDs.count)

            NSLog("Downloading message objects...")
            //2. download message objects
            self.getMessageObjects(messageIDs){
                msgs in
                messages = msgs
                print("# of message objects: ", messages.count)
                
                NSLog("Downloading message details...") //if needed
                //3. downloads message details
                self.getMessageDetailsIfNotAvailable(messages, messagesToProcess: messages.count){
                    compMsgs in
                    completeMessages = compMsgs
                    
                    print("complete messages: ", completeMessages.count)
                    
                    NSLog("Decrypting messages...")
                    //4. decrypt messages (using the user's PGP key)
                    self.decryptBodyAndExtractData(completeMessages) {
                        //If index is build, call completion handler
                        completionHandler()
                    }
                }
            }
        }
    }
    
    func fetchMessages(_ mailBoxID: String, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        let messageIDs:NSMutableArray = []  //changed from var to let
        let numberOfFetches:Int = Int(ceil(Double(self.totalMessages)/Double(self.limitPerRequest)))
        //var count: Int = 0
        
        let group = DispatchGroup()
        //repeat {
        for _ in 0...numberOfFetches {
            
            group.enter()
            print("enter group")

            //Do not block main queue to avoid deadlock
            DispatchQueue.global(qos: .default).async {
                print("Fetching new messages...")
                print("Running on thread: ", Thread.current)
                self.messageService.fetchMessages(byLabel: mailBoxID, time: 0, forceClean: false, isUnread: false) { _, result, error in
                    if error == nil {
                        //NSLog("Messages: %@", result!)
                        //print("response: %@", result!)
                        let msgIDs = self.getMessageIDs(result)
                        messageIDs.addObjects(from: msgIDs as! [Any])
                        self.processedMessages += msgIDs.count
                        print("Processed messages: ", self.processedMessages)
                    } else {
                        NSLog(error as! String)
                    }
                    //count += 1
                    print("Finished fetching messages...")
                    group.leave()
                }
            }
            print("wait until fetching messages is completed...")
            //print("should be main thread: ", Thread.current.isMainThread)
            //print("thread?: ", Thread.current)
            //group.wait()    //wait for fetch to finish until next fetch
            //print("Should not be executed befor any result is returned")
        }   //end for
        //} while count < 5//self.processedMessages < self.totalMessages
        
        group.notify(queue: .main) {
            print("Fetching messages completed!")
            //return messageIDs once all are here
            completionHandler(messageIDs)
        }
    }
    
    func getMessageIDs(_ response: [String:Any]?) -> NSMutableArray {
        //self.totalMessages = response!["Total"] as! Int
        //print("Total messages found: ", self.totalMessages)
        let messages:NSArray = response!["Messages"] as! NSArray
        
        let messageIDs:NSMutableArray = []
        for message in messages{
            //messageIDs.adding(message["ID"])
            if let msg = message as? Dictionary<String, AnyObject> {
                //print(msg["ID"]!)
                messageIDs.add(msg["ID"]!)
            }
            
            //print(message)
            //break
        }
        //print("Message IDs:")
        //print(messageIDs)
        
        return messageIDs
    }
    
    func getMessageObjects(_ messageIDs: NSArray, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        //print("Iterate through messages:")
        let messages: NSMutableArray = []
        var processedMessages: Int = 0
        for msgID in messageIDs {
            self.getMessage(msgID as! String) {
                m in
                messages.add(m!)
                processedMessages += 1
                print("message: ", processedMessages)
                
                if processedMessages == messageIDs.count {
                    completionHandler(messages)
                }
            }
            
            //print("Message contains body?: ", message!.isDetailDownloaded)
            //print("Message body: ", message!.body)
            //break
        }
        
        //do I have to call it here as well?
        if processedMessages == messageIDs.count {
            completionHandler(messages)
        }
    }
    
    /*func getMessageDetails(_ messages: NSArray, messagesToProcess: Int, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        let msg: NSMutableArray = []
        var processedMessageCount: Int = 0
        for m in messages {
            self.messageService.ForcefetchDetailForMessage(m as! Message){_,_,newMessage,error in
                //print("message")
                //print(newMessage!)
                //print("error")
                //print(error!)
                if error == nil {
                    print("Processing message: ", processedMessageCount)
                    msg.add(newMessage!)
                    processedMessageCount += 1
                }
                else {
                    NSLog("Error when fetching message details: %@", error!)
                }
                
                //check if last message
                //if index == messages.count-1 {
                if processedMessageCount == messagesToProcess {
                    completionHandler(msg)
                }
            }
        }
    }*/
    
    func getMessageDetailsIfNotAvailable(_ messages: NSArray, messagesToProcess: Int, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        let msg: NSMutableArray = []
        var processedMessageCount: Int = 0
        for m in messages {
            if (m as! Message).isDetailDownloaded {
                msg.add(m)
                processedMessageCount += 1
            } else {
                self.messageService.fetchMessageDetailForMessage(m as! Message, labelID: "5") { _, response, _, error in
                    //print("Response: ", response!)
                    print("Fetching message details for message: ", (m as! Message).messageID)
                    
                    if error == nil {
                        //let abc:NSDictionary = response!["Message"] as! NSDictionary
                        //print("abc:", abc)
                        //TODO extract message id
                        let mID: String = (m as! Message).messageID
                        //call get message (from cache) -> now with details
                        //let newM:Message? = self.getMessage(mID)
                        self.getMessage(mID) { newM in
                            msg.add(newM!)
                            print("Message: (", mID, ") successfull added!")
                            processedMessageCount += 1  //increase message count if successfully added
                            
                            //if we are already finished with for loop, we have to check here to be able to return
                            if processedMessageCount == messagesToProcess {
                                completionHandler(msg)
                            }
                        }
                    }
                    else {
                        NSLog("Error: ", error!)
                    }
                    //print("Finish fetching message detail")
                }
            }
            print("Messages processed: ", processedMessageCount)
        }
        
        //check if all messages have been processed
        //do I have to check here as well?
        if processedMessageCount == messagesToProcess {
            completionHandler(msg)
        }
    }
    
    private func getMessage(_ messageID: String, completionHandler: @escaping (Message?) -> Void) -> Void {
        let fetchedResultsController = self.messageService.fetchedMessageControllerForID(messageID)
        
        if let fetchedResultsController = fetchedResultsController {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D(" error: \(ex)")
            }
        }
        
        if let context = fetchedResultsController?.managedObjectContext{
            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                //return message
                completionHandler(message)
            }
        }
        //return nil
        //completionHandler(nil)
    }
    
    func decryptBodyAndExtractData(_ messages: NSArray, completionHandler: @escaping () -> Void) {
        //2. decrypt messages (using the user's PGP key)
        var processedMessagesCount: Int = 0
        var decryptionFailed: Bool = true
        for m in messages {
            //print("Message:")
            //print((m as! Message).body)
            
            var body: String? = ""
            do {
                body = try self.messageService.decryptBodyIfNeeded(message: m as! Message)
                //print("Body of email (plaintext): ", body!)
                decryptionFailed = false
            } catch {
                print("Unexpected error: \(error).")
            }
            
            var keyWordsPerEmail: String = ""
            keyWordsPerEmail = self.extractKeywordsFromBody(bodyOfEmail: body!)
            
            var encryptedContent: EncryptedsearchEncryptedMessageContent? = nil
            encryptedContent = self.createEncryptedContent(message: m as! Message, cleanedBody: keyWordsPerEmail)
            
            self.addMessageKewordsToSearchIndex(m as! Message, encryptedContent, decryptionFailed)
            
            processedMessagesCount += 1
            
            if processedMessagesCount == messages.count {
                completionHandler()
            }
        }
    }
    
    func extractKeywordsFromBody(bodyOfEmail body: String, _ removeQuotes: Bool = true) -> String {
        var contentOfEmail: String = ""
        
        do {
            //let html = "<html><head><title>First parse</title></head>"
            //    + "<body><p>Parsed HTML into a doc.</p></body></html>"
            //parse HTML email as DOM tree
            let doc: Document = try SwiftSoup.parse(body)
            
            //remove style elements from DOM tree
            let styleElements: Elements = try doc.getElementsByTag("style")
            for s in styleElements {
                try s.remove()
            }
            
            //remove quoted text, unless the email is forwarded
            var content: String = ""
            if removeQuotes {
                let (noQuoteContent, _) = try locateBlockQuotes(doc)
                content = noQuoteContent
            } else {
                content = try doc.html()
            }
            
            let newBodyOfEmail: Document = try SwiftSoup.parse(content)
            contentOfEmail = try newBodyOfEmail.text().trim()
            //TODO replace multiple whitespaces with a single whitespace
            //i.e. in Kotlin -> .replace("\\s+", " ")
        } catch Exception.Error(_, let message) {
            print(message)
        } catch {
            print("error")
        }
        //print("content of email cleaned: ", contentOfEmail)
        
        return contentOfEmail
    }
    
    //Returns content before and after match in the source
    func split(_ source: String, _ match: String) -> (before: String, after: String) {
        if let range:Range<String.Index> = source.range(of: match) {
            let index: Int = source.distance(from: source.startIndex, to: range.lowerBound)
            let s1_index: String.Index = source.index(source.startIndex, offsetBy: index)
            let s1: String = String(source[..<s1_index])
            
            let s2_index: String.Index = source.index(s1_index, offsetBy: match.count)
            let s2: String = String(source[s2_index...])
            
            return (s1, s2)
        }
        //no match found
        return (source, "")
    }
    
    //TODO refactor
    func searchforContent(_ element: Element?, _ text: String) throws -> Elements {
        let abc: Document = (element?.ownerDocument())!
        let cde: Elements? = try abc.select(":matches(^$text$)")
        return cde!
    }
    
    func locateBlockQuotes(_ inputDocument: Element?) throws -> (String, String) {
        guard inputDocument != nil else { return ("", "") }
        
        let body: Elements? = try inputDocument?.select("body")
        
        var document: Element?
        if body!.first() != nil {
            document = body!.first()
        } else {
            document = inputDocument
        }
        
        var parentHTML: String? = ""
        if try document?.html() != nil {
            parentHTML = try document?.html()
        }
        var parentText: String? = ""
        if try document?.text() != nil {
            parentText = try document?.text()
        }
        
        var result:(String, String)? = nil
        
        func testBlockQuote(_ blockquote: Element) throws -> (String, String)? {
            let blockQuoteText: String = try blockquote.text()
            let (beforeText, afterText): (String, String) = split(parentText!, blockQuoteText)
            
            if (!(beforeText.trim().isEmpty) && (afterText.trim().isEmpty)) {
                let blockQuoteHTML: String = try blockquote.outerHtml()
                let (beforeHTML, _): (String, String) = split(parentHTML!, blockQuoteHTML)
                
                return (beforeHTML, blockQuoteHTML)
            }
            return nil
        }
        
        let blockQuoteSelectors: NSArray = [".protonmail_quote",
                                            ".gmail_quote",
                                            ".yahoo_quoted",
                                            ".gmail_extra",
                                            ".moz-cite-prefix",
                                            // '.WordSection1',
                                            "#isForwardContent",
                                            "#isReplyContent",
                                            "#mailcontent:not(table)",
                                            "#origbody",
                                            "#reply139content",
                                            "#oriMsgHtmlSeperator",
                                            "blockquote[type=\"cite\"]",
                                            "[name=\"quote\"]", // gmx
                                            ".zmail_extra", // zoho
        ]
        let blockQuoteSelector: String = blockQuoteSelectors.componentsJoined(by: ",")
        
        // Standard search with a composed query selector
        let blockQuotes: Elements? = try document?.select(blockQuoteSelector)
        try blockQuotes?.forEach({ blockquote in
            if (result == nil) {
                result = try testBlockQuote(blockquote)
            }
        })
        
        let blockQuoteTextSelectors: NSArray = ["-----Original Message-----"]
        // Second search based on text content with xpath
        if (result == nil) {
            try blockQuoteTextSelectors.forEach { text in
                if (result == nil) {
                    try searchforContent(document, text as! String).forEach { blockquote in
                        if (result == nil) {
                            result = try testBlockQuote(blockquote)
                        }
                    }
                }
            }
        }
        
        if result == nil {
            return (parentHTML!, "")
        }
        
        return result!
    }
    
    struct Sender: Codable {
        var Name: String = ""
        var Address: String = ""
    }
    
    /*struct Recipient: Codable {
        var name: String = ""
        var email: String = ""
    }
    
    struct RecipientList: Codable {
        var recipient: [Recipient?]
    }
    
    struct DecryptedMessageContent: Codable {
        var subject: String = ""
        var sender: Recipient = Recipient()
        var body: String = ""
        var toList: RecipientList = RecipientList(recipient: [nil])
        var ccList: RecipientList = RecipientList(recipient: [nil])
        var bccList: RecipientList = RecipientList(recipient: [nil])
    }*/
    
    func createEncryptedContent(message: Message, cleanedBody: String) -> EncryptedsearchEncryptedMessageContent? {
        //1. create decryptedMessageContent
        let decoder = JSONDecoder()
        let senderJsonData = Data(message.sender!.utf8)
        let toListJsonData: Data = message.toList.data(using: .utf8)!
        let ccListJsonData: Data = message.ccList.data(using: .utf8)!
        let bccListJsonData: Data = message.bccList.data(using: .utf8)!
        
        /*print("To List: ", message.toList)
        print("CC List: ", message.ccList)
        print("BCC List: ", message.bccList)
        print("Extract data from Json string... ")*/
        
        var decryptedMessageContent: EncryptedsearchDecryptedMessageContent? = EncryptedsearchDecryptedMessageContent()
        do {
            let senderStruct = try decoder.decode(Sender.self, from: senderJsonData)
            let toListStruct = try decoder.decode([Sender].self, from: toListJsonData)
            let ccListStruct = try decoder.decode([Sender].self, from: ccListJsonData)
            let bccListStruct = try decoder.decode([Sender].self, from: bccListJsonData)
            
            let sender: EncryptedsearchRecipient? = EncryptedsearchRecipient(senderStruct.Name, email: senderStruct.Address)
            let toList: EncryptedsearchRecipientList = EncryptedsearchRecipientList()
            toListStruct.forEach { s in
                let r: EncryptedsearchRecipient? = EncryptedsearchRecipient(s.Name, email: s.Address)
                toList.add(r)
            }
            let ccList: EncryptedsearchRecipientList = EncryptedsearchRecipientList()
            ccListStruct.forEach { s in
                let r: EncryptedsearchRecipient? = EncryptedsearchRecipient(s.Name, email: s.Address)
                ccList.add(r)
            }
            let bccList: EncryptedsearchRecipientList = EncryptedsearchRecipientList()
            bccListStruct.forEach { s in
                let r: EncryptedsearchRecipient? = EncryptedsearchRecipient(s.Name, email: s.Address)
                bccList.add(r)
            }
            
            decryptedMessageContent = EncryptedsearchNewDecryptedMessageContent(message.subject, sender, cleanedBody, toList, ccList, bccList)
        } catch {
            print(error)
        }
        
        //print("Decrypted Message Content (subject): ", decryptedMessageContent!.subject)
        
        //2. encrypt content via gomobile
        let cipher: EncryptedsearchAESGCMCipher = self.getCipher()
        var ESEncryptedMessageContent: EncryptedsearchEncryptedMessageContent? = nil
        
        do {
            ESEncryptedMessageContent = try cipher.encrypt(decryptedMessageContent)
            //print("Encrypted content (ciphertext): ", String(decoding: ESEncryptedMessageContent!.ciphertext!, as: UTF8.self))
            //print("Encrypted content (IV): ", String(decoding:ESEncryptedMessageContent!.iv!, as: UTF8.self))
        } catch {
            print(error)
        }
        
        return ESEncryptedMessageContent
    }
    
    private func getCipher() -> EncryptedsearchAESGCMCipher {
        let key: Data? = self.retrieveSearchIndexKey()
        
        let cipher: EncryptedsearchAESGCMCipher = EncryptedsearchAESGCMCipher(key)!
        return cipher
    }
    
    private func generateSearchIndexKey(_ userID: String) -> Data? {
        let keylen: Int = 32
        var error: NSError?
        let bytes = CryptoRandomToken(keylen, &error)
        self.storeSearchIndexKey(bytes, userID: userID)
        return bytes
    }
    
    private func storeSearchIndexKey(_ key: Data?, userID: String) {
        var encData: Data? = nil
        
        if #available(iOS 13.0, *) {
            let key256 = CryptoKit.SymmetricKey(size: .bits256)
            encData = try! AES.GCM.seal(key!, using: key256).combined
        } else {
            // Fallback on earlier versions - do not encrypt key?
            encData = key
        }
        KeychainWrapper.keychain.set(encData!, forKey: "searchIndexKey_" + userID)
    }
    
    private func retrieveSearchIndexKey() -> Data? {
        let uid: String = self.user.userInfo.userId
        var key: Data? = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + uid)
        
        //Check if user already has an key
        if key != nil {
            var decryptedKey:Data? = nil
            if #available(iOS 13.0, *) {
                let box = try! AES.GCM.SealedBox(combined: key!)
                let key256 = CryptoKit.SymmetricKey(size: .bits256)
                decryptedKey = try! AES.GCM.open(box, using: key256)
            } else {
                // Fallback on earlier versions - do not decrypt key?
                decryptedKey = key
            }
            
            return decryptedKey // if yes, return
        }
 
        // if no, generate a new key and then return
        key = self.generateSearchIndexKey(uid)
        return key
    }
    
    func addMessageKewordsToSearchIndex(_ message: Message, _ encryptedContent: EncryptedsearchEncryptedMessageContent?, _ decryptionFailed: Bool) -> Void {
        //encryptionIV, encryptedContent, encryptedConentenFile
        
        var hasBody: Bool = true
        if decryptionFailed {
            hasBody = false //TODO are there any other case where there is no body?
        }
        
        let location: Int = Int(Message.Location.allmail.rawValue)!
        let time: Int = Int((message.time)!.timeIntervalSince1970)
        let order: Int = Int(truncating: message.order)
        
        let iv: String = String(decoding: (encryptedContent?.iv)!, as: UTF8.self)
        let ciphertext: String = String(decoding: (encryptedContent?.ciphertext)!, as: UTF8.self)
        
        //print("IV: ", iv)
        //print("ciphertext: ", ciphertext)
        
        let row: Int64? = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex(messageID: message.messageID, time: time, labelIDs: message.labels, isStarred: message.starred, unread: message.unRead, location: location, order: order, hasBody: hasBody, decryptionFailed: decryptionFailed, encryptionIV: iv, encryptedContent: ciphertext, encryptedContentFile: "")
        print("message inserted at row: ", row!)
    }

    //Encrypted Search
    func search(_ query: String, page: Int, completion: (([Message.ObjectIDContainer]?, NSError?) -> Void)?) {
        let error: NSError? = nil
        //TODO implement
        print("encrypted search on client side!")
        
        print("Query: ", query)
        print("Page: ", page)
        
        self.getTotalMessages {
            //TODO get searcher
            let searcher: EncryptedsearchSimpleSearcher = self.getSearcher(query)
            let cipher: EncryptedsearchAESGCMCipher = self.getCipher()
            
            //TODO do Cached Search
            //TODO if we don't succeed with cached search, do index search
            let searchResults: EncryptedsearchResultList? = nil
            self.doIndexSearch(searcher: searcher, cipher: cipher, searchResults: searchResults!, totalMessages: self.totalMessages)
            
            //TODO extract messages from result of search
            let messages: [Message.ObjectIDContainer]? = nil
            
            completion!(messages, error)
        }
    }
    
    func getSearcher(_ query: String) -> EncryptedsearchSimpleSearcher {
        let contextSize: CLong = 50 // The max size of the content showed in the preview
        let keywords: EncryptedsearchStringList? = createEncryptedSearchStringList(query)   //split query into individual keywords

        let searcher: EncryptedsearchSimpleSearcher = EncryptedsearchSimpleSearcher(keywords, contextSize: contextSize)!
        return searcher
    }
    
    func createEncryptedSearchStringList(_ query: String) -> EncryptedsearchStringList {
        let result: EncryptedsearchStringList? = EncryptedsearchStringList()
        let searchQueryArray: [String] = query.components(separatedBy: " ")
        searchQueryArray.forEach { q in
            result?.add(q)
        }
        return result!
    }
    
    func doIndexSearch(searcher: EncryptedsearchSimpleSearcher, cipher: EncryptedsearchAESGCMCipher, searchResults: EncryptedsearchResultList, totalMessages:Int) {
        let index: EncryptedsearchIndex = getIndex()
        do {
            try index.openDBConnection()
        } catch {
            print("Error when opening DB connection: \(error)")
        }
        
        var batchCount: Int = 0
        var previousLength: Int = searchResults.length()
        
        while !searchResults.isComplete && !hasEnoughResults(searchResults: searchResults) {   //TODO add some more condition-> see Android
            var startBatchSearch: Int = 0
            
            let batchSize: Int = 0 // TODO
            do {
                try index.searchNewBatch(fromDB: searcher, cipher: cipher, results: searchResults, batchSize: batchSize)
            } catch {
                print("Error while searching... ", error)
            }
            if !hasEnoughResults(searchResults: searchResults) {
                if previousLength != searchResults.length() {
                    //TODO publish
                    previousLength = searchResults.length()
                }
                //publisheProgress
            }
            let endBatchSearch: Int = 0 //TODO time
            batchCount += 1
        }
        
        do {
            try index.closeDBConnection()
        } catch {
            print("Error while closing database Connection: \(error)")
        }
    }
    
    func getIndex() -> EncryptedsearchIndex {
        let index: EncryptedsearchIndex = EncryptedsearchIndex()
        //TODO implement
        return index
    }
    
    func hasEnoughResults(searchResults: EncryptedsearchResultList) -> Bool {
        let pageSize: Int = 15 // The size of a page of results in the search activity
        let page: Int = 0 // TODO
        let pageLowerBound = pageSize * (page + 1)
        return searchResults.length() >= pageLowerBound
    }
}
