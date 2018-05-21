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
import NSDate_Helper
import Groot
import PromiseKit
import AwaitKit

let sharedContactDataService = ContactDataService()


typealias ContactFetchComplete = (([Contact]?, NSError?) -> Void)
typealias ContactAddComplete = (([Contact]?, NSError?) -> Void)

typealias ContactImportComplete = (([Contact]?, String) -> Void)
typealias ContactImportUpdate = ((Int) -> Void)
typealias ContactImportCancel = (() -> Bool)

typealias ContactDeleteComplete = ((NSError?) -> Void)
typealias ContactUpdateComplete = (([Contact]?, NSError?) -> Void)


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
        lastUpdatedStore.contactsCached = 0
        if let context = self.managedObjectContext {
            Contact.deleteAll(inContext: context)
            Email.deleteAll(inContext: context)
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
                                           selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            fetchRequest.sortDescriptors = [strComp]
            
            return NSFetchedResultsController(fetchRequest: fetchRequest,
                                              managedObjectContext: moc,
                                              sectionNameKeyPath: Contact.Attributes.name,
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
    func add(cards: [[CardData]],
             completion: ContactAddComplete?) {
        let api = ContactAddRequest<ContactAddResponse>(cards: cards)
        api.call { (task, response, hasError) in
            var contacts_json : [[String : Any]] = []
            var lasterror : NSError?
            if let results = response?.results, !results.isEmpty {
                let isCountMatch = cards.count == results.count
                var i : Int = 0
                for res in results {
                    if let error = res as? NSError {
                        lasterror = error
                    } else if var contact = res as? [String: Any] {
                        if isCountMatch {
                            contact["Cards"] = cards[i].toDictionary()
                            contacts_json.append(contact)
                        }
                    }
                    i += 1
                }
            }
            
            if !contacts_json.isEmpty {
                let context = sharedCoreDataService.newManagedObjectContext()
                context.performAndWait() {
                    do {
                        if let contacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                           fromJSONArray: contacts_json,
                                                                           in: context) as? [Contact] {
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                                completion?(nil, error)
                            } else {
                                completion?(contacts, lasterror)
                            }
                        }
                    } catch let ex as NSError {
                        PMLog.D(" error: \(ex)")
                        completion?(nil, ex)
                    }
                }
            } else {
                completion?(nil, lasterror)
            }
        }
    }
    
    /**
     import a new conact
     
     - Parameter name: contact name
     - Parameter emails: contact email list
     - Parameter cards: vcard contact data -- 4 different types
     - Parameter completion: async add contact complete response
     **/
    func imports(cards: [[CardData]], cancel: ContactImportCancel?, update: ContactImportUpdate?, completion: ContactImportComplete?) {
        
        {
            var lasterror : [String] = []
            let count : Int = cards.count
            var processed : Int = 0
            var tempCards : [[CardData]] = []
            var importedContacts : [Contact] = []
            for card in cards {
                
                if let isCancel = cancel?(), isCancel == true {
                    completion?(importedContacts, "")
                    return
                }
                
                tempCards.append(card)
                processed += 1
                if processed == count || tempCards.count >= 3 {
                    
                    let api = ContactAddRequest<ContactAddResponse>(cards: tempCards)
                    do {
                        let response = try api.syncCall()
                        
                        update?(processed)
                        
                        var contacts_json : [[String : Any]] = []
                        if let results = response?.results, !results.isEmpty {
                            let isCountMatch = tempCards.count == results.count
                            var i : Int = 0
                            for res in results {
                                if let error = res as? NSError {
                                    lasterror.append(error.description)
                                } else if var contact = res as? [String: Any] {
                                    if isCountMatch {
                                        contact["Cards"] = tempCards[i].toDictionary()
                                    }
                                    contacts_json.append(contact)
                                }
                                i += 1
                            }
                        }
                        
                        tempCards.removeAll()
                        
                        if !contacts_json.isEmpty {
                            let context = sharedCoreDataService.newManagedObjectContext()
                            context.performAndWait() {
                                do {
                                    if let contacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                                       fromJSONArray: contacts_json,
                                                                                       in: context) as? [Contact] {
                                        
                                        if let error = context.saveUpstreamIfNeeded() {
                                            PMLog.D(" error: \(error)")
                                        } else {
                                            importedContacts.append(contentsOf: contacts)
                                        }
                                    }
                                } catch let ex as NSError {
                                    PMLog.D(" error: \(ex)")
                                }
                            }
                        }
                    } catch let ex as NSError {
                        PMLog.D(" error: \(ex)")
                    }
                }
            }
            completion?(importedContacts, lasterror.joined(separator: "\n"))
        } ~> .async
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
                            contact.needsRebuild = true
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                                completion?(nil, error)
                            } else {
                                completion?([contact], nil)
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
                if let err = response?.error, err.code == 13043 { //not exsit
                    if let context = sharedCoreDataService.mainManagedObjectContext {
                        context.performAndWait() {
                            if let contact = Contact.contactForContactID(contactID, inManagedObjectContext: context) {
                                context.delete(contact)
                            }
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                            }
                        }
                    }
                }
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
    
    
    
    func fetch(byEmails emails: [String], context: NSManagedObjectContext?) -> Promise<[PreContact]> {
        
        let context = context ?? sharedCoreDataService.newManagedObjectContext()
        
        return Promise { seal in
            async {
                
                guard let contactEmails = Email.findEmails(emails, inManagedObjectContext: context) else {
                    seal.fulfill([])
                    return
                }
                
                let noDetails : [Email] = contactEmails.filter { $0.managedObjectContext != nil && $0.defaults == 0 && $0.contact.isDownloaded == false}
                let fetchs : [Promise<Contact>] = noDetails.map { return self.details(contactID: $0.contactID) }

                firstly {
                    when(resolved: fetchs)
                }.then { (result) -> Guarantee<[Result<PreContact>]> in
                    let details : [Email] = contactEmails.filter { $0.defaults == 0 && $0.contact.isDownloaded}
                    let parsers : [Promise<PreContact>] = details.map {
                        return self.parseContact(email: $0.email, cards: $0.contact.getCardData())
                    }
                    return when(resolved: parsers)
                }.then { contacts -> Promise<[PreContact]> in
                    var sucessed : [PreContact] = [PreContact]()
                    for c in contacts {
                        switch c {
                        case .fulfilled(let value):
                            sucessed.append(value)
                        case .rejected(let error):
                            PMLog.D(error.localizedDescription)
                        }
                    }
                    return .value(sucessed)
                }.done { result in
                    seal.fulfill(result)
                }.catch { error in
                    seal.reject(error)
                }
            }
        }
    }
    
    func parseContact(email : String, cards: [CardData]) -> Promise<PreContact> {
        return Promise { seal in
            async {
                for c in cards {
                    switch c.type {
                    case .SignedOnly:
                        if let vcard = PMNIEzvcard.parseFirst(c.data) {
                            let emails = vcard.getEmails()
                            for e in emails {
                                if email == e.getValue() {
                                    let group = e.getGroup();
                                    let encrypt = vcard.getPMEncrypt()
                                    let sign = vcard.getPMSign()
                                    let isSign = sign?.getValue() ?? "false" == "true" ? true : false
                                    let keys = vcard.getKeys()
                                    let isEncrypt = encrypt?.getValue() ?? "false" == "true" ? true : false
                                    let schemeType = vcard.getPMScheme()
                                    let isMime = schemeType?.getValue() ?? "pgp-mime" == "pgp-mime" ? true : false
                                    let mimeType = vcard.getPMMimeType()
                                    let pt = mimeType?.getValue()
                                    let plainText = pt ?? "text/html" == "text/html" ? false : true
                                    
                                    for key in keys {
                                        let kg = key.getGroup()
                                        if kg == group {
                                            let kp = key.getPref()
                                            let value = key.getBinary() //based 64 key
                                            if kp == 1 || kp == Int32.min {
                                                return seal.fulfill(PreContact(email: email, pubKey: value, sign: isSign, encrypt: isEncrypt, mime: isMime, plainText: plainText))
                                            }
                                        }

                                    }
                                }
                                
                            }
                        }
                    default:
                        break
                        
                    }
                }
                //TODO::need improe the error part
                seal.reject(NSError.badResponse())
            }
           

        }
    }
    
    /**
     get all contacts from server
     
     - Parameter completion: async complete response
     **/
    fileprivate var isFetching : Bool = false
    func fetchContacts(completion: ContactFetchComplete?) {
        if lastUpdatedStore.contactsCached == 1 || isFetching {
            return
        }
        self.isFetching = true
        
        {
            do {
                var currentPage = 0
                var fetched = -1
                let pageSize = 1000
                var loop = 1
                var total = 0
                while (true) {
                    if loop <= 0 || fetched >= total {
                        break
                    }
                    loop = loop - 1
                    
                    let contactsApi = ContactsRequest(page: currentPage, pageSize: pageSize)
                    if let response = try contactsApi.syncCall() {
                        let contacts = response.contacts
                        if fetched == -1 {
                            fetched = contacts.count
                            total = response.total
                            loop = (total / pageSize) - (total % pageSize == 0 ? 1 : 0)
                        } else {
                            fetched = fetched + contacts.count
                        }
                        let context = sharedCoreDataService.newManagedObjectContext()
                        context.performAndWait() {
                            do {
                                let _ = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                         fromJSONArray: contacts,
                                                                         in: context) as? [Contact]
                                if let error = context.saveUpstreamIfNeeded() {
                                    PMLog.D(" error: \(error)")
                                }
                            } catch let ex as NSError {
                                PMLog.D(" error: \(ex)")
                            }
                        }
                    }
                }
                
                currentPage = 0
                fetched = -1
                loop = 1
                total = 0
                while (true) {
                    if loop <= 0 || fetched >= total {
                        break
                    }
                    loop = loop - 1
                    let api = ContactEmailsRequest(page: currentPage, pageSize: pageSize)
                    if let contactsRes = try api.syncCall() {
                        currentPage = currentPage + 1
                        let contactsArray = contactsRes.contacts
                        if fetched == -1 {
                            fetched = contactsArray.count
                            total = contactsRes.total
                            loop = (total / pageSize) - (total % pageSize == 0 ? 1 : 0)
                            if loop == 0 && fetched < total {
                                loop = loop + 1
                            }
                        } else {
                            fetched = fetched + contactsArray.count
                        }
                        let context = sharedCoreDataService.newManagedObjectContext()
                        context.performAndWait() {
                            do {
                                if let contacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                                   fromJSONArray: contactsArray,
                                                                                   in: context) as? [Contact] {
                                    for contact in contacts {
                                        let _ = contact.fixName(force: true)
                                    }
                                    if let error = context.saveUpstreamIfNeeded() {
                                        PMLog.D(" error: \(error)")
                                        //completion?(nil, error)
                                    } else {
                                        //completion?(contacts, nil)
                                        //completion?(self.allContacts(), nil)
                                    }
                                }
                            } catch let ex as NSError {
                                PMLog.D(" error: \(ex)")
                                //completion?(nil, ex)
                            }
                        }
                    }
                }
                
                lastUpdatedStore.contactsCached = 1
                self.isFetching = false
            } catch let ex as NSError {
                completion?(nil, ex)
            }
        } ~> .async
    }
    
    /**
     get contact full details
     
     - Parameter contactID: contact id
     - Parameter completion: async complete response
     **/
    func details(contactID: String) -> Promise<Contact> {
        return Promise { seal in
            let api = ContactDetailRequest<ContactDetailResponse>(cid: contactID)
            api.call { (task, response, hasError) in
                if let contactDict = response?.contact {
                    let context = sharedCoreDataService.newManagedObjectContext()
                    context.performAndWait() {
                        do {
                            if let contact = try GRTJSONSerialization.object(withEntityName: Contact.Attributes.entityName, fromJSONDictionary: contactDict, in: context) as? Contact {
                                contact.isDownloaded = true
                                let _ = contact.fixName(force: true)
                                if let error = context.saveUpstreamIfNeeded() {
                                    seal.reject(error)
                                } else {
                                    seal.fulfill(contact)
                                }
                            }
                        } catch let ex as NSError {
                            seal.reject(ex)
                        }
                    }
                } else {
                    seal.reject(NSError.unableToParseResponse(response))
                }
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
