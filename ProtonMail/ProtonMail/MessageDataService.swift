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
    var managedObjectContext: NSManagedObjectContext? {
        return (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext
    }
    
    func fetchMessagesForLocation(location: APIService.Location, completion: (NSError? -> Void)) {
        sharedAPIService.messageList(location, page: 1, sortedColumn: .date, order: .descending, filter: .noFilter, completion: completion)
    }
    
    func fetchedResultsControllerForLocation(location: APIService.Location) -> NSFetchedResultsController? {
        
        if let moc = managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
            
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        }
     
        return nil
    }
    
    func setMessage(message: Message, isStarred: Bool, completion: (NSError? -> Void)) {
        if isStarred {
            sharedAPIService.starMessage(message) { error in
                NSLog("error: \(error)")
            }
        } else {
            sharedAPIService.unstarMessage(message) { error in
                NSLog("error: \(error)")
            }
        }
    }
}