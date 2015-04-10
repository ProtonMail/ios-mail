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
    typealias ContactCompletionBlock = (([Contact]?, NSError?) -> Void)
    
    func addContact(#name: String, email: String, completion: ContactCompletionBlock?) {
        sharedAPIService.contactAdd(name: name, email: email, completion: completionBlockForContactCompletionBlock(completion))
    }

    /// Only call from the main thread
    func allContacts() -> [Contact] {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            return allContactsInManagedObjectContext(context)
        }
        
        return []
    }
    
    func allContactsInManagedObjectContext(context: NSManagedObjectContext) -> [Contact] {
        let fetchRequest = NSFetchRequest(entityName: Contact.Attributes.entityName)
        
        var error: NSError?
        if let contacts = context.executeFetchRequest(fetchRequest, error: &error) as? [Contact] {
            return contacts
        }
        
        NSLog("\(__FUNCTION__) error: \(error)")
        
        return []
    }
    
    func deleteContact(contactID: String!, completion: ContactCompletionBlock?) {
        if (completion != nil) {
            sharedAPIService.contactDelete(contactID: contactID, completion: completionBlockForContactCompletionBlock(completion))
        } else {
            sharedAPIService.contactDelete(contactID: contactID, completion: nil)
        }
    }
    
    func fetchContacts(completion: ContactCompletionBlock?) {
        let completionWrapper: APIService.CompletionBlock = { task, response, error in
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
                        completion?(nil, error)
                    } else {
                        NSLog("\(__FUNCTION__) updated \(contacts.count) contacts")
                        completion?(self.allContacts(), nil)
                    }
                }
            } else {
                completion?(nil, NSError.unableToParseResponse(response))
            }
        }
        
        sharedAPIService.contactList(completionWrapper)
    }
    
    func updateContact(#contactID: String, name: String, email: String, completion: ContactCompletionBlock?) {
        if (completion != nil) {
            sharedAPIService.contactUpdate(contactID: contactID, name: name, email: email, completion: completionBlockForContactCompletionBlock(completion))
        } else {
            sharedAPIService.contactUpdate(contactID: contactID, name: name, email: email, completion: nil)
        }
    }
    
    
    // MARK: - Private methods
    
    private func completionBlockForContactCompletionBlock(completion: ContactCompletionBlock?) -> APIService.CompletionBlock {
        return { task, response, error in
            if error == nil {
                self.fetchContacts(completion)
            } else {
                completion?(nil, error)
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


// MARK: AddressBook contact extension

extension ContactDataService {
    typealias ContactVOCompletionBlock = ((contacts: [ContactVO], error: NSError?) -> Void)
    
    func allContactVOs() -> [ContactVO] {
        var contacts: [ContactVO] = []
        
        for contact in sharedContactDataService.allContacts() {
            contacts.append(ContactVO(id: contact.contactID, name: contact.name, email: contact.email, isProtonMailContact: true))
        }
        
        return contacts
    }
    
    func fetchContactVOs(completion: ContactVOCompletionBlock) {
        // fetch latest contacts from server
        fetchContacts { (_, error) -> Void in
            self.requestAccessToAddressBookIfNeeded(lastError: error, completion: completion)
            self.processContacts(addressBookAccessGranted: sharedAddressBookService.hasAccessToAddressBook(), lastError: error, completion: completion)
        }
    }
    
    private func requestAccessToAddressBookIfNeeded(var #lastError: NSError?, completion: ContactVOCompletionBlock) {
        if !sharedAddressBookService.hasAccessToAddressBook() {
            sharedAddressBookService.requestAuthorizationWithCompletion({ (granted: Bool, error: NSError?) -> Void in
                if error != nil {
                    lastError = error
                }
                
                self.processContacts(addressBookAccessGranted: granted, lastError: lastError, completion: completion)
            })
        }
    }
    
    private func processContacts(addressBookAccessGranted granted: Bool, var lastError: NSError?, completion: ContactVOCompletionBlock) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            var contacts: [ContactVO] = []
            
            if granted {
                // get contacts from address book
                contacts = sharedAddressBookService.contacts()
            }
            
            // merge address book and core data contacts
            let context = sharedCoreDataService.newManagedObjectContext()
            context.performBlockAndWait() {
                for contact in sharedContactDataService.allContactsInManagedObjectContext(context) {
                    contacts.append(ContactVO(id: contact.contactID, name: contact.name, email: contact.email, isProtonMailContact: true))
                }
            }
            
            contacts.sort { $0.name.lowercaseString < $1.name.lowercaseString }
            
            dispatch_async(dispatch_get_main_queue()) {
                completion(contacts: contacts, error: lastError)
            }
        }
    }
}
