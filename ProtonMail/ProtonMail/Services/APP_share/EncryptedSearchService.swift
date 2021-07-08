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
            //TODO implement code in the background
            //1. download all messages locally
            NSLog("Downloading messages locally")
            ///  nonmaly fetching the message from server based on label and time. //TODO:: change to promise
            ///
            /// - Parameters:
            ///   - labelID: labelid, location id, forlder id
            ///   - time: the latest update time
            ///   - forceClean: force clean the exsition messages first
            ///   - completion: aync complete handler
            //func fetchMessages(byLabel labelID : String, time: Int, forceClean: Bool, isUnread: Bool, completion: CompletionBlock?)
            //MessageDataService:159
            
            let mailBoxID: String = "5"
            var messageIDs: NSMutableArray = []
            var messages: NSMutableArray = []   //Array containing all messages of a user
            
            self.messageService.fetchMessages(byLabel: mailBoxID, time: 0, forceClean: false, isUnread: false) { _, result, error in
                //TODO implement completion block
                if error == nil {
                    //NSLog("Messages: %@", result!)
                    //print("response: %@", result!)
                    messageIDs = self.getMessageIDs(result)
                    messages = self.getMessageDetails(messageIDs)
                    
                    print("There are so many messages:", messages.count)
                    
                    //2. decrypt messages (using the user's PGP key)
                    //MessageDataService+Decrypt.swift:38
                    //func decryptBodyIfNeeded(message: Message) throws -> String?
                } else {
                    NSLog(error as! String)
                }
                NSLog("All messages downloaded")
            }
            

            print("Finished!")
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
    
    func getMessageDetails(_ messageIDs: NSArray) -> NSMutableArray {
        //print("Iterate through messages:")
        let messages: NSMutableArray = []
        for msgID in messageIDs {
            let message:Message?  = self.getMessage(msgID as! String)
            //print(message!)
            //print("Message id 1: %s, id of message: %s", messageIDs[msg] as! String, message!.messageID)
            print(message!.messageID)

            messages.add(message!)
        }
        return messages
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

    //Encrypted Search
    func search() {
        //TODO implement
    }
}
