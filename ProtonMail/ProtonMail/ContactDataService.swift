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

import Foundation
import CoreData

let sharedContactDataService = ContactDataService()

class ContactDataService {
    typealias ContactCompletionBlock = (([Contact]?, NSError?) -> Void)
    
    func addContact(name name: String, email: String, completion: ContactCompletionBlock?) {
        sharedAPIService.contactAdd(name: name, email: email, completion: completionBlockForContactCompletionBlock(completion))
    }
    
    private var managedObjectContext: NSManagedObjectContext? {
        return sharedCoreDataService.mainManagedObjectContext
    }
    
    func cleanUp()
    {
        if let context = managedObjectContext {
            Contact.deleteAll(inContext: context)
        }
    }
    
    /// Only call from the main thread
    func allContacts() -> [Contact] {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            //context.performBlockAndWait() {
            return self.allContactsInManagedObjectContext(context)
            //}
        }
        return []
    }
    
    private func allContactsInManagedObjectContext(context: NSManagedObjectContext) -> [Contact] {
        let fetchRequest = NSFetchRequest(entityName: Contact.Attributes.entityName)
        do {
            if let contacts = try context.executeFetchRequest(fetchRequest) as? [Contact] {
                return contacts
            }
        } catch let ex as NSError {
            PMLog.D(" error: \(ex)")
        }
        return []
    }
    
    func deleteContact(contactID: String!, completion: ContactCompletionBlock?) {
        sharedAPIService.contactDelete(contactID: contactID) { (task, response, error) -> Void in
            if error == nil {
                if let context = sharedCoreDataService.mainManagedObjectContext {
                    context.performBlockAndWait() {
                        if let contact = Contact.contactForContactID(contactID, inManagedObjectContext: context) {
                            context.deleteObject(contact)
                        }
                        if let error = context.saveUpstreamIfNeeded() {
                            PMLog.D(" error: \(error)")
                        }
                    }
                }
            }
            completion?(nil,nil)
        }
    }
    
    func fetchContacts(completion: ContactCompletionBlock?) {
        let completionWrapper: APIService.CompletionBlock = { task, response, error in
            if let contactsArray = response?["Contacts"] as? [Dictionary<String, AnyObject>] {
                let context = sharedCoreDataService.newManagedObjectContext()
                context.performBlockAndWait() {
                    do {
                        if let contacts = try GRTJSONSerialization.objectsWithEntityName(Contact.Attributes.entityName, fromJSONArray: contactsArray, inContext: context) as? [Contact] {
                            self.removeContacts(contacts, notInContext: context)
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                                completion?(nil, error)
                            } else {
                                completion?(self.allContacts(), nil)
                            }
                        }
                    } catch let ex as NSError {
                        PMLog.D(" error: \(ex)")
                        completion?(nil, ex)
                    }
                }
            } else {
                completion?(nil, NSError.unableToParseResponse(response))
            }
        }
        sharedAPIService.contactList(completionWrapper)
    }
    
    func updateContact(contactID contactID: String, name: String, email: String, completion: ContactCompletionBlock?) {
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
    
    private func removeContacts(contacts: [Contact], notInContext context: NSManagedObjectContext) {
        if contacts.count == 0 {
            return
        }
        let fetchRequest = NSFetchRequest(entityName: Contact.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "NOT (SELF IN %@)", contacts)
        do {
            let deletedObjects = try context.executeFetchRequest(fetchRequest)
            for deletedObject in deletedObjects as! [NSManagedObject] {
                context.deleteObject(deletedObject)
            }
        } catch let ex as NSError {
            PMLog.D(" error: \(ex)")
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
            self.requestAccessToAddressBookIfNeeded(completion)
            self.processContacts(addressBookAccessGranted: sharedAddressBookService.hasAccessToAddressBook(), lastError: error, completion: completion)
        }
    }
    
    func getContactVOs(completion: ContactVOCompletionBlock) {
        
        self.requestAccessToAddressBookIfNeeded(completion)
        self.processContacts(addressBookAccessGranted: sharedAddressBookService.hasAccessToAddressBook(), lastError: nil, completion: completion)
        
    }
    
    private func requestAccessToAddressBookIfNeeded(cp: ContactVOCompletionBlock) {
        if !sharedAddressBookService.hasAccessToAddressBook() {
            sharedAddressBookService.requestAuthorizationWithCompletion({ (granted: Bool, error: NSError?) -> Void in
                self.processContacts(addressBookAccessGranted: granted, lastError: error, completion: cp)
            })
        }
    }
    
    private func processContacts(addressBookAccessGranted granted: Bool, lastError: NSError?, completion: ContactVOCompletionBlock) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            var contacts: [ContactVO] = []
            if granted {
                // get contacts from address book
                contacts = sharedAddressBookService.contacts()
            }
            
            // merge address book and core data contacts
            let context = sharedCoreDataService.newManagedObjectContext()
            context.performBlockAndWait() {
                let contactesCache = sharedContactDataService.allContactsInManagedObjectContext(context)
                var pm_contacts: [ContactVO] = []
                for contact in contactesCache {
                    if contact.managedObjectContext != nil {
                        pm_contacts.append(ContactVO(id: contact.contactID, name: contact.name, email: contact.email, isProtonMailContact: true))
                    }
                }
                pm_contacts.distinctMerge(contacts)
                contacts = pm_contacts
            }
            contacts.sortInPlace { $0.name.lowercaseString == $1.name.lowercaseString ?  $0.email.lowercaseString < $1.email.lowercaseString : $0.name.lowercaseString < $1.name.lowercaseString}
            
            dispatch_async(dispatch_get_main_queue()) {
                completion(contacts: contacts, error: lastError)
            }
        }
    }
}
