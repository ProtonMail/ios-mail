//
//  Message.swift
//  ProtonMail
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation
import CoreData

class Message: NSManagedObject {
    struct Attributes {
        static let entityName = "Message"
        
        static let messageID = "messageID"
        static let time = "time"
    }
    
    typealias CompletionBlock = MessageDataService.CompletionBlock

    @NSManaged var expirationTime: NSDate?
    @NSManaged var hasAttachment: Bool
    @NSManaged var isEncrypted: Bool
    @NSManaged var isForwarded: Bool
    @NSManaged var isRead: Bool
    @NSManaged var isReplied: Bool
    @NSManaged var isRepliedAll: Bool
    @NSManaged var isStarred: Bool
    @NSManaged var locationNumber: NSNumber
    @NSManaged var messageID: String
    @NSManaged var recipientList: String
    @NSManaged var recipientNameList: String
    @NSManaged var sender: String
    @NSManaged var senderName: String
    @NSManaged var tag: String
    @NSManaged var time: NSDate?
    @NSManaged var title: String
    @NSManaged var totalSize: NSNumber
    
    @NSManaged var attachments: NSSet
    @NSManaged var detail: MessageDetail?
    
    // MARK: - Private variables
    
    private let starredTag = "starred"
    
    // MARK: - Public methods

    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entityForName(Attributes.entityName, inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
    }
    
    class func fetchOrCreateMessageForMessageID(messageID: String, context: NSManagedObjectContext) -> (message: Message?, error: NSError?) {
        var error: NSError?
        var message: Message?
        let fetchRequest = NSFetchRequest(entityName: Attributes.entityName)
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
    
    func fetchDetailIfNeeded(completion: CompletionBlock) {
        sharedMessageDataService.fetchMessageDetailForMessage(self, completion: completion)
    }
    
    func setIsStarred(isStarred: Bool, completion: CompletionBlock) {
        sharedMessageDataService.setMessage(self, isStarred: isStarred, completion: completion)
    }
    
    func updateTag(tag: String) {
        self.tag = tag
        isStarred = tag.rangeOfString(starredTag) != nil
    }
}
