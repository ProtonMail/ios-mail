//
//  ContactDataService.swift
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
import Groot
import PromiseKit
import AwaitKit
import Crypto
import OpenPGP
import ProtonCore_Networking
import ProtonCore_Services

typealias ContactFetchComplete = (([Contact]?, NSError?) -> Void)
typealias ContactAddComplete = (([Contact]?, NSError?) -> Void)

typealias ContactImportComplete = (([Contact]?, String) -> Void)
typealias ContactImportUpdate = ((Int) -> Void)
typealias ContactImportCancel = (() -> Bool)

typealias ContactDeleteComplete = ((NSError?) -> Void)
typealias ContactUpdateComplete = (([Contact]?, NSError?) -> Void)

class ContactDataService: Service, HasLocalStorage {
    
    private let addressBookService: AddressBookService
    private let labelDataService: LabelsDataService
    private let coreDataService: CoreDataService
    private let apiService : APIService
    private let userID : String
    private var lastUpdatedStore: LastUpdatedStoreProtocol
    private let cacheService: CacheService
    init(api: APIService, labelDataService: LabelsDataService, userID : String, coreDataService: CoreDataService, lastUpdatedStore: LastUpdatedStoreProtocol, cacheService: CacheService) {
        self.userID = userID
        self.apiService = api
        self.addressBookService = AddressBookService()
        self.labelDataService = labelDataService
        self.coreDataService = coreDataService
        self.lastUpdatedStore = lastUpdatedStore
        self.cacheService = cacheService
    }
    
    /**
     clean contact local cache
     **/
    func cleanUp() -> Promise<Void> {
        return Promise { seal in
            lastUpdatedStore.contactsCached = 0
            let context = self.coreDataService.operationContext
            self.coreDataService.enqueue(context: context) { (context) in
                let fetch1 = NSFetchRequest<NSFetchRequestResult>(entityName: Contact.Attributes.entityName)
                fetch1.predicate = NSPredicate(format: "%K == %@", Contact.Attributes.userID, self.userID)
                let request1 = NSBatchDeleteRequest(fetchRequest: fetch1)
                request1.resultType = .resultTypeObjectIDs
                if let result = try? context.execute(request1) as? NSBatchDeleteResult,
                   let objectIdArray = result.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIdArray]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                }
                
                let fetch2 = NSFetchRequest<NSFetchRequestResult>(entityName: Email.Attributes.entityName)
                fetch2.predicate = NSPredicate(format: "%K == %@", Email.Attributes.userID, self.userID)
                let request2 = NSBatchDeleteRequest(fetchRequest: fetch2)
                request2.resultType = .resultTypeObjectIDs
                if let result = try? context.execute(request2) as? NSBatchDeleteResult,
                   let objectIdArray = result.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIdArray]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                }
                
                let fetch3 = NSFetchRequest<NSFetchRequestResult>(entityName: LabelUpdate.Attributes.entityName)
                fetch3.predicate = NSPredicate(format: "%K == %@", LabelUpdate.Attributes.userID, self.userID)
                let request3 = NSBatchDeleteRequest(fetchRequest: fetch3)
                if let result = try? context.execute(request3) as? NSBatchDeleteResult,
                   let objectIdArray = result.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIdArray]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                }
                
                seal.fulfill_()
            }
        }
    }
    
    static func cleanUpAll() -> Promise<Void> {
        return Promise { seal in
            let coreDataService = sharedServices.get(by: CoreDataService.self)
            let context = coreDataService.operationContext
            coreDataService.enqueue(context: context) { (context) in
                Contact.deleteAll(inContext: context)
                Email.deleteAll(inContext: context)
                seal.fulfill_()
            }
        }
    }
    
    /**
     get/build fetch results controller for contacts
     
     **/
    func resultController(isCombineContact: Bool = false) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let moc = self.coreDataService.mainContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Contact.Attributes.entityName)
        let strComp = NSSortDescriptor(key: Contact.Attributes.name,
                                       ascending: true,
                                       selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [strComp]
        
        if !isCombineContact {
            fetchRequest.predicate = NSPredicate(format: "%K == %@", Contact.Attributes.userID, self.userID)
        }
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: moc,
                                          sectionNameKeyPath: Contact.Attributes.sectionName,
                                          cacheName: nil)
    }

    func contactFetchedController(by contactID: String) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let moc = self.coreDataService.mainContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Contact.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Contact.Attributes.contactID, contactID)
        let strComp = NSSortDescriptor(key: Contact.Attributes.name,
                                       ascending: true,
                                       selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [strComp]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: moc,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }
    
    /**
     add a new contact
     
     - Parameter cards: vcard contact data -- 4 different types
     - Parameter completion: async add contact complete response
     **/
    func add(cards: [[CardData]], authCredential: AuthCredential?, completion: ContactAddComplete?) {
        let route = ContactAddRequest(cards: cards, authCredential: authCredential)
        self.apiService.exec(route: route) { (response: ContactAddResponse) in
            var contacts_json : [[String : Any]] = []
            var lasterror : NSError?
            let results = response.results
            if !results.isEmpty {
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
                self.cacheService.addNewContact(serverReponse: contacts_json) { (contacts, error) in
                    completion?(contacts, error)
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
    func imports(cards: [[CardData]], authCredential: AuthCredential?,
                 cancel: ContactImportCancel?, update: ContactImportUpdate?, completion: ContactImportComplete?) {
        
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

                    let api = ContactAddRequest(cards: tempCards, authCredential: authCredential)
                    do {
                        let response: ContactAddResponse = try `await`(self.apiService.run(route: api))
                        update?(processed)
                        var contacts_json : [[String : Any]] = []
                        let results = response.results
                        if !results.isEmpty {
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
                            self.cacheService.addNewContact(serverReponse: contacts_json) { (contacts, error) in
                                importedContacts.append(contentsOf: contacts ?? [])
                                PMLog.D("error: \(String(describing: error))")
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
    func update(contactID: String,
                cards: [CardData], completion: ContactUpdateComplete?) {
        let api = ContactUpdateRequest(contactid: contactID, cards:cards)
        self.apiService.exec(route: api) { (task, response: ContactDetailResponse) in
            if let error = response.error {
                completion?(nil, error.toNSError)
            } else if var contactDict = response.contact {
                //api is not returning the cards data so set it use request cards data
                //check is contactDict has cards if doesnt exsit set it here
                if contactDict["Cards"] == nil {
                    contactDict["Cards"] = cards.toDictionary()
                }

                self.cacheService.updateContact(contactID: contactID, cardsJson: contactDict) { result in
                    switch result {
                    case .success(let contact):
                        completion?(contact, nil)
                    case .failure(let error):
                        completion?(nil, error)
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
    func delete(contactID: String, completion: @escaping ContactDeleteComplete) {
        let api = ContactDeleteRequest(ids: [contactID])
        self.apiService.exec(route: api) { (task, response) in
            if let error = response.error {
                if error.responseCode == 13043 { //not exsit
                    self.cacheService.deleteContact(by: contactID) { (cacheError) in
                        PMLog.D(" error: \(String(describing: cacheError))")
                    }
                }
                completion(error.toNSError)
            } else {
                self.cacheService.deleteContact(by: contactID) { (error) in
                    if let cacheError = error {
                        DispatchQueue.main.async {
                            completion(cacheError)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }
            }
        }
    }
    
    func fetch(byEmails emails: [String], context: NSManagedObjectContext? = nil) -> Promise<[PreContact]> {
        let context = context ?? self.coreDataService.mainContext
        return Promise { seal in
            guard let fetchController = Email.findEmailsController(emails, inManagedObjectContext: context) else {
                seal.fulfill([])
                return
            }
            guard let contactEmails = fetchController.fetchedObjects as? [Email] else {
                seal.fulfill([])
                return
            }
            
            let noDetails : [Email] = contactEmails.filter { $0.managedObjectContext != nil && $0.defaults == 0 && $0.contact.isDownloaded == false && $0.userID == self.userID }
            let fetchs : [Promise<Contact>] = noDetails.map { return self.details(contactID: $0.contactID) }
            firstly {
                when(resolved: fetchs)
            }.then { (result) -> Guarantee<[Result<PreContact>]> in
                var allEmails = contactEmails
                if let newFetched = fetchController.fetchedObjects as? [Email] {
                    allEmails = newFetched
                }
                
                let details : [Email] = allEmails.filter { $0.defaults == 0 && $0.contact.isDownloaded && $0.userID == self.userID }
                var parsers : [Promise<PreContact>] = details.map {
                    return self.parseContact(email: $0.email, cards: $0.contact.getCardData())
                }
                for r in result {
                    switch r {
                    case .fulfilled(let value):
                        if let fEmail = contactEmails.first(where: { (e) -> Bool in
                            e.contactID == value.contactID
                        }) {
                            PMLog.D(value.cardData)
                            parsers.append(self.parseContact(email: fEmail.email, cards: value.getCardData()))
                        }
                    case .rejected(let error):
                        PMLog.D(error.localizedDescription)
                    }
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
            }.catch(policy: .allErrors) { error in
                seal.reject(error)
            }
        }
    }
    
    func parseContact(email : String, cards: [CardData]) -> Promise<PreContact> {
        return Promise { seal in
            async {
                for c in cards {
                    switch c.type {
                    case .SignedOnly:
                        //PMLog.D(c.data)
                        if let vcard = PMNIEzvcard.parseFirst(c.data) {
                            let emails = vcard.getEmails()
                            for e in emails {
                                if email == e.getValue() {
                                    let group = e.getGroup();
                                    let encrypt = vcard.getPMEncrypt(group)
                                    let sign = vcard.getPMSign(group)
                                    let isSign = sign?.getValue() ?? "false" == "true" ? true : false
                                    let keys = vcard.getKeys(group)
                                    let isEncrypt = encrypt?.getValue() ?? "false" == "true" ? true : false
                                    let schemeType = vcard.getPMScheme(group)
                                    let isMime = schemeType?.getValue() ?? "pgp-mime" == "pgp-mime" ? true : false
                                    let mimeType = vcard.getPMMimeType(group)
                                    let pt = mimeType?.getValue()
                                    let plainText = pt ?? "text/html" == "text/html" ? false : true
                                    
                                    var firstKey : Data?
                                    var pubKeys : [Data] = []
                                    for key in keys {
                                        let kg = key.getGroup()
                                        if kg == group {
                                            let kp = key.getPref()
                                            let value = key.getBinary() //based 64 key
                                            if let isExpired = value.isPublicKeyExpired(), !isExpired {
                                                pubKeys.append(value)
                                                if kp == 1 || kp == Int32.min {
                                                    firstKey = value
                                                }
                                            }
                                        }
                                    }
                                    return seal.fulfill(PreContact(email: email,
                                                                   pubKey: firstKey, pubKeys: pubKeys,
                                                                   sign: isSign, encrypt: isEncrypt,
                                                                   mime: isMime, plainText: plainText))
                                }
                            }
                        }
                    default:
                        break
                        
                    }
                }
                //TODO::need to improve the error part
                seal.reject(NSError.badResponse())
            }
           

        }
    }
    
    /**
     get all contacts from server
     
     - Parameter completion: async complete response
     **/
    fileprivate var isFetching : Bool = false
    fileprivate var retries : Int = 0
    func fetchContacts(completion: ContactFetchComplete?) {
        if lastUpdatedStore.contactsCached == 1 || isFetching {
            completion?(nil, nil)
            return
        }
        
        if self.retries > 3 {
            lastUpdatedStore.contactsCached = 0
            self.isFetching = false;
            self.retries = 0
            completion?(nil, nil)
            return
        }
        
        self.isFetching = true
        self.retries = self.retries + 1

        async {
            do {
                // fetch contacts, without their respective emails
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
                    
                    let response: ContactsResponse = try `await`(self.apiService.run(route: ContactsRequest(page: currentPage, pageSize: pageSize)))
                    if response.error == nil {
                        let contacts = response.contacts //TODO:: fix me set userID
                        if fetched == -1 {
                            fetched = contacts.count
                            total = response.total
                            loop = (total / pageSize) - (total % pageSize == 0 ? 1 : 0)
                        } else {
                            fetched = fetched + contacts.count
                        }
                        self.cacheService.addNewContact(serverReponse: contacts, shouldFixName: true) { (_, error) in
                            if let err = error {
                                DispatchQueue.main.async {
                                    err.alertErrorToast()
                                }
                            }
                        }
                    }
                }

                // fetch contact groups  //TDOO:: this fetch could be removed.
                // TODO: if I don't manually store the labels first, the record won't be saved automatically? (cascade)
                self.labelDataService.fetchV4ContactGroup().cauterize()

                // fetch contact emails
                currentPage = 0
                fetched = -1
                loop = 1
                total = 0
                while (true) {
                    if loop <= 0 || fetched >= total {
                        break
                    }
                    loop = loop - 1
                    let contactsRes: ContactEmailsResponse = try `await`(self.apiService.run(route: ContactEmailsRequest(page: currentPage,
                                                                                                                       pageSize: pageSize)))
                    if contactsRes.error == nil {
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
                        self.cacheService.addNewContact(serverReponse: contactsArray, shouldFixName: true) { (_, error) in
                            if let err = error {
                                DispatchQueue.main.async {
                                    err.alertErrorToast()
                                }
                            }
                        }
                    }
                }
                self.lastUpdatedStore.contactsCached = 1
                self.isFetching = false
                self.retries = 0

                completion?(nil, nil)

            } catch let ex as NSError {
                self.lastUpdatedStore.contactsCached = 0
                self.isFetching = false;

                {
                    completion?(nil, ex)
                } ~> .main
            }
        }
    }
    
    /**
     get contact full details
     
     - Parameter contactID: contact id
     - Parameter completion: async complete response
     **/
    func details(contactID: String) -> Promise<Contact> {
        return Promise { seal in
            let api = ContactDetailRequest(cid: contactID)
            self.apiService.exec(route: api) { (task, response: ContactDetailResponse) in
                if let error = response.error {
                    seal.reject(error)
                } else if let contactDict = response.contact {
                    self.cacheService.updateContactDetail(serverResponse: contactDict) { (contact, error) in
                        if let err = error {
                            seal.reject(err)
                        } else if let c = contact {
                            seal.fulfill(c)
                        } else {
                            fatalError()
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
        let context = self.coreDataService.mainContext
        return self.allEmailsInManagedObjectContext(context)
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
    
    private func allEmailsInManagedObjectContext(_ context: NSManagedObjectContext, isContactCombine: Bool) -> [Email] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Email.Attributes.entityName)
        let predicate = isContactCombine ? nil : NSPredicate(format: "%K == %@", Email.Attributes.userID, self.userID)
        fetchRequest.predicate = predicate
        do {
            if let emails = try context.fetch(fetchRequest) as? [Email] {
                return emails
            }
        } catch let ex as NSError {
            PMLog.D(" error: \(ex)")
        }
        return []
    }
    
    /**
     The function that checks if the current dest contactVO (emailID) is an e2e encrypted
     
     - Parameters:
     - model: ContactPickerModelProtocol
     - progress: the closure that contains the actions required before and during the email status is being checked
     - complete: the closure that contains the actions required after the email status is checked
     */
    func lockerCheck(model: ContactPickerModelProtocol,
                     message: Message? = nil,
                     progress: () -> Void,
                     complete: ((UIImage?, Int) -> Void)?) {
        guard let c = model as? ContactVO else {
            complete?(nil, -1)
            return
        }
        
        guard let email = model.displayEmail else {
            complete?(nil, -1)
            return
        }
        
        progress()
        
        let context = self.coreDataService.mainContext // VALIDATE
        async {
            let getEmail: Promise<KeysResponse> = self.apiService.run(route: UserEmailPubKeys(email: email))
            let getContact = self.fetch(byEmails: [email], context: context)
            when(fulfilled: getEmail, getContact).done { keyRes, contacts in
                if keyRes.recipientType == 1 {
                    if let contact = contacts.first, contact.firstPgpKey != nil {
                        c.pgpType = .internal_trusted_key
                    } else {
                        c.pgpType = .internal_normal
                    }
                } else {
                    if let contact = contacts.first, contact.firstPgpKey != nil {
                        if contact.encrypt {
                            c.pgpType = .pgp_encrypt_trusted_key
                        } else if contact.sign {
                            c.pgpType = .pgp_signed
                            if let pwd = message?.password, pwd != "" {
                                c.pgpType = .eo
                            }
                        }
                    } else {
                        if let pwd = message?.password, pwd != "" {
                            c.pgpType = .eo
                        } else {
                            c.pgpType = .none
                        }
                    }
                }
                complete?(c.lock, c.pgpType.rawValue)
            }.catch(policy: .allErrors) { (error) in
                PMLog.D(error.localizedDescription)
                complete?(nil, -1)
            }
        }
    }
}

//// MARK: AddressBook contact extension
extension ContactDataService {
    typealias ContactVOCompletionBlock = ((_ contacts: [ContactVO], _ error: Error?) -> Void)
    
    func allContactVOs() -> [ContactVO] {
        allEmails()
            .filter { $0.userID == userID }
            .map { ContactVO(id: $0.contactID, name: $0.name, email: $0.email, isProtonMailContact: true) }
    }
    
    func fetchContactVOs(_ completion: @escaping ContactVOCompletionBlock) {
        // fetch latest contacts from server
        //getContacts { (_, error) -> Void in
        self.requestAccessToAddressBookIfNeeded(completion)
        self.processContacts(addressBookAccessGranted: addressBookService.hasAccessToAddressBook(), lastError: nil, completion: completion)
        //}
    }
    
    func getContactVOs(_ completion: @escaping ContactVOCompletionBlock) {
        
        self.requestAccessToAddressBookIfNeeded(completion)
        self.processContacts(addressBookAccessGranted: addressBookService.hasAccessToAddressBook(), lastError: nil, completion: completion)
        
    }
    
    fileprivate func requestAccessToAddressBookIfNeeded(_ cp: @escaping ContactVOCompletionBlock) {
        if !addressBookService.hasAccessToAddressBook() {
            addressBookService.requestAuthorizationWithCompletion({ (granted: Bool, error: Error?) -> Void in
                self.processContacts(addressBookAccessGranted: granted, lastError: error, completion: cp)
            })
        }
    }
    
    fileprivate func processContacts(addressBookAccessGranted granted: Bool, lastError: Error?, completion: @escaping ContactVOCompletionBlock) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            var contacts: [ContactVO] = []
            if granted {
                // get contacts from address book
                contacts = self.addressBookService.contacts()
            }
            
            // merge address book and core data contacts
            let context = self.coreDataService.operationContext // VALIDATE
            context.performAndWait() {
                let emailsCache = self.allEmailsInManagedObjectContext(context,
                                                                       isContactCombine: userCachedStatus.isCombineContactOn)
                var pm_contacts: [ContactVO] = []
                for email in emailsCache {
                    if email.managedObjectContext != nil {
                        pm_contacts.append(ContactVO(id: email.contactID, name: email.name, email: email.email, isProtonMailContact: true))
                    }
                }
                contacts.append(contentsOf: pm_contacts)
            }
            contacts.sort { $0.name.lowercased() == $1.name.lowercased() ? $0.email.lowercased() < $1.email.lowercased() : $0.name.lowercased() < $1.name.lowercased()}
            
            DispatchQueue.main.async {
                completion(Array(Set(contacts)), lastError)
            }
        }
    }
}
