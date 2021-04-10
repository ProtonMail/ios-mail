//
//  NSManagedObjectContextExtension.swift
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

extension NSManagedObjectContext {
    
    func deleteAll(_ entityName: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try self.persistentStoreCoordinator?.execute(deleteRequest, with: self)
            PMLog.D("Deleted \(entityName) objects.")
        } catch let error as NSError {
            PMLog.D("error: \(error)")
        }
    }
    
    func managedObjectWithEntityName(_ entityName: String, matching values : [String : CVarArg]) -> NSManagedObject? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        var subPredication : [NSPredicate] = []
        for (key, value) in values {
            let predicate = NSPredicate(format: "%K == %@", key, value)
            subPredication.append(predicate)
        }
        let predicateCompound = NSCompoundPredicate.init(type: .and, subpredicates: subPredication)
        fetchRequest.predicate = predicateCompound
        
        do {
            let results = try fetch(fetchRequest)
            return results.first as? NSManagedObject
        } catch let ex as NSError {
            PMLog.D("error: \(ex)")
        }
        return nil
    }
    
    func managedObjectsWithEntityName(_ entityName: String, matching values : [String : CVarArg]) -> [NSManagedObject]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
       
        var subPredication : [NSPredicate] = []
        for (key, value) in values {
            let predicate = NSPredicate(format: "%K == %@", key, value)
            subPredication.append(predicate)
        }
        let predicateCompound = NSCompoundPredicate.init(type: .and, subpredicates: subPredication)
        fetchRequest.predicate = predicateCompound
        
        do {
            let results = try fetch(fetchRequest)
            return results as? [NSManagedObject]
        } catch let ex as NSError {
            PMLog.D("error: \(ex)")
        }
        return nil
    }
    
    
    func managedObjectWithEntityName(_ entityName: String, forKey key: String, matchingValue value: CVarArg) -> NSManagedObject? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", key, value)
        
        do {
            let results = try fetch(fetchRequest)
            return results.first as? NSManagedObject
        } catch let ex as NSError {
            PMLog.D("error: \(ex)")
        }
        return nil
    }
    
    func managedObjectsWithEntityName(_ entityName: String, forKey key: String, matchingValue value: CVarArg) -> [NSManagedObject]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", key, value)
        
        do {
            let results = try fetch(fetchRequest)
            return results as? [NSManagedObject]
        } catch let ex as NSError {
            PMLog.D("error: \(ex)")
        }
        return nil
    }
    
    func managedObjectsWithEntityName(_ entityName: String, forManagedObjectIDs objectIDs: [NSManagedObjectID], error: NSErrorPointer) -> [NSManagedObject]? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = NSPredicate(format: "SELF in %@", objectIDs)
        do {
            let results = try fetch(request)
            return results as? [NSManagedObject]
        } catch let ex as NSError {
            PMLog.D("error: \(ex)")
        }
        return nil
    }
    
    func objectsWithEntityName(_ entityName: String, forKey key: String, forManagedObjectIDs objectIDs: [String]) -> [NSManagedObject]? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K in %@", key, objectIDs)
        do {
            let results = try fetch(request)
            return results as? [NSManagedObject]
        } catch let ex as NSError {
            PMLog.D("error: \(ex)")
        }
        return nil
    }
    
    func fetchedControllerEntityName(entityName: String, forKey key: String, forManagedObjectIDs objectIDs: [String]) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K in %@", key, objectIDs)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: key, ascending: false)]
        fetchRequest.includesPropertyValues = false
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func saveUpstreamIfNeeded() -> NSError? {
        var error: NSError?
        do {
            if hasChanges {
                //TODO: - v4 remove it later
                if self == CoreDataService.shared.mainContext {
                    fatalError("Do not save on main context")
                }
                try save()
                if let parentContext = parent {
                    parentContext.performAndWait() { () -> Void in
                        error = parentContext.saveUpstreamIfNeeded()
                    }
                }
            }
        } catch let ex as NSError {
            error = ex
        }
        return error
    }
    
    func find(with objectID: NSManagedObjectID) -> NSManagedObject? {
        var msgObject : NSManagedObject?
        do {
            msgObject = try self.existingObject(with: objectID)
        } catch {
            msgObject = nil
        }
//        if let obj = msgObject as? T {
//            return obj
//        }
        return msgObject
    }
}
