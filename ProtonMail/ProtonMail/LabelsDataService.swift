//
//  LabelsDataService.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/13/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


let sharedLabelsDataService = LabelsDataService()

class LabelsDataService {
//    typealias ContactCompletionBlock = (([Contact]?, NSError?) -> Void)
//    
//    func addContact(#name: String, email: String, completion: ContactCompletionBlock?) {
//        sharedAPIService.contactAdd(name: name, email: email, completion: completionBlockForContactCompletionBlock(completion))
//    }
//    
    private var managedObjectContext: NSManagedObjectContext? {
        return sharedCoreDataService.mainManagedObjectContext
    }
    
    //
    func cleanUp()
    {
        if let context = managedObjectContext {
            Label.deleteAll(inContext: context)
        }
    }
    
    func fetchLabels() {
        let eventAPI = GetLabelsRequest<GetLabelsResponse>()
        eventAPI.call() { task, response, hasError in
            if response == nil {
                //error
                //completion?(task: task, response:nil, error: nil)
            } else if let labels = response?.labels {
                //save
                let context = sharedCoreDataService.newMainManagedObjectContext()
                context.performBlockAndWait() {
                    var error: NSError?
                    var labes = GRTJSONSerialization.mergeObjectsForEntityName(Label.Attributes.entityName, fromJSONArray: labels, inManagedObjectContext: context, error: &error)
                    if error == nil {
                        error = context.saveUpstreamIfNeeded()
                    } else {
                        NSLog("\(__FUNCTION__) error: \(error)")
                    }
                }
            } else {
                //error
            }
        }
    }
    
    func fetchedResultsController() -> NSFetchedResultsController? {
        if let moc = managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Label.Attributes.entityName)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Label.Attributes.order, ascending: true)]
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        }
        
        return nil
    }
    
    func addNewLabel(response : Dictionary<String, AnyObject>?) {
        if let label = response {
            let context = sharedCoreDataService.newMainManagedObjectContext()
            context.performBlockAndWait() {
                var error: NSError?
                var labes = GRTJSONSerialization.mergeObjectsForEntityName(Label.Attributes.entityName, fromJSONArray: [label], inManagedObjectContext: context, error: &error)
                if error == nil {
                    error = context.saveUpstreamIfNeeded()
                } else {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
            }

        }
    }
    
//    /// Only call from the main thread
//    func allContacts() -> [Contact] {
//        if let context = sharedCoreDataService.mainManagedObjectContext {
//            return allContactsInManagedObjectContext(context)
//        }
//        return []
//    }
//    
//    func allContactsInManagedObjectContext(context: NSManagedObjectContext) -> [Contact] {
//        let fetchRequest = NSFetchRequest(entityName: Contact.Attributes.entityName)
//        var error: NSError?
//        if let contacts = context.executeFetchRequest(fetchRequest, error: &error) as? [Contact] {
//            return contacts
//        }
//        
//        NSLog("\(__FUNCTION__) error: \(error)")
//        
//        return []
//    }
//    
//    func deleteContact(contactID: String!, completion: ContactCompletionBlock?) {
//        if (completion != nil) {
//            sharedAPIService.contactDelete(contactID: contactID, completion: completionBlockForContactCompletionBlock(completion))
//        } else {
//            sharedAPIService.contactDelete(contactID: contactID, completion: nil)
//        }
//    }
//    

//    
//    func updateContact(#contactID: String, name: String, email: String, completion: ContactCompletionBlock?) {
//        if (completion != nil) {
//            sharedAPIService.contactUpdate(contactID: contactID, name: name, email: email, completion: completionBlockForContactCompletionBlock(completion))
//        } else {
//            sharedAPIService.contactUpdate(contactID: contactID, name: name, email: email, completion: nil)
//        }
//    }
//    
//    
//    // MARK: - Private methods
//    
//    private func completionBlockForContactCompletionBlock(completion: ContactCompletionBlock?) -> APIService.CompletionBlock {
//        return { task, response, error in
//            if error == nil {
//                self.fetchContacts(completion)
//            } else {
//                completion?(nil, error)
//            }
//        }
//    }
//    
//    private func removeContacts(contacts: [Contact], notInContext context: NSManagedObjectContext, error: NSErrorPointer) {
//        if contacts.count == 0 {
//            return
//        }
//        
//        let fetchRequest = NSFetchRequest(entityName: Contact.Attributes.entityName)
//        fetchRequest.predicate = NSPredicate(format: "NOT (SELF IN %@)", contacts)
//        
//        if let deletedObjects = context.executeFetchRequest(fetchRequest, error: error) {
//            for deletedObject in deletedObjects as! [NSManagedObject] {
//                context.deleteObject(deletedObject)
//            }
//        }
//    }
}
