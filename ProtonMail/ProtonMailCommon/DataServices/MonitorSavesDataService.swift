//
//  MonitorSavesDataService.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
        let updatedObjects = sharedCoreDataService.mainManagedObjectContext.updatedObjects
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
