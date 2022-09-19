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
import CryptoKit
import Network
//import HTMLEmailParser

extension Array {
    func chunks(_ chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

public class EncryptedSearchService {
    //instance of Singleton
    static let shared = EncryptedSearchService()
    
    //set initializer to private - Singleton
    private init(){
        let users: UsersManager = sharedServices.get()
        user = users.firstUser! //should return the currently active user
        messageService = user.messageService
        
        //enable network monitoring for internet connection
        self.checkForNetworkConnectivity()
    }
    
    internal var user: UserManager!
    internal var messageService: MessageDataService
    var totalMessages: Int = 0
    var limitPerRequest: Int = 1
    var lastMessageTimeIndexed: Int = 0     //stores the time of the last indexed message in case of an interrupt, or to fetch more than the limit of messages per request
    var processedMessages: Int = 0
    internal var viewModel: SettingsEncryptedSearchViewModel? = nil
    
    internal var searchIndex: Connection? = nil
    internal var cipherForSearchIndex: EncryptedsearchAESGCMCipher? = nil
    internal var lastSearchQuery: String = ""
    internal var cacheSearchResults: EncryptedsearchResultList? = nil
    internal var indexSearchResults: EncryptedsearchResultList? = nil
    internal var searchState: EncryptedsearchSearchState? = nil
    internal var indexBuildingInProcess: Bool = false
    internal var eventsWhileIndexing: [MessageAction]? = []

    @available(iOS 12.0, *)
    internal static var monitorInternetConnectivity: NWPathMonitor? {
        return NWPathMonitor()
    }
    
    internal var timingsBuildIndex: NSMutableArray = []
    internal var timingsMessageFetching: NSMutableArray = []
    internal var timingsMessageDetailsFetching: NSMutableArray = []
    internal var timingsDecryptMessages: NSMutableArray = []
    internal var timingsExtractData: NSMutableArray = []
    internal var timingsCreateEncryptedContent: NSMutableArray = []
    internal var timingsWriteToDatabase: NSMutableArray = []
    
    internal var timingsParseBody: NSMutableArray = []
    internal var timingsRemoveElements: NSMutableArray = []
    internal var timingsParseCleanedContent: NSMutableArray = []
}

extension EncryptedSearchService {
    //function to build the search index needed for encrypted search
    func buildSearchIndex(_ viewModel: SettingsEncryptedSearchViewModel) -> Bool {
        self.indexBuildingInProcess = true
        self.viewModel = viewModel
        self.updateCurrentUserIfNeeded()    //check that we have the correct user selected
        self.timingsBuildIndex.add(CFAbsoluteTimeGetCurrent())  //add start time
        //Run code in the background
        DispatchQueue.global(qos: .userInitiated).async {
            NSLog("Check total number of messages on the backend")
            self.getTotalMessages() {
                print("Total messages: ", self.totalMessages)
                
                //if search index already build, and there are no new messages we can return here
                if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.user.userInfo.userId) {
                    print("Search index already exists for user!")
                    //check if search index needs updating
                    if EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.user.userInfo.userId) == self.totalMessages {
                        print("Search index already contains all available messages.")
                        //self.view?.viewModel.isEncryptedSearch = true
                        self.viewModel?.isEncryptedSearch = true
                        self.indexBuildingInProcess = false
                        return
                    }
                }
                
                //build search index completely new
                self.downloadAllMessagesAndBuildSearchIndex(){
                    //Search index build -> update progress bar to finished?
                    print("Finished building search index!")
                    self.timingsBuildIndex.add(CFAbsoluteTimeGetCurrent())  //add stop time
                    self.printTiming("Building the Index", for: self.timingsBuildIndex)
                    self.printTiming("Message Fetching", for: self.timingsMessageFetching)
                    self.printTiming("Message Details Downloading", for: self.timingsMessageDetailsFetching)
                    self.printTiming("Decrypting Data", for: self.timingsDecryptMessages)
                    self.printTiming("Extracting Data", for: self.timingsExtractData)
                    self.printTiming("Create Encrypted Content", for: self.timingsCreateEncryptedContent)
                    self.printTiming("Writing to Database", for: self.timingsWriteToDatabase)
                    
                    self.printTiming("Parse Body", for: self.timingsParseBody)
                    self.printTiming("Remove Elements", for: self.timingsRemoveElements)
                    self.printTiming("Parse Cleaned Content", for: self.timingsParseCleanedContent)
                    
                    //self.view?.viewModel.isEncryptedSearch = true
                    self.viewModel?.isEncryptedSearch = true
                    self.indexBuildingInProcess = false
                    return
                }
            }
        }
        return false
    }
    
    struct MessageAction {
        var action: NSFetchedResultsChangeType? = nil
        var message: Message? = nil
        var indexPath: IndexPath? = nil
        var newIndexPath: IndexPath? = nil
    }
    
    func updateSearchIndex(_ action: NSFetchedResultsChangeType, _ message: Message?, _ indexPath: IndexPath?, _ newIndexPath: IndexPath?) {
        if self.indexBuildingInProcess {
            let messageAction: MessageAction = MessageAction(action: action, message: message, indexPath: indexPath, newIndexPath: newIndexPath)
            self.eventsWhileIndexing!.append(messageAction)
        } else {
            //print("action type: \(action.rawValue)")
            switch action {
                case .delete:
                    print("Delete message from search index")
                    self.updateMessageMetadataInSearchIndex(message, action)    //delete just triggers a move to the bin folder
                case .insert:
                    print("Insert new message to search index")
                    self.insertSingleMessageToSearchIndex(message)
                case .move:
                    print("Move message in search index")
                    self.updateMessageMetadataInSearchIndex(message, action)    //move just triggers a change in the location of the message
                case .update:
                    print("Update message")
                    //self.updateMessageMetadataInSearchIndex(message, action)
                default:
                    return
            }
        }
    }
    
    func processEventsAfterIndexing(completionHandler: @escaping () -> Void) {
        if self.eventsWhileIndexing!.isEmpty {
            completionHandler()
        } else {
            let messageAction: MessageAction = self.eventsWhileIndexing!.removeFirst()
            self.updateSearchIndex(messageAction.action!, messageAction.message, messageAction.indexPath, messageAction.newIndexPath)
            self.processEventsAfterIndexing {
                print("Events remainding to process: \(self.eventsWhileIndexing!.count)")
            }
        }
    }
    
    func insertSingleMessageToSearchIndex(_ message: Message?) {
        //some simple error handling
        if message == nil {
            print("message nil!")
            return
        }
        
        //just insert a new message if the search index exists for the user - otherwise it needs to be build first
        if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.user.userInfo.userId) {
            //get message details
            self.getMessageDetailsWithRecursion([message!]) { result in
                self.decryptBodyAndExtractData(result) {
                    print("Sucessfully inserted new message \(message!.messageID) in search index")
                    //TODO update some flags?
                }
            }
        }
    }
    
    func deleteMessageFromSearchIndex(_ message: Message?) {
        if message == nil {
            print("message nil!")
            return
        }
        
        //just delete a message if the search index exists for the user - otherwise it needs to be build first
        if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.user.userInfo.userId) {
            EncryptedSearchIndexService.shared.removeEntryFromSearchIndex(message!.messageID)
        }
    }
    
    func deleteSearchIndex(){
        //just delete the search index if it exists
        if EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.user.userInfo.userId) {
            let result: Bool = EncryptedSearchIndexService.shared.deleteSearchIndex(for: self.user.userInfo.userId)
            //TODO do we want to do anything when deleting fails?
            if result {
                print("Search index for user \(self.user.userInfo.userId) sucessfully deleted!")
            }
        }
    }
    
    func updateMessageMetadataInSearchIndex(_ message: Message?, _ action: NSFetchedResultsChangeType) {
        if message == nil {
            print("message nil!")
            return
        }
        
        switch action {
        case .delete:
            print("DELETE: message location: \(message!.getLabelIDs()), labels: \(message!.labels)")
        case .move:
            print("MOVE: message location: \(message!.getLabelIDs()), labels: \(message!.labels)")
        case .update:
            print("UPDATE: message \(message!), labelid: \(message!.getLabelIDs()), labels: \(message!.labels)")
        default:
            return
        }
    }
    
    private func updateCurrentUserIfNeeded() -> Void {
        let users: UsersManager = sharedServices.get()
        self.user = users.firstUser
    }
    
    private func printTiming(_ title: String, for array: NSMutableArray) -> Void {
        var timeElapsed: Double = 0
        
        for index in stride(from: 0, to: array.count, by: 2) {
            let start: Double = array[index] as! Double
            let stop : Double = array[index+1] as! Double
            timeElapsed += (stop-start)
        }
        
        print("Time for \(title): elapsed: \(timeElapsed)s")
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
        self.downloadAndProcessPage(Message.Location.allmail.rawValue, 0) {
            completionHandler()
        }
    }

    func downloadAndProcessPage(_ mailboxID: String, _ time: Int, completionHandler: @escaping () -> Void) -> Void {
        let group = DispatchGroup()
        
        self.timingsMessageFetching.add(CFAbsoluteTimeGetCurrent())  //add start time
        group.enter()
        self.messageService.fetchMessages(byLabel: mailboxID, time: time, forceClean: false, isUnread: false) { _, result, error in
            if error == nil {
                let messagesBatch: NSMutableArray = self.getMessageIDs(result)
                print("Process page...")
                self.processPage(messagesBatch) {
                    print("Page successfull processed!")

                    //update processed messages
                    self.processedMessages += messagesBatch.count
                    self.lastMessageTimeIndexed = self.getOldestMessageInMessageBatch(result)

                    group.leave()
                }
            } else {
                print("Error while fetching messages: \(String(describing: error))")
            }
        }
        
        //Wait to call completion handler until all message id's are here
        group.notify(queue: .main) {
            print("Processed messages: ", self.processedMessages)
            //if we processed all messages then return
            if self.processedMessages >= self.totalMessages {
                completionHandler()
            } else {
                //call recursively
                self.downloadAndProcessPage(mailboxID, self.lastMessageTimeIndexed) {
                    completionHandler()
                }
            }
        }
    }
    
    func processPage(_ messageIDs: NSMutableArray, completionHandler: @escaping () -> Void) -> Void {
        self.getMessageObjects(messageIDs){
            messageObjects in

            NSLog("Downloading message details...")
            self.timingsMessageFetching.add(CFAbsoluteTimeGetCurrent())  //add stop time
            self.timingsMessageDetailsFetching.add(CFAbsoluteTimeGetCurrent())  //add start time
            self.getMessageDetailsWithRecursion(messageObjects as! [Message]) {
                messagesWithDetails in

                NSLog("Decrypting messages...")
                self.timingsMessageDetailsFetching.add(CFAbsoluteTimeGetCurrent())  //add stop time
                self.decryptBodyAndExtractData(messagesWithDetails) {
                    completionHandler()
                }
            }
        }
    }
    
    func getMessageIDs(_ response: [String:Any]?) -> NSMutableArray {
        let messages:NSArray = response!["Messages"] as! NSArray
        
        let messageIDs:NSMutableArray = []
        for message in messages {
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
            //print("Fetching message objects completed!")
            completionHandler(messages)
        }
    }
    
    func getMessageDetailsWithRecursion(_ messages: [Message], completionHandler: @escaping (NSMutableArray) -> Void){
        let messagesWithDetails: NSMutableArray = []
        
        print("number of messages left to fetch details: \(messages.count)")
        //stop recursion
        if messages.count == 0 {
            completionHandler(messagesWithDetails)
        } else {
            let m: Message = messages[0]//get the first message
            let group = DispatchGroup()
            
            group.enter()
            self.messageService.fetchMessageDetailForMessage(m, labelID: Message.Location.allmail.rawValue) { _, _, _, error in
                if error == nil {
                    //let mID: String = m.messageID
                    self.getMessage(m.messageID) { newMessage in
                        messagesWithDetails.add(newMessage!)
                        group.leave()
                    }
                } else {
                    print("Error when fetching message details: \(String(describing: error))")
                }
            }
            
            group.notify(queue: .main) {
                //remove already processed entry from messages array
                var remaindingMessages: [Message] = messages
                if let index = remaindingMessages.firstIndex(of: m) {
                    remaindingMessages.remove(at: index)
                }
                
                //Update UI progress bar
                DispatchQueue.main.async {
                    self.updateIndexBuildingProgress(processedMessages: self.processedMessages + (50 - remaindingMessages.count))
                }
                
                //call function recursively until entire message array has been processed
                self.getMessageDetailsWithRecursion(remaindingMessages) { mWithDetails in
                    mWithDetails.addObjects(from: messagesWithDetails as! [Any])
                    completionHandler(mWithDetails)
                }
            }
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
        
        //connect to search index database
        self.searchIndex = EncryptedSearchIndexService.shared.connectToSearchIndex(user.userInfo.userId)!
        EncryptedSearchIndexService.shared.createSearchIndexTable()
        
        for m in messages {
            var decryptionFailed: Bool = true
            
            self.timingsDecryptMessages.add(CFAbsoluteTimeGetCurrent())     // add start time
            var body: String? = ""
            do {
                body = try self.messageService.decryptBodyIfNeeded(message: m as! Message)
                decryptionFailed = false
            } catch {
                print("Error when decrypting messages: \(error).")
            }
            
            self.timingsDecryptMessages.add(CFAbsoluteTimeGetCurrent())     // add stop time
            self.timingsExtractData.add(CFAbsoluteTimeGetCurrent())     //add start time
            
            var keyWordsPerEmail: String = ""
            keyWordsPerEmail = self.extractKeywordsFromBody(bodyOfEmail: body!)
            //TODO check how to include (framework, or as pod?)
            //keyWordsPerEmail = HTMLEmailParser.EmailParserExtractData(body!, true)
            self.timingsExtractData.add(CFAbsoluteTimeGetCurrent())     //add stop time
            self.timingsCreateEncryptedContent.add(CFAbsoluteTimeGetCurrent()) //add start time
            
            var encryptedContent: EncryptedsearchEncryptedMessageContent? = nil
            encryptedContent = self.createEncryptedContent(message: m as! Message, cleanedBody: keyWordsPerEmail)
            
            self.timingsCreateEncryptedContent.add(CFAbsoluteTimeGetCurrent()) //add stop time
            self.timingsWriteToDatabase.add(CFAbsoluteTimeGetCurrent()) //add start time
            
            self.addMessageKewordsToSearchIndex(m as! Message, encryptedContent, decryptionFailed)
            
            self.timingsWriteToDatabase.add(CFAbsoluteTimeGetCurrent()) //add stop time
            
            processedMessagesCount += 1
            print("Processed messages: ", processedMessagesCount)
            
            if processedMessagesCount == messages.count {
                completionHandler()
            }
        }
    }
    
    func extractKeywordsFromBody(bodyOfEmail body: String, _ removeQuotes: Bool = true) -> String {
        var contentOfEmail: String = ""
        
        do {
            self.timingsParseBody.add(CFAbsoluteTimeGetCurrent()) //add start time
            //parse HTML email as DOM tree
            let doc: Document = try SwiftSoup.parse(body)
            self.timingsParseBody.add(CFAbsoluteTimeGetCurrent()) //add stop time
            
            self.timingsRemoveElements.add(CFAbsoluteTimeGetCurrent()) //add start time
            //remove style elements from DOM tree
            let styleElements: Elements = try doc.getElementsByTag("style")
            for s in styleElements {
                try s.remove()
            }
            
            //remove quoted text, unless the email is forwarded
            if removeQuotes {
                let (noQuoteContent, _) = try locateBlockQuotes(doc)
                self.timingsParseCleanedContent.add(CFAbsoluteTimeGetCurrent()) //add start time
                let newBodyOfEmail: Document = try SwiftSoup.parse(noQuoteContent)
                contentOfEmail = try newBodyOfEmail.text().preg_replace("\\s+", replaceto: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                self.timingsParseCleanedContent.add(CFAbsoluteTimeGetCurrent()) //add start time
            } else {
                contentOfEmail = try doc.text().preg_replace("\\s+", replaceto: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            }
            self.timingsRemoveElements.add(CFAbsoluteTimeGetCurrent()) //add start time
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
        
        print("encrypted search on client side!")
        print("Query: ", query)
        print("Page: ", page)
        
        if query == "" {
            completion!(nil, error) //There are no results for an empty search query
        }
        
        //if search query hasn't changed, but just the page, then just display results
        if query == self.lastSearchQuery {
            //TODO is searchedCount the same as searchresults.length?
            if self.searchState!.searchedCount == 0 {//self.searchResults!.length() == 0 {
                completion!(nil, error)
            } else {
                //TODO
                /*self.extractSearchResults(self.searchResults!, page) { messages in
                    completion!(messages, error)
                }*/
            }
        } else {    //If there is a new search query, then trigger new search
            let startSearch: Double = CFAbsoluteTimeGetCurrent()
            let searcher: EncryptedsearchSimpleSearcher = self.getSearcher(query)
            let cipher: EncryptedsearchAESGCMCipher = self.getCipher()
            let cache: EncryptedsearchCache? = self.getCache(cipher: cipher)
            self.searchState = EncryptedsearchSearchState()
            
            let numberOfResultsFoundByCachedSearch: Int = self.doCachedSearch(searcher: searcher, cache: cache!, searchState: &self.searchState, totalMessages: self.totalMessages)
            //print("Results found by cache search: ", numberOfResultsFoundByCachedSearch)
            
            //Check if there are enough results from the cached search
            let searchResultPageSize: Int = 15
            var numberOfResultsFoundByIndexSearch: Int = 0
            if !self.searchState!.isComplete && numberOfResultsFoundByCachedSearch <= searchResultPageSize {
                numberOfResultsFoundByIndexSearch = self.doIndexSearch(searcher: searcher, cipher: cipher, searchState: &self.searchState, resultsFoundInCache: numberOfResultsFoundByCachedSearch)
            }
            
            let endSearch: Double = CFAbsoluteTimeGetCurrent()
            print("Search finished. Time: \(endSearch-startSearch)")
            
            if numberOfResultsFoundByCachedSearch + numberOfResultsFoundByIndexSearch == 0 {
                completion!(nil, error)
            } else {
                self.extractSearchResults(self.cacheSearchResults!, page) { messagesCacheSearch in
                    if numberOfResultsFoundByIndexSearch > 0 {
                        self.extractSearchResults(self.indexSearchResults!, page) { messagesIndexSearch in
                            let combinedMessages: [Message] = messagesCacheSearch! + messagesIndexSearch!
                            let messages: [Message.ObjectIDContainer]? = combinedMessages.map(ObjectBox.init)
                            completion!(messages, error)
                        }
                    } else {
                        //no results from index search - so we only need to return results from cache search
                        let messages: [Message.ObjectIDContainer]? = messagesCacheSearch!.map(ObjectBox.init)
                        completion!(messages, error)
                    }
                }
            }
        }
    }

    func extractSearchResults(_ searchResults: EncryptedsearchResultList, _ page: Int, completionHandler: @escaping ([Message]?) -> Void) -> Void {
        let pageSize: Int = 50
        let numberOfPages: Int = Int(ceil(Double(searchResults.length()/pageSize)))
        if page > numberOfPages {
            completionHandler([])
        } else {
            let startIndex: Int = page * pageSize
            var endIndex: Int = startIndex + (pageSize-1)
            if page == numberOfPages {  //final page
                endIndex = startIndex + (searchResults.length() % pageSize)-1
            }
            
            var messages: [Message] = []
            let group = DispatchGroup()
            //for index in 0...(searchResults.length()-1) {
            for index in startIndex...endIndex {
                group.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    let res: EncryptedsearchSearchResult? = searchResults.get(index)
                    let m: EncryptedsearchMessage? = res?.message
                    self.getMessage(m!.id_) { mnew in
                        messages.append(mnew!)
                        group.leave()
                    }
                }
            }

            //Wait to call completion handler until all search results are extracted
            group.notify(queue: .main) {
                print("Extracting search results completed!")
                completionHandler(messages)
            }
        }
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
    
    func doIndexSearch(searcher: EncryptedsearchSimpleSearcher, cipher: EncryptedsearchAESGCMCipher, searchState: inout EncryptedsearchSearchState?, resultsFoundInCache:Int) -> Int {
        let startIndexSearch: Double = CFAbsoluteTimeGetCurrent()
        let index: EncryptedsearchIndex = self.getIndex()
        do {
            try index.openDBConnection()
        } catch {
            print("Error when opening DB connection: \(error)")
        }
        print("Successfully opened connection to searchindex...")
        
        var batchCount: Int = 0
        let searchFetchPageSize: Int = 150
        var resultsFound: Int = resultsFoundInCache
        print("Start index search...")
        while !searchState!.isComplete && resultsFound < searchFetchPageSize {
            let startBatchSearch: Double = CFAbsoluteTimeGetCurrent()
            
            let searchBatchHeapPercent: Double = 0.1 // Percentage of heap that can be used to load messages from the index
            let searchMsgSize: Double = 14000 // An estimation of how many bytes take a search message in memory
            let batchSize: Int = Int((getTotalAvailableMemory() * searchBatchHeapPercent)/searchMsgSize)
            do {
                self.indexSearchResults = EncryptedsearchResultList()
                self.indexSearchResults = try index.searchNewBatch(fromDB: searcher, cipher: cipher, state: searchState, batchSize: batchSize)
                resultsFound += self.indexSearchResults!.length()
            } catch {
                print("Error while searching... ", error)
            }
            let endBatchSearch: Double = CFAbsoluteTimeGetCurrent()
            print("Batch \(batchCount) search. time: \(endBatchSearch-startBatchSearch), with batchsize: \(batchSize)")
            batchCount += 1
        }
        
        do {
            try index.closeDBConnection()
        } catch {
            print("Error while closing database Connection: \(error)")
        }
        
        let endIndexSearch: Double = CFAbsoluteTimeGetCurrent()
        print("Index search finished. Time: \(endIndexSearch-startIndexSearch)")
        
        return resultsFound
    }
    
    func doCachedSearch(searcher: EncryptedsearchSimpleSearcher, cache: EncryptedsearchCache, searchState: inout EncryptedsearchSearchState?, totalMessages: Int) -> Int {
        let searchCacheDecryptedMessages: Bool = true
        if searchCacheDecryptedMessages && !searchState!.cachedSearchDone && !searchState!.isComplete {
            self.cacheSearchResults = EncryptedsearchResultList()
            let startCacheSearch: Double = CFAbsoluteTimeGetCurrent()
            do {
                self.cacheSearchResults = try cache.search(searchState, searcher: searcher)
            } catch {
                print("Error while searching the cache: \(error)")
            }
            let endCacheSearch: Double = CFAbsoluteTimeGetCurrent()
            print("Cache search: \(endCacheSearch-startCacheSearch) seconds")
            return self.cacheSearchResults!.length()
        }
        return 0
    }
    
    func getIndex() -> EncryptedsearchIndex {
        let dbParams: EncryptedsearchDBParams = EncryptedSearchIndexService.shared.getDBParams(self.user.userInfo.userId)
        let index: EncryptedsearchIndex = EncryptedsearchIndex(dbParams)!
        return index
    }
    
    //Code from here: https://stackoverflow.com/a/64738201
    func getTotalAvailableMemory() -> Double {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let re_kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                }
        }
        let totalMb = Float(ProcessInfo.processInfo.physicalMemory)// / 1048576.0
        return Double(totalMb)
    }
    
    //Code from here: https://stackoverflow.com/a/64738201
    func getCurrentlyAvailableAppMemory() -> Double {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                }
        }
        let usedMb = Float(taskInfo.phys_footprint)// / 1048576.0
        let totalMb = Float(ProcessInfo.processInfo.physicalMemory)// / 1048576.0
        var availableMemory: Double = 0
        if result != KERN_SUCCESS {
            //print("Memory used: ? of \(totalMb) (in byte)")
            availableMemory = Double(totalMb)
        } else {
            //print("Memory used: \(usedMb) (in byte) of \(totalMb) (in byte)")
            availableMemory = Double(totalMb - usedMb)
        }
        return availableMemory
    }
    
    func checkForNetworkConnectivity() {
        //If iOS 12 is available use NWPathMonitor
        if #available(iOS 12, *) {
            print("Check for network connectivity in ES")
            //start network monitoring in the background
            let queue: DispatchQueue = DispatchQueue.global(qos: .background)
            EncryptedSearchService.monitorInternetConnectivity?.start(queue: queue)

            //Check for changes in the network
            EncryptedSearchService.monitorInternetConnectivity?.pathUpdateHandler = { path in
                print("Network change detected!")
                if path.status == .satisfied {
                    print("Internet connectivity satisfied")
                }
                if path.status == .unsatisfied {
                    print("We lost Internet connection!")
                }
                if path.usesInterfaceType(.wifi) {
                    print("Wifi connection established")
                } else if path.usesInterfaceType(.cellular) {
                    print("Cellular connection established")
                }
            }
        } else {
            //TODO
        }
    }
    
    func stopCheckingForNetworkConnectivity() {
        //If iOS 12 is available use NWPathMonitor
        if #available(iOS 12, *) {
            //stop monitoring network for changes of the internet connectivity
            EncryptedSearchService.monitorInternetConnectivity?.cancel()
        } else {
            //TODO
        }
    }
    
    func updateIndexBuildingProgress(processedMessages: Int){
        //progress bar runs from 0 to 1 - normalize by totalMessages
        let updateStep: Float = Float(processedMessages)/Float(self.totalMessages)
        self.viewModel?.progressViewStatus.value = updateStep
    }
}
