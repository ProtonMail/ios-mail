//
//  EncryptedSearchService.swift
//  ProtonMail
//
//  Created by Ralph Ankele on 05.07.21.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import Foundation
import CoreData

public class EncryptedSearchService {
    //instance of Singleton
    static let shared = EncryptedSearchService()
    
    //set initializer to private - Singleton
    private init(){
        let users: UsersManager = sharedServices.get()
        user = users.firstUser!
        //TODO is the firstUser correct? Should we select user by ID?
        
        messageService = user.messageService
        
        //self.conversationStateService = user.conversationStateService
    }
    
    internal var user: UserManager!
    internal var messageService: MessageDataService
    var totalMessages: Int = 0
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
    func buildSearchIndex() -> Bool {
        //Run code in the background
        DispatchQueue.global(qos: .userInitiated).async {
            let mailBoxID: String = "5"
            var messageIDs: NSMutableArray = []
            var messages: NSMutableArray = []   //Array containing all messages of a user
            var completeMessages: NSMutableArray = []

            //1. download all messages locally
            NSLog("Downloading messages locally...")
            self.fetchMessages(mailBoxID){ids in
                messageIDs = ids
                print("# of message ids: ", messageIDs.count)

                NSLog("Downloading message objects...")
                //2. download message objects
                self.getMessageObjects(messageIDs){
                    msgs in
                    messages = msgs
                    print("# of message objects: ", messages.count)
                    
                    NSLog("Downloading message details...")
                    //3. downloads message details
                    self.getMessageDetails(messages, messagesToProcess: messages.count){
                        compMsgs in
                        completeMessages = compMsgs
                        
                        print("complete messages: ", completeMessages.count)
                        
                        NSLog("Downloading message details...")
                        //4. decrypt messages (using the user's PGP key)
                        self.decryptBodyAndExtractData(completeMessages)
                    }
                }
            }

            /*

            print("Finished!")*/
            //TODOs:
            //3. extract keywords from message
            //4. encrypt search index (using local symmetric key)
            //5. store the keywords index in a local DB(sqlite3)
        }
        DispatchQueue.main.async {
            // TODO task has completed
            // Update UI -> progress bar?
        }
        return false
    }
    
    func fetchMessages(_ mailBoxID: String, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
        self.messageService.fetchMessages(byLabel: mailBoxID, time: 0, forceClean: false, isUnread: false) { _, result, error in
            if error == nil {
                //NSLog("Messages: %@", result!)
                //print("response: %@", result!)
                var messageIDs:NSMutableArray = []
                messageIDs = self.getMessageIDs(result)
                completionHandler(messageIDs)
            } else {
                NSLog(error as! String)
            }
            //NSLog("All messages downloaded")
        }
    }
    
    func getMessageIDs(_ response: [String:Any]?) -> NSMutableArray {
        self.totalMessages = response!["Total"] as! Int
        print("Total messages found: ", self.totalMessages)
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
        for msgID in messageIDs {
            let message:Message? = self.getMessage(msgID as! String)
            messages.add(message!)
        }
        completionHandler(messages)
    }
    
    func getMessageDetails(_ messages: NSArray, messagesToProcess: Int, completionHandler: @escaping (NSMutableArray) -> Void) -> Void {
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

                        //check if last message
                        //if index == messages.count-1 {
                        if processedMessageCount == messagesToProcess {
                            completionHandler(msg)
                        }
                    }
            }
        }
    }
    
    private func getMessage(_ messageID: String) -> Message? {
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
                return message
            }
        }
        return nil
    }
    
    func decryptBodyAndExtractData(_ messages: NSArray) {
        //2. decrypt messages (using the user's PGP key)
        //MessageDataService+Decrypt.swift:38
        //func decryptBodyIfNeeded(message: Message) throws -> String?
        for message in messages {
            
            print("Message:")
            print(message)
            /*ProtonMail.ObjectBox
            print((message as! Message).isDetailDownloaded)
            
            print((message as! Message).subject)
            print("Encrypted body of message:")
            print((message as! Message).body)
            //break
            
            do {
                let body = try self.messageService.decryptBodyIfNeeded(message: message as! Message)
                print("Body of email: ", body!)
            } catch {
                print("Unexpected error: \(error).")
            }
            break*/
            break
        }
    }

    //Encrypted Search
    func search() {
        //TODO implement
    }
}
