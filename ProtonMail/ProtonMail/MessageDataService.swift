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
    typealias ReadBlock = (() -> Void)
    
    enum Location: Int, Printable {
        case draft = 1
        case inbox = 0
        case outbox = 2
        case spam = 4
        case starred = 5
        case trash = 3
        
        var description : String {
            get {
                switch(self) {
                case inbox:
                    return "Inbox"
                case draft:
                    return "Draft"
                case outbox:
                    return "Outbox"
                case spam:
                    return "Spam"
                case starred:
                    return "Starred"
                case trash:
                    return "Trash"
                }
            }
        }
        
        var moveAction: MessageAction? {
            switch(self) {
            case .inbox:
                return .inbox
            case .spam:
                return .spam
            case .trash:
                return .trash
            default:
                return nil
            }
        }
    }
    
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
    
    private let lastUpdated = LastUpdated()
    
    private var managedObjectContext: NSManagedObjectContext? {
        return sharedCoreDataService.mainManagedObjectContext
    }
    
    private var readQueue: [ReadBlock] = [] {
        didSet {
            NSLog("\(__FUNCTION__) readQueue.count: \(readQueue.count)")
        }
    }
    private let writeQueue = MessageQueue(queueName: "writeQueue")
    
    init() {
        setupMessageMonitoring()
        setupNotifications()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func fetchMessageCountForLocation(location: Location, completion: CompletionBlock?) {
        queue { () -> Void in
            let completionWrapper: CompletionBlock = {task, response, error in
                let countInfo: Dictionary<String, Int> = [
                    "unread" : response?["UnRead"] as? Int ?? 0,
                    "read" : response?["Read"] as? Int ?? 0,
                    "total" : response?["Total"] as? Int ?? 0]
                
                completion?(task, countInfo, nil)
            }
            
            sharedAPIService.messageCountForLocation(location.rawValue, completion: completionWrapper)
        }
    }
    
    func fetchMessageDetailForMessage(message: Message, completion: CompletionBlock) {
        if !message.isDetailDownloaded {
            queue() {
                let completionWrapper: CompletionBlock = { task, response, error in
                    let context = sharedCoreDataService.newManagedObjectContext()
                    
                    context.performBlock() {
                        var error: NSError?
                        let message = GRTJSONSerialization.mergeObjectForEntityName(Message.Attributes.entityName, fromJSONDictionary: response, inManagedObjectContext: context, error: &error) as Message
                        
                        if error == nil {
                            message.isDetailDownloaded = true
                            
                            error = context.saveUpstreamIfNeeded()
                        }
                        
                        if error != nil  {
                            NSLog("\(__FUNCTION__) error: \(error)")
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(task, response, error)
                        }
                    }
                }

                sharedAPIService.messageDetail(messageID: message.messageID, completion: completionWrapper)
            }
        } else {
            completion(nil, nil, nil)
        }
    }
    
    func fetchMessagesForLocation(location: Location, page: Int, completion: CompletionBlock) {
        queue() {
            let completionWrapper: CompletionBlock = { task, responseDict, error in
                if let messagesArray = responseDict?["Messages"] as? [Dictionary<String,AnyObject>] {
                    
                    let context = sharedCoreDataService.newManagedObjectContext()
                    
                    context.performBlock() {
                        var error: NSError?
                        var messages = GRTJSONSerialization.mergeObjectsForEntityName(Message.Attributes.entityName, fromJSONArray: messagesArray, inManagedObjectContext: context, error: &error)
                        
                        if error == nil {
                            for message in messages as [Message] {
                                message.locationNumber = location.rawValue
                            }
                            
                            error = context.saveUpstreamIfNeeded()
                        }
                        
                        if error != nil  {
                            NSLog("\(__FUNCTION__) error: \(error)")
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(task, responseDict, error)
                        }
                    }
                } else {
                    completion(task, responseDict, NSError.unableToParseResponse(responseDict))
                }
            }

            sharedAPIService.messageList(location.rawValue, page: page, sortedColumn: .date, order: .descending, filter: .noFilter, completion: completionWrapper)
        }
    }
    
    func fetchedResultsControllerForLocation(location: Location) -> NSFetchedResultsController? {
        
        if let moc = managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K == %i", Message.Attributes.locationNumber, location.rawValue)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        }
     
        return nil
    }
    
    // MARK: - Private methods
    
    // MARK: Notifications
    
    private func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didSignOutNotification:", name: UserDataService.Notification.didSignOut, object: nil)
        
        // TODO: add monitoring for didBecomeActive
        
    }
    
    @objc private func didSignOutNotification(notification: NSNotification) {
        if let context = managedObjectContext {
            Message.deleteAll(inContext: context)
        }
        
        lastUpdated.clear()
    }
    
    // MARK: Queue
    
    private func dequeueIfNeeded() {
        if let (uuid, messageID, actionString) = writeQueue.nextMessage() {
            if let action = MessageAction(rawValue: actionString) {
                writeQueue.isInProgress = true
                
                sharedAPIService.messageID(messageID, updateWithAction: action.rawValue) { task, response, error in
                    self.writeQueue.isInProgress = false

                    if error == nil {
                        self.writeQueue.remove(elementID: uuid)
                        self.dequeueIfNeeded()
                    } else {
                        NSLog("\(__FUNCTION__) error: \(error)")

                        // TODO: handle error
                    }
                }
                
            } else {
                NSLog("\(__FUNCTION__) Unsupported action \(actionString), removing from queue.")
                writeQueue.remove(elementID: uuid)
            }
        } else if !writeQueue.isBlocked && writeQueue.count == 0 && readQueue.count > 0 {
            readQueue.removeAtIndex(0)()
        }
    }
        
    private func queue(#message: Message, action: MessageAction) {
        writeQueue.addMessage(message.messageID, action: action.rawValue)
        
        dequeueIfNeeded()
    }
    
    private func queue(#readBlock: ReadBlock) {
        readQueue.append(readBlock)
        dequeueIfNeeded()
    }
    
    // MARK: Setup
    
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

// MARK: - Message extension

extension Message {
    
    // MARK: - Public variables
    
    var location: MessageDataService.Location {
        return MessageDataService.Location(rawValue: locationNumber.integerValue) ?? MessageDataService.Location.inbox
    }
    
    /// Removes all messages from the store.
    class func deleteAll(inContext context: NSManagedObjectContext) {
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = context
        context.deleteAll(Attributes.entityName)
    }
}
