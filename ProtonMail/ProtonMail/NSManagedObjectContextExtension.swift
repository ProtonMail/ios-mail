//
//  NSManagedObjectContextExtension.swift
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

extension NSManagedObjectContext {
    
    func deleteAll(entityName: String) {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.includesPropertyValues = false
        
        performBlock { () -> Void in
            var error: NSError?
            if let objects = self.executeFetchRequest(fetchRequest, error: &error) {
                for object in objects as [NSManagedObject] {
                    self.deleteObject(object)
                }
                
                NSLog("\(__FUNCTION__) Deleted \(objects.count) objects.")
                
                if let error = self.saveUpstreamIfNeeded() {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
            }
        }
    }
    
    func managedObjectWithEntityName(entityName: String, forKey key: String, matchingValue value: CVarArgType) -> NSManagedObject? {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", key, value)
        
        var error: NSError?
        if let results = executeFetchRequest(fetchRequest, error: &error) {
            return results.first as? NSManagedObject
        }
        
        if error != nil  {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
        
        return nil
    }

    func managedObjectsWithEntityName(entityName: String, forManagedObjectIDs objectIDs: [NSManagedObjectID], error: NSErrorPointer) -> [NSManagedObject]? {
        let request = NSFetchRequest(entityName: entityName)
        request.predicate = NSPredicate(format: "SELF in %@", objectIDs)

        return executeFetchRequest(request, error: error) as? [NSManagedObject]
    }
    
    func saveUpstreamIfNeeded() -> NSError? {
        var error: NSError?
        
        if hasChanges && save(&error) {
            if let parentContext = parentContext {
                parentContext.performBlockAndWait() { () -> Void in
                    error = parentContext.saveUpstreamIfNeeded()
                }
            }
        }
        
        return error
    }
    
}