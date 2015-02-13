//
//  MessageExtension.swift
//  ProtonMail
//
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

import CoreData
import Foundation

extension Message {
    
    struct Attributes {
        static let entityName = "Message"
        static let locationNumber = "locationNumber"
        static let isStarred = "isStarred"
        static let messageID = "messageID"
        static let time = "time"
    }
    
    typealias CompletionBlock = MessageDataService.CompletionBlock
    
    struct Constants {
        static let starredTag = "starred"
    }
    
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
    
    func updateTag(tag: String) {
        self.tag = tag
        isStarred = tag.rangeOfString(Constants.starredTag) != nil
    }
    
    // MARK: - Private methods
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // Set nil string attributes to ""
        for (_, attribute) in entity.attributesByName as [String : NSAttributeDescription] {
            if attribute.attributeType == .StringAttributeType {
                if valueForKey(attribute.name) == nil {
                    setValue("", forKey: attribute.name)
                }
            }
        }
    }
}