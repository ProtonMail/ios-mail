//
//  MonitorSavesDataService.swift
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

import Foundation
import CoreData

let sharedMonitorSavesDataService = MonitorSavesDataService()

class MonitorSavesDataService {
    
    typealias HandlerBlock = (NSManagedObject -> Void)
    
    private var handlers: [String : [String : HandlerBlock]] = [:]
    private var monitorQueue: [NSManagedObject : [HandlerBlock]] = [:]
    
    init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MonitorSavesDataService.didSaveNotification(_:)), name: NSManagedObjectContextDidSaveNotification, object: sharedCoreDataService.mainManagedObjectContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MonitorSavesDataService.willSaveNotification(_:)), name: NSManagedObjectContextWillSaveNotification, object: sharedCoreDataService.mainManagedObjectContext)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Public methods
    
    func registerEntityName(entityName: String, attribute: String, handler: HandlerBlock) {
        
        var attributeHandler: [String : HandlerBlock]? = handlers[entityName]
        
        if (attributeHandler == nil) {
            attributeHandler = [String: HandlerBlock]()
        }
        
        attributeHandler![attribute] = handler
        
        handlers[entityName] = attributeHandler!
    }
    
    // MARK: - Private methods
    
    private func addMonitorQueueHandler(handler: HandlerBlock, forManagedObject managedObject: NSManagedObject) {
        var handlers = monitorQueue[managedObject as NSManagedObject]
        
        if handlers == nil {
            handlers = []
        }
        
        handlers?.append(handler)
        
        monitorQueue[managedObject] = handlers
    }
    
    private func clearMonitorQueue() {
        monitorQueue.removeAll(keepCapacity: false)
    }
    
    private func executeHandlersForUpdatedObjects(updatedObjects: NSSet) {
        for (managedObject, handlers) in monitorQueue {
            if updatedObjects.containsObject(managedObject) {
                for handler in handlers {
                    handler(managedObject)
                }
            }
        }
    }
    
    private func filterUpdatedObjects(updatedObjects: NSSet, forEntityName entityName: String) -> NSSet? {
        if let predicate = NSPredicate(format: "entity.name == %@", entityName) as NSPredicate?{
            let filteredObjects = updatedObjects.filteredSetUsingPredicate(predicate)
            
            return filteredObjects
        }
        
        return nil
    }
    
    
    // MARK: - Notifications
    
    @objc func didSaveNotification(notification: NSNotification) {
        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? NSSet {
            executeHandlersForUpdatedObjects(updatedObjects)
        }
        
        clearMonitorQueue()
    }
    
    @objc func willSaveNotification(notification: NSNotification) {
        clearMonitorQueue()
        
        if let updatedObjects = sharedCoreDataService.mainManagedObjectContext?.updatedObjects {
            for (entityName, attributeHandlerDictionary) in handlers {
                if let filteredObjects = filterUpdatedObjects(updatedObjects, forEntityName: entityName) {
                    
                    for managedObject in filteredObjects {
                        let changedValues = managedObject.changedValues()
                        
                        for (attribute, handler) in attributeHandlerDictionary {
                            if changedValues[attribute] != nil {
                                addMonitorQueueHandler(handler, forManagedObject: managedObject as! NSManagedObject)
                            }
                        }
                    }
                }
            }
        }
    }
}
