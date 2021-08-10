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
import Crypto
//import ProtonCore_Services
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
        searchIndex = EncryptedSearchIndexService.shared.createSearchIndex(user.userInfo.userId)!
        EncryptedSearchIndexService.shared.createSearchIndexTable()
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
    internal var cipherForSearchIndex: EncryptedsearchAESGCMCipher? = nil
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
                    viewModel.isEncryptedSearch = true
                    return
                }
            }
        }
        return false
    }
    
    // Checks the total number of messages on the backend
    func getTotalMessages(completionHandler: @escaping () -> Void) -> Void {
        self.messageService.fetchMessages(byLabel: Message.Location.allmail.rawValue, time: 0, forceClean: false, isUnread: false) { _, response, error in
            if error == nil {
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
        self.fetchMessagesWithSemaphore(Message.Location.allmail.rawValue){ids in
        //self.fetchMessagesWithLoop(Message.Location.allmail.rawValue){ids in
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
    
    //Async/Await just available with swift 5.5 (enable again when released)
    /*func fetchMessagesWithLoop(_ mailBoxID: String, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        let messageIDs:NSMutableArray = []
        
        repeat {
            var messagesBatch: NSMutableArray = []
            let result = await self.fetchMessagesWrapper(mailBoxID, self.lastMessageTimeIndexed)
            messagesBatch = self.getMessageIDs(result)
            self.processedMessages += messagesBatch.count
            print("Processed messages: ", self.processedMessages)
            self.lastMessageTimeIndexed = self.getOldestMessageInMessageBatch(result)
            
            //add messagesBatch to all messages
            messageIDs.add(messagesBatch)
            
            //For testing purposes only
            break
        } while self.processedMessages < self.totalMessages
        
        print("Fetching messages in loop completed!")
        
        //for testing purposes only!!!
        exit(1)
        
        completionHandler(messageIDs)
    }*/
    
    //Async/Await just available with swift 5.5 (enable again when released)
    /*func fetchMessagesWrapper(_ mailboxID: String, _ time: Int) async -> NSMutableArray {
        return await withUnsafeContinuation {
            continuation in
            self.messageService.fetchMessages(byLabel: mailboxID, time: time, forceClean: false, isUnread: false) { _, result, error in
                if error == nil {
                    continuation.resume(returning: result)
                } else {
                    print("Error while fetching!")
                }
            }
        }
    }*/
    
    func fetchMessagesWithSemaphore(_ mailBoxID: String, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        let semaphore = DispatchSemaphore(value: 1)
        let group = DispatchGroup()
        let messageIDs:NSMutableArray = []
        let numberOfFetches:Int = Int(ceil(Double(self.totalMessages)/Double(self.limitPerRequest)))
        
        for _ in 0...numberOfFetches {
            group.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                semaphore.wait()
                self.messageService.fetchMessages(byLabel: mailBoxID, time: self.lastMessageTimeIndexed, forceClean: false, isUnread: false) { _, result, error in
                    if error == nil {
                        let msgIDs = self.getMessageIDs(result)
                        messageIDs.addObjects(from: msgIDs as! [Any])
                        self.processedMessages += msgIDs.count
                        self.lastMessageTimeIndexed = self.getOldestMessageInMessageBatch(result)
                    } else {
                        print("Error when fetching messages:", error!)
                    }
                    semaphore.signal()
                    group.leave()
                }
            }
        }

        //Wait to call completion handler until all message id's are here
        group.notify(queue: .main) {
            print("Fetching messages completed!")
            completionHandler(messageIDs)
        }
    }
    
    func getMessageIDs(_ response: [String:Any]?) -> NSMutableArray {
        let messages:NSArray = response!["Messages"] as! NSArray
        
        let messageIDs:NSMutableArray = []
        for message in messages{
            if let msg = message as? Dictionary<String, AnyObject> {
                messageIDs.add(msg["ID"]!)
            }
        }

        return messageIDs
    }

    func getOldestMessageInMessageBatch(_ response: [String:Any]?) -> Int {
        var time: Int = Int.max
        let messagesBatch: NSArray = response!["Messages"] as! NSArray

        for msg in messagesBatch {
            let m = msg as? Dictionary<String, AnyObject>
            let mInt = Int(truncating: m!["Time"]! as! NSNumber)
            if mInt < time {
                time = mInt
            }
        }

        return time
    }

    func getMessageObjects(_ messageIDs: NSArray, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        let group = DispatchGroup()
        let messages: NSMutableArray = []

        for msgID in messageIDs {
            group.enter()

            //Do not block main queue to avoid deadlock
            DispatchQueue.global(qos: .default).async {
                self.getMessage(msgID as! String) {
                    m in
                    messages.add(m!)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            print("Fetching message objects completed!")
            completionHandler(messages)
        }
    }

    func getMessageDetailsIfNotAvailable(_ messages: NSArray, messagesToProcess: Int, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        let group = DispatchGroup()
        let msg: NSMutableArray = []
        var processedMessageCount: Int = 0
        for m in messages {
            if (m as! Message).isDetailDownloaded {
                msg.add(m)
                processedMessageCount += 1
            } else {
                group.enter()
                //Do not block main queue to avoid deadlock
                DispatchQueue.global(qos: .default).async {
                    self.messageService.fetchMessageDetailForMessage(m as! Message, labelID: "5") { _, response, _, error in
                        if error == nil {
                            let mID: String = (m as! Message).messageID
                            self.getMessage(mID) { newM in
                                msg.add(newM!)
                                processedMessageCount += 1
                            }
                        }
                        else {
                            print("Error when fetching message details: ", error!)
                        }
                        group.leave()
                    }
                }//dispatchqueue
            }
            //print("Messages processed: ", processedMessageCount)
        }

        group.notify(queue: .main) {
            print("Fetching message details completed!")
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
                completionHandler(message)
            }
        }
    }
    
    func decryptBodyAndExtractData(_ messages: NSArray, completionHandler: @escaping () -> Void) {
        var processedMessagesCount: Int = 0
        for m in messages {
            var decryptionFailed: Bool = true
            var body: String? = ""
            do {
                body = try self.messageService.decryptBodyIfNeeded(message: m as! Message)
                decryptionFailed = false
            } catch {
                print("Error when decrypting messages: \(error).")
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
    
    func createEncryptedContent(message: Message, cleanedBody: String) -> EncryptedsearchEncryptedMessageContent? {
        //1. create decryptedMessageContent
        let decoder = JSONDecoder()
        let senderJsonData = Data(message.sender!.utf8)
        let toListJsonData: Data = message.toList.data(using: .utf8)!
        let ccListJsonData: Data = message.ccList.data(using: .utf8)!
        let bccListJsonData: Data = message.bccList.data(using: .utf8)!
        
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
        
        //2. encrypt content via gomobile
        let cipher: EncryptedsearchAESGCMCipher = self.getCipher()
        var ESEncryptedMessageContent: EncryptedsearchEncryptedMessageContent? = nil
        
        do {
            ESEncryptedMessageContent = try cipher.encrypt(decryptedMessageContent)
        } catch {
            print(error)
        }
        
        return ESEncryptedMessageContent
    }

    private func getCipher() -> EncryptedsearchAESGCMCipher {
        if self.cipherForSearchIndex == nil {   //TODO we need to regenerate the cipher if there is a switch between users
            let key: Data? = self.retrieveSearchIndexKey()
        
            let cipher: EncryptedsearchAESGCMCipher = EncryptedsearchAESGCMCipher(key!)!
            self.cipherForSearchIndex = cipher
        }
        return self.cipherForSearchIndex!
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
        
        /*if #available(iOS 13.0, *) {
            let key256 = CryptoKit.SymmetricKey(size: .bits256)
            encData = try! AES.GCM.seal(key!, using: key256).combined
        } else {
            // Fallback on earlier versions - do not encrypt key?
            encData = key
        }*/
        encData = key // disable encrypting key for testing purposes
        KeychainWrapper.keychain.set(encData!, forKey: "searchIndexKey_" + userID)
    }
    
    private func retrieveSearchIndexKey() -> Data? {
        let uid: String = self.user.userInfo.userId
        var key: Data? = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + uid)
        
        //Check if user already has an key
        if key != nil {
            var decryptedKey:Data? = nil
            /*if #available(iOS 13.0, *) {
                let box = try! AES.GCM.SealedBox(combined: key!)
                let key256 = CryptoKit.SymmetricKey(size: .bits256)
                decryptedKey = try! AES.GCM.open(box, using: key256)
            } else {
                // Fallback on earlier versions - do not decrypt key?
                decryptedKey = key
            }*/
            decryptedKey = key  //disable encrypting key for testing purposes
            
            return decryptedKey // if yes, return
        }
 
        // if no, generate a new key and then return
        key = self.generateSearchIndexKey(uid)
        return key
    }
    
    func addMessageKewordsToSearchIndex(_ message: Message, _ encryptedContent: EncryptedsearchEncryptedMessageContent?, _ decryptionFailed: Bool) -> Void {
        var hasBody: Bool = true
        if decryptionFailed {
            hasBody = false //TODO are there any other case where there is no body?
        }
        
        let location: Int = Int(Message.Location.allmail.rawValue)!
        let time: Int = Int((message.time)!.timeIntervalSince1970)
        let order: Int = Int(truncating: message.order)
        
        //let iv: String = String(decoding: (encryptedContent?.iv)!, as: UTF8.self)
        let iv: Data = (encryptedContent?.iv)!.base64EncodedData()
        //let ciphertext: String = String(decoding: (encryptedContent?.ciphertext)!, as: UTF8.self)
        let ciphertext:Data = (encryptedContent?.ciphertext)!.base64EncodedData()
        
        let _: Int64? = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex(messageID: message.messageID, time: time, labelIDs: message.labels, isStarred: message.starred, unread: message.unRead, location: location, order: order, hasBody: hasBody, decryptionFailed: decryptionFailed, encryptionIV: iv, encryptedContent: ciphertext, encryptedContentFile: "")
        //print("message inserted at row: ", row!)
    }

    //Encrypted Search
    func search(_ query: String, page: Int, completion: (([Message.ObjectIDContainer]?, NSError?) -> Void)?) {
        let error: NSError? = nil
        //TODO implement
        print("encrypted search on client side!")
        
        print("Query: ", query)
        print("Page: ", page)
        
        self.getTotalMessages {
            let searcher: EncryptedsearchSimpleSearcher = self.getSearcher(query)
            let cipher: EncryptedsearchAESGCMCipher = self.getCipher()
            let cache: EncryptedsearchCache? = self.getCache(cipher: cipher)
            var searchResults: EncryptedsearchResultList? = EncryptedsearchResultList()
            
            self.doCachedSearch(searcher: searcher, cache: cache!, searchResult: &searchResults, totalMessages: self.totalMessages)
            let numberOfResultsFoundByCachedSearch: Int = (searchResults?.length())!
            
            //Check if there are enough results from the cached search
            let searchResultPageSize: Int = 15  //TODO Why 15?
            if !searchResults!.isComplete && numberOfResultsFoundByCachedSearch <= searchResultPageSize {
                self.doIndexSearch(searcher: searcher, cipher: cipher, searchResults: &searchResults, totalMessages: self.totalMessages)
            }
            
            let messages: [Message.ObjectIDContainer]? = self.extractSearchResults(searchResults!)
            completion!(messages, error)
        }
    }

    func extractSearchResults(_ searchResults: EncryptedsearchResultList) -> [Message.ObjectIDContainer]? {
        print("Search Results: ", searchResults)
        //TODO extract search results from EncryptedsearchResultList
        // and return [Message.ObjectIDContainer]
        return nil
    }
    
    func getSearcher(_ query: String) -> EncryptedsearchSimpleSearcher {
        let contextSize: CLong = 50 // The max size of the content showed in the preview
        let keywords: EncryptedsearchStringList? = createEncryptedSearchStringList(query)   //split query into individual keywords

        let searcher: EncryptedsearchSimpleSearcher = EncryptedsearchSimpleSearcher(keywords, contextSize: contextSize)!
        return searcher
    }
    
    func getCache(cipher: EncryptedsearchAESGCMCipher) -> EncryptedsearchCache {
        let dbParams: EncryptedsearchDBParams = EncryptedSearchIndexService.shared.getDBParams(self.user.userInfo.userId)
        let cache: EncryptedsearchCache? = EncryptedSearchCacheService.shared.buildCacheForUser(userId: self.user.userinfo.userId, dbParams: dbParams, cipher: cipher)
        return cache!
    }
    
    func createEncryptedSearchStringList(_ query: String) -> EncryptedsearchStringList {
        let result: EncryptedsearchStringList? = EncryptedsearchStringList()
        let searchQueryArray: [String] = query.components(separatedBy: " ")
        searchQueryArray.forEach { q in
            result?.add(q)
        }
        return result!
    }
    
    func doIndexSearch(searcher: EncryptedsearchSimpleSearcher, cipher: EncryptedsearchAESGCMCipher, searchResults: inout EncryptedsearchResultList?, totalMessages:Int) {
        let index: EncryptedsearchIndex = self.getIndex()
        do {
            try index.openDBConnection()
        } catch {
            print("Error when opening DB connection: \(error)")
        }
        print("Successfully opened connection to searchindex...")
        
        var batchCount: Int = 0
        var previousLength: Int = 0
        if searchResults != nil {
            previousLength = searchResults!.length()
        }
        
        print("Start search...")
        while !searchResults!.isComplete && !hasEnoughResults(searchResults: searchResults!) {   //TODO add some more condition-> see Android
            let startBatchSearch: Double = NSDate().timeIntervalSince1970   //do we need it more accurate?
            
            let SEARCH_BATCH_HEAP_PERCENT = 0.1 // Percentage of heap that can be used to load messages from the index
            let SEARCH_MSG_SIZE: Double = 14000 // An estimation of how many bytes take a search message in memory
            let batchSize: Int = Int((getAppMemory() * SEARCH_BATCH_HEAP_PERCENT)/SEARCH_MSG_SIZE)
            do {
                try index.searchNewBatch(fromDB: searcher, cipher: cipher, results: searchResults, batchSize: batchSize)
                //Is that running async?
                print("search result: ", searchResults!)
                print("searchedCount: \(searchResults!.searchedCount), lastID: \(searchResults!.lastIDSearched), lasttime: \(searchResults!.lastTimeSearched), iscomplete: \(searchResults!.isComplete)")
                print("batchsize: ", batchSize)
            } catch {
                print("Error while searching... ", error)
            }
            if !hasEnoughResults(searchResults: searchResults!) {
                if previousLength != searchResults!.length() {
                    //self.publishIntermediateResults(&searchResults)
                    previousLength = searchResults!.length()
                }
                //self.publishProgress(searchResults, totalMessages)
            }
            let endBatchSearch: Double = NSDate().timeIntervalSince1970
            print("Batch \(batchCount) search. start: \(startBatchSearch), end: \(endBatchSearch), with batchsize: \(batchSize)")
            batchCount += 1
        }
        
        do {
            try index.closeDBConnection()
        } catch {
            print("Error while closing database Connection: \(error)")
        }
    }
    
    func doCachedSearch(searcher: EncryptedsearchSimpleSearcher, cache: EncryptedsearchCache, searchResult: inout EncryptedsearchResultList?, totalMessages: Int){
        let startCacheSearch: Double = NSDate().timeIntervalSince1970
        print("Start cache search...")
        do {
            try cache.search(searchResult, searcher: searcher)
        } catch {
            print("Error while searching the cache: \(error)")
        }
        let endCacheSearch: Double = NSDate().timeIntervalSince1970
        print("Cache search: start: \(startCacheSearch), end: \(endCacheSearch)")
    }
    
    func getIndex() -> EncryptedsearchIndex {
        let dbParams: EncryptedsearchDBParams = EncryptedSearchIndexService.shared.getDBParams(self.user.userInfo.userId)
        let index: EncryptedsearchIndex = EncryptedsearchIndex(dbParams)!
        return index
    }
    
    func hasEnoughResults(searchResults: EncryptedsearchResultList) -> Bool {
        let pageSize: Int = 15 // The size of a page of results in the search activity
        let page: Int = 0 // TODO
        let pageLowerBound = pageSize * (page + 1)
        return searchResults.length() >= pageLowerBound
    }
    
    /*func publishIntermediateResults(_ searchResults: inout EncryptedsearchResultList?) {
        //batchResults = extractResultpage(searchresults)
        let pageSize = 15 // The size of a page of results in the search activity
        let page = 0 //TODO set correct size
        let pageIndexLowerBound = page * pageSize
        let pageIndexUpperBound = pageIndexLowerBound + pageSize
        
        //prepareResultsPage (SearchMessages.kt)
        //val result = searchResults.get(index)
        //val message = getResultMessage(result)
        
        let result = EncryptedsearchSearchResult()
        
        searchResults?.add(result)
        
        //update UI with search results?
        //IntermediateSearchResultEvent -> SearchInfo (batchResults)
        //SearchInfo class : List<MailboxUiItem>
    }*/
    
    /*func publishProgress(_ searchResults: EncryptedsearchResultList?, _ totalMessages:Int) {
        
    }*/
    
    //Code from here: https://stackoverflow.com/a/64738201
    private func getAppMemory() -> Double {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                }
        }
        let usedMb = Float(taskInfo.phys_footprint)// / 1048576.0
        let totalMb = Float(ProcessInfo.processInfo.physicalMemory)// / 1048576.0
        //result != KERN_SUCCESS ? print("Memory used: ? of \(totalMb)") : print("Memory used: \(usedMb) of \(totalMb)")
        if result != KERN_SUCCESS {
            print("Memory used: ? of \(totalMb) (in byte)")
        } else {
            print("Memory used: \(usedMb) (in byte) of \(totalMb) (in byte)")
        }
        return Double(totalMb)
    }
}
