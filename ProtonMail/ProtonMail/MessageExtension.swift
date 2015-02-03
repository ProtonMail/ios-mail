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
        fetchRequest.predicate = NSPredicate(format: "%K == %@", "messageID", messageID)
        
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