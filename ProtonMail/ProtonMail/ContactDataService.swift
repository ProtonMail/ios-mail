//
//  ContactDataService.swift
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

let sharedContactDataService = ContactDataService()

class ContactDataService {
    typealias CompletionBlock = APIService.CompletionBlock
    
    func addContact(#name: String, email: String, completion: CompletionBlock?) {
        sharedAPIService.contactAdd(name: name, email: email, completion: fetchContactsCompletionBlockForCompletion(completion))
    }
    
    func deleteContact(contact: Contact, completion: CompletionBlock?) {
        sharedAPIService.contactDelete(contactID: contact.contactID, completion: fetchContactsCompletionBlockForCompletion(completion))
    }
    
    func fetchContacts(completion: CompletionBlock?) {
        let completionWrapper: CompletionBlock = { task, response, error in
            if let contactsArray = response?["Contacts"] as? [Dictionary<String, AnyObject>] {
                let context = sharedCoreDataService.newManagedObjectContext()
                
                context.performBlock() {
                    var error: NSError? = nil
                    var contacts = GRTJSONSerialization.mergeObjectsForEntityName(Contact.Attributes.entityName, fromJSONArray: contactsArray, inManagedObjectContext: context, error: &error)
                    
                    if error == nil {
                        self.removeContacts(contacts as [Contact], notInContext: context, error: &error)
                        
                        if error == nil {
                            error = context.saveUpstreamIfNeeded()
                        }
                    }
                    
                    if error != nil {
                        NSLog("\(__FUNCTION__) error: \(error)")
                    } else {
                        NSLog("\(__FUNCTION__) updated \(contacts.count) contacts")
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        completion?(task, response, error)
                        return
                    }
                }
            } else {
                completion?(task, response, NSError.unableToParseResponse(response))
            }
        }
        
        sharedAPIService.contactList(completionWrapper)
    }
    
    func updateContact(#contactID: String, name: String, email: String, completion: CompletionBlock?) {
        sharedAPIService.contactUpdate(contactID: contactID, name: name, email: email, completion: fetchContactsCompletionBlockForCompletion(completion))
    }
    
    // MARK: - Private methods
    
    private func fetchContactsCompletionBlockForCompletion(completion: CompletionBlock?) -> CompletionBlock {
        return { task, response, error in
            if error == nil {
                self.fetchContacts(completion)
            } else {
                completion?(task, response, error)
            }
        }
    }

    private func removeContacts(contacts: [Contact], notInContext context: NSManagedObjectContext, error: NSErrorPointer) {
        if contacts.count == 0 {
            return
        }
        
        let fetchRequest = NSFetchRequest(entityName: Contact.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "NOT (SELF IN %@)", contacts)
        
        if let deletedObjects = context.executeFetchRequest(fetchRequest, error: error) {
            for deletedObject in deletedObjects as [NSManagedObject] {
                context.deleteObject(deletedObject)
            }
        }
    }
}
