//
//  MonitorSavesDataService.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import CoreData

//TODO::fixme
let sharedMonitorSavesDataService = MonitorSavesDataService()

class MonitorSavesDataService {
    
    typealias HandlerBlock = ((NSManagedObject) -> Void)
    
    fileprivate var handlers: [String : [String : HandlerBlock]] = [:]
    fileprivate var monitorQueue: [NSManagedObject : [HandlerBlock]] = [:]
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MonitorSavesDataService.didSaveNotification(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MonitorSavesDataService.willSaveNotificationMain(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextWillSave,
                                               object: nil)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(MonitorSavesDataService.willSaveNotificationBackground(_:)),
//                                               name: NSNotification.Name.NSManagedObjectContextWillSave,
//                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - methods
    
    func registerEntityName(_ entityName: String, attribute: String, handler: @escaping HandlerBlock) {
        
        var attributeHandler: [String : HandlerBlock]? = handlers[entityName]
        
        if (attributeHandler == nil) {
            attributeHandler = [String: HandlerBlock]()
        }
        
        attributeHandler![attribute] = handler
        
        handlers[entityName] = attributeHandler!
    }
    
    // MARK: - Private methods
    
    fileprivate func addMonitorQueueHandler(_ handler: @escaping HandlerBlock, forManagedObject managedObject: NSManagedObject) {
        var handlers = monitorQueue[managedObject as NSManagedObject]
        
        if handlers == nil {
            handlers = []
        }
        
        handlers?.append(handler)
        
        monitorQueue[managedObject] = handlers
    }
    
    fileprivate func clearMonitorQueue() {
        monitorQueue.removeAll(keepingCapacity: false)
    }
    
    fileprivate func executeHandlersForUpdatedObjects(_ updatedObjects: NSSet) {
        for (managedObject, handlers) in monitorQueue {
            if updatedObjects.contains(managedObject) {
                for handler in handlers {
                    handler(managedObject)
                }
            }
        }
    }
    
    fileprivate func filterUpdatedObjects(_ updatedObjects: NSSet, forEntityName entityName: String) -> NSSet? {
        if let predicate = NSPredicate(format: "entity.name == %@", entityName) as NSPredicate?{
            let filteredObjects = updatedObjects.filtered(using: predicate)
            
            return filteredObjects as NSSet?
        }
        
        return nil
    }
    
    
    // MARK: - Notifications
    
    @objc func didSaveNotification(_ notification: Notification) {
        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? NSSet {
            executeHandlersForUpdatedObjects(updatedObjects)
        }
        
        clearMonitorQueue()
    }
    
    @objc func willSaveNotificationMain(_ notification: Notification) {
        let updatedObjects = CoreDataService.shared.mainManagedObjectContext.updatedObjects
        self.willSaveNotification(notification, updatedObjects: updatedObjects)
    }
    
//    @objc func willSaveNotificationBackground(_ notification: Notification) {
//        let updatedObjects = sharedCoreDataService.backgroundManagedObjectContext.updatedObjects
//        self.willSaveNotification(notification, updatedObjects: updatedObjects)
//    }
    
    func willSaveNotification(_ notification: Notification, updatedObjects: Set<NSManagedObject>) {
        clearMonitorQueue()
        
        for (entityName, attributeHandlerDictionary) in handlers {
            if let filteredObjects = filterUpdatedObjects(updatedObjects as NSSet, forEntityName: entityName) {
                
                for managedObject in filteredObjects {
                    let changedValues = (managedObject as AnyObject).changedValues()
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
