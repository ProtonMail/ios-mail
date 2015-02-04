//
//  Message.swift
//  ProtonMail
//
//  Created by Eric Chamberlain on 1/30/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData

class Message: NSManagedObject {
    struct Attributes {
        static let messageID = "messageID"
    }

    @NSManaged var bccList: String
    @NSManaged var bccNameList: String
    @NSManaged var body: String
    @NSManaged var ccList: String
    @NSManaged var ccNameList: String
    @NSManaged var expirationTime: NSDate?
    @NSManaged var hasAttachment: Bool
    @NSManaged var header: String
    @NSManaged var isEncrypted: Bool
    @NSManaged var isForwarded: Bool
    @NSManaged var isRead: Bool
    @NSManaged var isReplied: Bool
    @NSManaged var isRepliedAll: Bool
    @NSManaged var isStarred: Bool
    @NSManaged var locationInt: Int32
    @NSManaged var messageID: String
    @NSManaged var recipientList: String
    @NSManaged var recipientNameList: String
    @NSManaged var sender: String
    @NSManaged var senderName: String
    @NSManaged var spamScore: Int32
    @NSManaged var tag: String
    @NSManaged var time: NSDate?
    @NSManaged var title: String
    @NSManaged var totalSize: Int32
    
    @NSManaged var attachments: NSSet
    
    // MARK: - Public methods

    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entityForName(Message.entityName(), inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
    }
    
    class func entityName() -> String {
        return "Message"
    }
    
    class func fetchOrCreateMessageForMessageID(messageID: String, context: NSManagedObjectContext) -> (message: Message?, error: NSError?) {
        var error: NSError?
        var message: Message?
        let fetchRequest = NSFetchRequest(entityName: entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Attributes.messageID, messageID)
        
        if let messages = context.executeFetchRequest(fetchRequest, error: &error) {
            switch(messages.count) {
            case 0:
                message = Message(context: context)
            case 1:
                message = messages.first as? Message
            default:
                message = messages.first as? Message
                NSLog("\(__FUNCTION__) messageID: \(messageID) has \(messages.count) messages.")
            }
            
            message?.messageID = messageID
        }
        
        return (message, error)
    }
    
    func setIsStarred(isStarred: Bool, completion: (NSError? -> Void)) {
        sharedMessageDataService.setMessage(self, isStarred: isStarred, completion: completion)
    }
}
