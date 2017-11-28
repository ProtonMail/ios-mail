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


typealias ContactFetchComplete = (([Contact]?, NSError?) -> Void)
typealias ContactAddComplete = ((Contact?, NSError?) -> Void)
typealias ContactDeleteComplete = ((NSError?) -> Void)
typealias ContactUpdateComplete = (([Contact]?, NSError?) -> Void)
typealias ContactDetailsComplete = ((Contact?, NSError?) -> Void)


class ContactDataService {
    
    /**
     wraper of main context
     **/
    private var managedObjectContext: NSManagedObjectContext? {
        return sharedCoreDataService.mainManagedObjectContext
    }
    
    /**
     clean contact local cache
     **/
    func clean() {
        if let context = self.managedObjectContext {
            Contact.deleteAll(inContext: context)
        }
    }
    
    /**
     get/build fetch results controller for contacts
     
     **/
    func resultController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        if let moc = self.managedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Contact.Attributes.entityName)
            let strComp = NSSortDescriptor(key: Contact.Attributes.name,
                                           ascending: true,
                                           selector: #selector(NSString.caseInsensitiveCompare(_:)))
            fetchRequest.sortDescriptors = [strComp]
            
            return NSFetchedResultsController(fetchRequest: fetchRequest,
                                              managedObjectContext: moc,
                                              sectionNameKeyPath: nil,
                                              cacheName: nil)
        }
        return nil
    }
    
    /**
     add a new conact
     
     - Parameter name: contact name
     - Parameter emails: contact email list
     - Parameter cards: vcard contact data -- 4 different types
     - Parameter completion: async add contact complete response
     **/
    func add(cards: [CardData],
             completion: ContactAddComplete?) {
        let api = ContactAddRequest<ContactAddResponse>(cards: cards)
        api.call { (task, response, hasError) in
            if let error = response?.resError {
                completion?(nil, error)
            } else if var contactDict = response?.contact {
                //api is not returning the cards data so set it use request cards data
                //check is contactDict has cards if doesnt exsit set it here
                if contactDict["Cards"] == nil {
                    contactDict["Cards"] = cards.toDictionary()
                }
                let context = sharedCoreDataService.newManagedObjectContext()
                context.performAndWait() {
                    do {
                        if let contact = try GRTJSONSerialization.object(withEntityName: Contact.Attributes.entityName,
                                                                         fromJSONDictionary: contactDict,
                                                                         in: context) as? Contact {
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                                completion?(nil, error)
                            } else {
                               completion?(contact, nil)
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
    }
    
    /**
     update a exsiting conact
     
     - Parameter contactID: delete contact id
     - Parameter name: contact name
     - Parameter emails: contact email list
     - Parameter cards: vcard contact data -- 4 different types
     - Parameter completion: async add contact complete response
     **/
    func update(contactID : String,
                cards: [CardData],
                completion: ContactAddComplete?) {
        let api = ContactUpdateRequest<ContactDetailResponse>(contactid: contactID, cards:cards)
        api.call { (task, response, hasError) in
            if hasError {
                completion?(nil, response?.error)
            } else if var contactDict = response?.contact {
                //api is not returning the cards data so set it use request cards data
                //check is contactDict has cards if doesnt exsit set it here
                if contactDict["Cards"] == nil {
                    contactDict["Cards"] = cards.toDictionary()
                }
                let context = sharedCoreDataService.newManagedObjectContext()
                context.performAndWait() {
                    do {
                        if let contact = try GRTJSONSerialization.object(withEntityName: Contact.Attributes.entityName,
                                                                         fromJSONDictionary: contactDict,
                                                                         in: context) as? Contact {
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                                completion?(nil, error)
                            } else {
                                completion?(contact, nil)
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
    }
    
    /**
     delete a contact
     
     - Parameter contactID: delete contact id
     - Parameter completion: async delete prcess complete response
     **/
    func delete(contactID: String,
                completion: @escaping ContactDeleteComplete) {
        let api = ContactDeleteRequest<ApiResponse>(ids: [contactID])
        api.call { (task, response, hasError) in
            if hasError {
                completion(response?.error)
            } else {
                if let context = sharedCoreDataService.mainManagedObjectContext {
                    context.performAndWait() {
                        if let contact = Contact.contactForContactID(contactID, inManagedObjectContext: context) {
                            context.delete(contact)
                        }
                        if let error = context.saveUpstreamIfNeeded() {
                            PMLog.D(" error: \(error)")
                            completion(error)
                        } else {
                            completion(nil)
                        }
                    }
                } else {
                    completion(NSError.unableToParseResponse(response))
                }
            }
        }
    }

    
    /**
     get all contacts from server
     
     - Parameter completion: async complete response
     **/
    func fetchContacts(completion: ContactFetchComplete?) {
        //TODO::here need change to fetch by page until got total
        let api = ContactEmailsRequest<ContactEmailsResponse>(page: 0, pageSize: 800)
        api.call { (task, response, hasError) in
            if let contactsArray = response?.contacts {
                let context = sharedCoreDataService.newManagedObjectContext()
                context.performAndWait() {
                    do {
                        if let contacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                           fromJSONArray: contactsArray, 
                                                                           in: context) as? [Contact] {
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                                completion?(nil, error)
                            } else {
                                completion?(contacts, nil)
                                //completion?(self.allContacts(), nil)
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
    }
    
    /**
     get contact full details
     
     - Parameter contactID: contact id
     - Parameter completion: async complete response
     **/
    func details(contactID: String, completion: ContactDetailsComplete?) {
        let api = ContactDetailRequest<ContactDetailResponse>(cid: contactID)
        api.call { (task, response, hasError) in
            if let contactDict = response?.contact {
                let context = sharedCoreDataService.newManagedObjectContext()
                context.performAndWait() {
                    do {
                        if let contact = try GRTJSONSerialization.object(withEntityName: Contact.Attributes.entityName, fromJSONDictionary: contactDict, in: context) as? Contact {
                            contact.isDownloaded = true
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                                completion?(nil, error)
                            } else {
                                completion?(contact, nil)
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
    }
    
    
    /// Only call from the main thread
    func allEmails() -> [Email] {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            return self.allEmailsInManagedObjectContext(context)
        }
        return []
    }
    
    private func allEmailsInManagedObjectContext(_ context: NSManagedObjectContext) -> [Email] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Email.Attributes.entityName)
        do {
            if let emails = try context.fetch(fetchRequest) as? [Email] {
                return emails
            }
        } catch let ex as NSError {
            PMLog.D(" error: \(ex)")
        }
        return []
    }
}

//// MARK: AddressBook contact extension
extension ContactDataService {
    typealias ContactVOCompletionBlock = ((_ contacts: [ContactVO], _ error: Error?) -> Void)
    
    func allContactVOs() -> [ContactVO] {
        var contacts: [ContactVO] = []
        
        for email in sharedContactDataService.allEmails() {
            contacts.append(ContactVO(id: email.contactID, name: email.name, email: email.email, isProtonMailContact: true))
        }
        
        return contacts
    }
    
    func fetchContactVOs(_ completion: @escaping ContactVOCompletionBlock) {
        // fetch latest contacts from server
        //getContacts { (_, error) -> Void in
            self.requestAccessToAddressBookIfNeeded(completion)
            self.processContacts(addressBookAccessGranted: sharedAddressBookService.hasAccessToAddressBook(), lastError: nil, completion: completion)
        //}
    }
    
    func getContactVOs(_ completion: @escaping ContactVOCompletionBlock) {
        
        self.requestAccessToAddressBookIfNeeded(completion)
        self.processContacts(addressBookAccessGranted: sharedAddressBookService.hasAccessToAddressBook(), lastError: nil, completion: completion)
        
    }
    
    fileprivate func requestAccessToAddressBookIfNeeded(_ cp: @escaping ContactVOCompletionBlock) {
        if !sharedAddressBookService.hasAccessToAddressBook() {
            sharedAddressBookService.requestAuthorizationWithCompletion({ (granted: Bool, error: Error?) -> Void in
                self.processContacts(addressBookAccessGranted: granted, lastError: error, completion: cp)
            })
        }
    }
    
    fileprivate func processContacts(addressBookAccessGranted granted: Bool, lastError: Error?, completion: @escaping ContactVOCompletionBlock) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            var contacts: [ContactVO] = []
            if granted {
                // get contacts from address book
                contacts = sharedAddressBookService.contacts()
            }
            
            // merge address book and core data contacts
            let context = sharedCoreDataService.newManagedObjectContext()
            context.performAndWait() {
                let emailsCache = sharedContactDataService.allEmailsInManagedObjectContext(context)
                var pm_contacts: [ContactVO] = []
                for email in emailsCache {
                    if email.managedObjectContext != nil {
                        pm_contacts.append(ContactVO(id: email.contactID, name: email.name, email: email.email, isProtonMailContact: true))
                    }
                }
                pm_contacts.distinctMerge(contacts)
                contacts = pm_contacts
            }
            contacts.sort { $0.name.lowercased() == $1.name.lowercased() ?  $0.email.lowercased() < $1.email.lowercased() : $0.name.lowercased() < $1.name.lowercased()}
            
            DispatchQueue.main.async {
                completion(contacts, lastError)
            }
        }
    }
}
