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
    }
    
    internal var user: UserManager!
    internal var messageService: MessageDataService
    var totalMessages: Int = 0
    var limitPerRequest: Int = 1
    var lastMessageTimeIndexed: Int = 0     //stores the time of the last indexed message in case of an interrupt, or to fetch more than the limit of messages per request
    var processedMessages: Int = 0
    var processedMessagesDetailsDownloaded: Int = 0
    
    internal var searchIndex: Connection? = nil
    internal var cipherForSearchIndex: EncryptedsearchAESGCMCipher? = nil
    internal var lastSearchQuery: String = ""
    internal var searchResults: EncryptedsearchResultList? = nil
}

extension EncryptedSearchService {
    //function to build the search index needed for encrypted search
    func buildSearchIndex(_ viewModel: SettingsEncryptedSearchViewModel) -> Bool {
        self.updateCurrentUserIfNeeded()    //check that we have the correct user selected
        let startIndexingTimeStamp: Double = CFAbsoluteTimeGetCurrent()
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
                        viewModel.isEncryptedSearch = true
                        return
                    }
                }
                
                //build search index completely new
                self.downloadAllMessagesAndBuildSearchIndex(){
                    //Search index build -> update progress bar to finished?
                    print("Finished building search index!")
                    let finishedIndexingTimeStamp: Double = CFAbsoluteTimeGetCurrent()
                    self.printTiming("Building the Index", startIndexingTimeStamp, finishedIndexingTimeStamp)
                    
                    viewModel.isEncryptedSearch = true
                    return
                }
            }
        }
        return false
    }
    
    func updateSearchIndex(_ action: NSFetchedResultsChangeType, _ message: Message?) {
        switch action {
        case .delete:
            print("Delete message from search index")
            self.updateMessageMetadataInSearchIndex(message!)    //delete just triggers a move to the bin folder
        case .insert:
            print("Insert new message to search index")
            self.insertSingleMessageToSearchIndex(message!)
        case .move:
            print("Move message in search index")
            self.updateMessageMetadataInSearchIndex(message!)    //move just triggers a change in the location of the message
        case .update:
            print("Update message")
            self.updateMessageMetadataInSearchIndex(message!)
        default:
            return
        }
    }
    
    func insertSingleMessageToSearchIndex(_ message: Message) {
        
    }
    
    func deleteMessageFromSearchIndex(_ message: Message) {
        //TODO implement
    }
    
    func updateMessageMetadataInSearchIndex(_ message: Message) {
        //TODO implement
    }
    
    private func updateCurrentUserIfNeeded() -> Void {
        let users: UsersManager = sharedServices.get()
        self.user = users.firstUser
    }
    
    private func printTiming(_ title: String, _ startTime: Double, _ stopTime: Double) -> Void {
        let timeElapsed: Double = stopTime - startTime
        
        print("Time for \(title): elapsed: \(timeElapsed)s, startTimeStamp: \(startTime), stopTimeStamp: \(stopTime)")
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
        
        let startFetchingTimeStamp: Double = CFAbsoluteTimeGetCurrent()
        //1. download all messages locally
        NSLog("Downloading messages locally...")
        self.fetchMessageIDs(Message.Location.allmail.rawValue){ids in
        //self.fetchMessagesWithSemaphore(Message.Location.allmail.rawValue){ids in
        //self.fetchMessagesWithLoop(Message.Location.allmail.rawValue){ids in
            messageIDs = ids
            print("# of message ids: ", messageIDs.count)
            let finishedFetchingTimeStamp: Double = CFAbsoluteTimeGetCurrent()
            //print("# of message ids in global array: ", self.messageIDs.count)
            //exit(1) //DEBUGGING REASONS

            NSLog("Downloading message objects...")
            //2. download message objects
            self.getMessageObjects(messageIDs){
                msgs in
                messages = msgs
                print("# of message objects: ", messages.count)
                
                let startDownloadingMessageDetailTimeStamp: Double = CFAbsoluteTimeGetCurrent()
                NSLog("Downloading message details...") //if needed
                //3. downloads message details
                //self.getMessageDetailsIfNotAvailable(messages, messagesToProcess: messages.count){
                //self.getMessageDetails(messages){
                let messagesArray: [Message] = messages as! [Message]
                self.getMessageDetailsWithRecursion(messagesArray) {
                    compMsgs in
                    completeMessages = compMsgs
                    print("complete messages: ", completeMessages.count)
                    let finishedDownloadingMessageDetailTimeStamp: Double = CFAbsoluteTimeGetCurrent()
                    
                    NSLog("Decrypting messages...")
                    let startDecyptingTimeStamp: Double = CFAbsoluteTimeGetCurrent()
                    //4. decrypt messages (using the user's PGP key)
                    self.decryptBodyAndExtractData(completeMessages) {
                        //If index is build, call completion handler
                        let finishedDecryptingTimeStamp: Double = CFAbsoluteTimeGetCurrent()
                        
                        self.printTiming("Fetching message IDs from server", startFetchingTimeStamp, finishedFetchingTimeStamp)
                        self.printTiming("Downloading message details", startDownloadingMessageDetailTimeStamp, finishedDownloadingMessageDetailTimeStamp)
                        self.printTiming("Decrypting and Extracting Data", startDecyptingTimeStamp, finishedDecryptingTimeStamp)
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
    
    func fetchMessageIDs(_ mailBoxID: String,_ completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        print("Start fetching message ids...")
        self.fetchMessageWrapper(mailBoxID, 0) { messages in
            completionHandler(messages)
        }
    }
    
    func fetchMessageWrapper(_ mailboxID: String, _ time: Int, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        let group = DispatchGroup()
        let messageIDs:NSMutableArray = []
        
        group.enter()
        self.messageService.fetchMessages(byLabel: mailboxID, time: time, forceClean: false, isUnread: false) { _, result, error in
            if error == nil {
                let messagesBatch: NSMutableArray = self.getMessageIDs(result)
                //add messagesBatch to all messages
                messageIDs.addObjects(from: messagesBatch as! [Any])
                self.processedMessages += messagesBatch.count
                self.lastMessageTimeIndexed = self.getOldestMessageInMessageBatch(result)
                group.leave()
            } else {
                print("Error while fetching messages: ", error)
            }
        }
        
        //Wait to call completion handler until all message id's are here
        group.notify(queue: .main) {
            //print("Fetching batch of messages completed!")
            print("Processed messages: ", self.processedMessages)
            //self.messageIDs.addObjects(from: messageIDs as! [Any])
            //if we processed all messages then return
            if self.processedMessages >= self.totalMessages {
                completionHandler(messageIDs)
            } else {
                //call recursively
                self.fetchMessageWrapper(mailboxID, self.lastMessageTimeIndexed) { mIDs in
                    mIDs.addObjects(from: messageIDs as! [Any])
                    completionHandler(mIDs)
                }
            }
        }
    }
    
    func fetchMessagesWithSemaphore(_ mailBoxID: String, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        let semaphore = DispatchSemaphore(value: 1)
        let group = DispatchGroup()
        let messageIDs:NSMutableArray = []
        
        self.limitPerRequest = 100
        let numberOfFetches:Int = Int(ceil(Double(self.totalMessages)/Double(self.limitPerRequest)))
        
        print("total messages: ", self.totalMessages)
        print("limitperrequest: ", self.limitPerRequest)
        print("number of fetches: ", numberOfFetches)
        
        for index in 0...numberOfFetches {
            print("fetch start for index: ", index)
            group.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                semaphore.wait()
                self.messageService.fetchMessages(byLabel: mailBoxID, time: self.lastMessageTimeIndexed, forceClean: false, isUnread: false) { _, result, error in
                    //print("result: ", result)
                    if error == nil {
                        let msgIDs = self.getMessageIDs(result)
                        messageIDs.addObjects(from: msgIDs as! [Any])
                        self.processedMessages += msgIDs.count
                        self.lastMessageTimeIndexed = self.getOldestMessageInMessageBatch(result)
                    } else {
                        print("Error when fetching messages:", error!)
                    }
                    print("fetch completed for index: ", index)
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
                //print("Fetching message details completed for message: \(m.messageID)")
                //remove already processed entry from messages array
                var remaindingMessages: [Message] = messages
                if let index = remaindingMessages.firstIndex(of: m) {
                    remaindingMessages.remove(at: index)
                }
                
                //call function recursively until entire message array has been processed
                self.getMessageDetailsWithRecursion(remaindingMessages) { mWithDetails in
                    mWithDetails.addObjects(from: messagesWithDetails as! [Any])
                    completionHandler(mWithDetails)
                }
            }
        }
    }
    
    func getMessageDetailsForBatch(_ messages: NSArray, _ batchCount: Int, completionHandler: @escaping (NSMutableArray) -> Void){
        let group = DispatchGroup()
        let messageBatch: NSMutableArray = []
        
        for (index, m) in messages.enumerated() {
            group.enter()
            self.messageService.fetchMessageDetailForMessage(m as! Message, labelID: Message.Location.allmail.rawValue) { _, _, _, error in
                //print("For batch: \(batchCount), message: \(index), available memory: \(self.getCurrentlyAvailableAppMemory())")
                if error == nil {
                    let mID: String = (m as! Message).messageID
                    self.getMessage(mID) { newM in
                        messageBatch.add(newM!)
                        group.leave()
                    }
                }
                else {
                    print("Error when fetching message details: ", error!)
                }
            }
        }
        
        group.notify(queue: .main) {
            print("Fetching completed for message batch \(batchCount)!")
            completionHandler(messageBatch)
        }
    }
        
    func getMessageDetails(_ messages: NSArray, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        //let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 0)
        let batchSize: Int = 50 //TODO some calculation based on the number of available threads is most probably needed
        let numberOfBatches: Int = messages.count/batchSize
        print("There will be \(numberOfBatches) batches...")
        //split messages in batches of 50 messages each
        let messageBatches = (messages as! Array<Any>).chunks(batchSize)
        
        let results: NSMutableArray = []
        //for each batch:
        DispatchQueue.global(qos: .default).async {
            for (batchCount, batch) in messageBatches.enumerated() {
                //  download message details
                //group.enter()
                DispatchQueue.global(qos: .default).async {
                    print("Download details for batch: \(batchCount)")
                    self.getMessageDetailsForBatch(batch as NSArray, batchCount) { messageDetails in
                        //combine results
                        results.addObjects(from: messageDetails as! [Any])
                        semaphore.signal()
                        //group.leave()
                    }
                }
                //group.wait()
                semaphore.wait()
                if batchCount == numberOfBatches {
                    print("Fetching message details completed!")
                    completionHandler(results)
                }
            }
        }
        
        /*group.notify(queue: .main) {
            print("Fetching message details completed!")
            completionHandler(results)
        }*/
    }

    func getMessageDetailsIfNotAvailable(_ messages: NSArray, messagesToProcess: Int, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        let group = DispatchGroup()
        let msg: NSMutableArray = []
        var count: Int = 0
        for m in messages {
            if (m as! Message).isDetailDownloaded {
                msg.add(m)
                count += 1
                self.processedMessagesDetailsDownloaded += 1
                print("Details for message already downloaded: ", self.processedMessagesDetailsDownloaded)
            } else {
                count += 1
                group.enter()
                //Do not block main queue to avoid deadlock
                DispatchQueue.global(qos: .default).async {
                    print("Count: \(count), thread: \(Thread.current)")
                    self.messageService.fetchMessageDetailForMessage(m as! Message, labelID: "5") { _, response, _, error in
                        if error == nil {
                            let mID: String = (m as! Message).messageID
                            self.getMessage(mID) { newM in
                                msg.add(newM!)
                                //processedMessageCount += 1
                                self.processedMessagesDetailsDownloaded += 1
                                print("Messages processed: ", self.processedMessagesDetailsDownloaded)
                                group.leave()
                            }
                        }
                        else {
                            print("Error when fetching message details: ", error!)
                            group.leave()
                        }
                        //group.leave()
                    }
                }//dispatchqueue
            }
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
        
        //connect to search index database
        self.searchIndex = EncryptedSearchIndexService.shared.connectToSearchIndex(user.userInfo.userId)!
        EncryptedSearchIndexService.shared.createSearchIndexTable()
        
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
            print("Processed messages: ", processedMessagesCount)
            
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
        
        print("encrypted search on client side!")
        print("Query: ", query)
        print("Page: ", page)
        
        if query == "" {
            completion!(nil, error) //There are no results for an empty search query
        }
        
        //if search query hasn't changed, but just the page, then just display results
        if query == self.lastSearchQuery {
            if self.searchResults!.length() == 0 {
                completion!(nil, error)
            } else {
                self.extractSearchResults(self.searchResults!, page) { messages in
                    completion!(messages, error)
                }
            }
        } else {    //If there is a new search query, then trigger new search
            self.getTotalMessages {
                let searcher: EncryptedsearchSimpleSearcher = self.getSearcher(query)
                let cipher: EncryptedsearchAESGCMCipher = self.getCipher()
                let cache: EncryptedsearchCache? = self.getCache(cipher: cipher)
                self.searchResults = EncryptedsearchResultList()
                
                self.doCachedSearch(searcher: searcher, cache: cache!, searchResult: &self.searchResults, totalMessages: self.totalMessages)
                let numberOfResultsFoundByCachedSearch: Int = (self.searchResults?.length())!
                print("Results found by cache search: ", numberOfResultsFoundByCachedSearch)
                
                print("searchedCount: ", self.searchResults!.searchedCount)
                print("cacheSearchedCount: ", self.searchResults!.cacheSearchedCount)
                print("cache search done?: ", self.searchResults!.cachedSearchDone)
                print("search completed?: ", self.searchResults!.isComplete)
                print("last message id searched: ", self.searchResults!.lastIDSearched)
                print("last message time searched: ", self.searchResults!.lastTimeSearched)
                
                //Check if there are enough results from the cached search
                let searchResultPageSize: Int = 15  //TODO Why 15?
                if !self.searchResults!.isComplete && numberOfResultsFoundByCachedSearch <= searchResultPageSize {
                    print("do index search")
                    self.doIndexSearch(searcher: searcher, cipher: cipher, searchResults: &self.searchResults, totalMessages: self.totalMessages)
                }
                
                if self.searchResults!.length() == 0 {
                    completion!(nil, error)
                } else {
                    self.extractSearchResults(self.searchResults!, page) { messages in
                        //return search results when available
                        completion!(messages, error)
                    }
                }
            }
        }
    }

    func extractSearchResults(_ searchResults: EncryptedsearchResultList, _ page: Int, completionHandler: @escaping ([Message.ObjectIDContainer]?) -> Void) -> Void {
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
                let results: [Message.ObjectIDContainer]? = messages.map(ObjectBox.init)
                completionHandler(results)
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
        
        print("Start index search...")
        while !searchResults!.isComplete && !hasEnoughResults(searchResults: searchResults!) {   //TODO add some more condition-> see Android
            let startBatchSearch: Double = NSDate().timeIntervalSince1970   //do we need it more accurate?
            
            let SEARCH_BATCH_HEAP_PERCENT = 0.1 // Percentage of heap that can be used to load messages from the index
            let SEARCH_MSG_SIZE: Double = 14000 // An estimation of how many bytes take a search message in memory
            let batchSize: Int = Int((getTotalAvailableMemory() * SEARCH_BATCH_HEAP_PERCENT)/SEARCH_MSG_SIZE)
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
        //print("Start cache search...")
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
    func getTotalAvailableMemory() -> Double {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                }
        }
        //let usedMb = Float(taskInfo.phys_footprint)// / 1048576.0
        let totalMb = Float(ProcessInfo.processInfo.physicalMemory)// / 1048576.0
        //result != KERN_SUCCESS ? print("Memory used: ? of \(totalMb)") : print("Memory used: \(usedMb) of \(totalMb)")
        //if result != KERN_SUCCESS {
        //    print("Memory used: ? of \(totalMb) (in byte)")
        //} else {
        //    print("Memory used: \(usedMb) (in byte) of \(totalMb) (in byte)")
        //}
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
        //result != KERN_SUCCESS ? print("Memory used: ? of \(totalMb)") : print("Memory used: \(usedMb) of \(totalMb)")
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
}
