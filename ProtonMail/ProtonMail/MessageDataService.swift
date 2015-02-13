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
    
    private var managedObjectContext: NSManagedObjectContext? {
        return sharedCoreDataService.mainManagedObjectContext
    }
    
    init() {
        setupMessageMonitoring()
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
    
    func setupMessageMonitoring() {
        sharedMonitorSavesDataService.registerEntityName(Message.Attributes.entityName, attribute: Message.Attributes.isStarred, handler: { message in
            if let message = message as? Message {
                if message.isStarred {
                    sharedAPIService.starMessage(message)
                } else {
                    sharedAPIService.unstarMessage(message)
                }
            }
        })
    }

}
