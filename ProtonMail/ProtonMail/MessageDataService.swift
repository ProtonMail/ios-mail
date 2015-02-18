//
//  MessageDataService.swift
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

let sharedMessageDataService = MessageDataService()

class MessageDataService {
    typealias CompletionBlock = APIService.CompletionBlock
    
    enum MessageAction: String {
        
        // Read/unread
        case read = "read"
        case unread = "unread"
        
        // Star/unstar
        case star = "star"
        case unstar = "unstar"
        
        // Move mailbox
        case delete = "delete"
        case inbox = "inbox"
        case spam = "spam"
        case trash = "trash"
    }
    
    private var managedObjectContext: NSManagedObjectContext? {
        return sharedCoreDataService.mainManagedObjectContext
    }
    
    private let messageQueue = MessageQueue(queueName: "messageQueue")
    
    init() {
        setupMessageMonitoring()
        
        // TODO: add monitoring for didBecomeActive
    }
    
    /// Removes all messages from the store.
    func deleteAllMessages() {
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = managedObjectContext
        context.deleteAll(Message.Attributes.entityName)
    }
    
    func fetchMessageDetailForMessage(message: Message, completion: CompletionBlock) {
        if !message.isDetailDownloaded {
            sharedAPIService.messageDetail(message: message, completion: completion)
        } else {
            completion(nil)
        }
    }
    
    func fetchMessagesForLocation(location: APIService.Location, completion: CompletionBlock) {
        sharedAPIService.messageList(location, page: 1, sortedColumn: .date, order: .descending, filter: .noFilter, completion: completion)
    }
    
    func fetchedResultsControllerForLocation(location: APIService.Location) -> NSFetchedResultsController? {
        
        if let moc = managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K == %i", Message.Attributes.locationNumber, location.rawValue)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        }
     
        return nil
    }
    
    // MARK: - Private methods
    
    private func dequeueMessageIfNeeded() {
        if let (uuid, messageID, actionString) = messageQueue.nextMessage() {
            if let action = MessageAction(rawValue: actionString) {
                messageQueue.isInProgress = true
                
                sharedAPIService.messageID(messageID, updateWithAction: action) { error in
                    self.messageQueue.isInProgress = false
                    
                    if error == nil {
                        self.messageQueue.remove(elementID: uuid)
                        self.dequeueMessageIfNeeded()
                    } else {
                        NSLog("\(__FUNCTION__) error: \(error)")
                        
                        // TODO: handle error
                    }
                }
                
            } else {
                NSLog("\(__FUNCTION__) Unsupported action \(actionString), removing from queue.")
                messageQueue.remove(elementID: uuid)
            }
        }
    }
    
    private func queue(#message: Message, action: MessageAction) {
        messageQueue.addMessage(message.messageID, action: action.rawValue)
        
        dequeueMessageIfNeeded()
    }
    
    private func setupMessageMonitoring() {
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.locationNumber, handler: { message in
            if let action = message.location.moveAction {
                self.queue(message: message, action: action)
            } else {
                NSLog("\(__FUNCTION__) \(message.messageID) move to \(message.location) was not a user initiated move.")
            }
        })
        
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.isRead, handler: { message in
            let action: MessageAction = message.isRead ? .read : .unread
            
            self.queue(message: message, action: action)
        })
        
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.isStarred, handler: { message in
            let action: MessageAction = message.isStarred ? .star : .unstar
            
            self.queue(message: message, action: action)
        })
    }
}
