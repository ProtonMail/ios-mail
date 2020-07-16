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
import NSDate_Helper
import Groot
import PromiseKit
import AwaitKit
import Crypto

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
    private let apiService : API
    private let userID : String
    init(api: API, labelDataService: LabelsDataService, userID : String) {
        self.userID = userID
        self.apiService = api
        self.addressBookService = AddressBookService()
        self.labelDataService = labelDataService
    }
    
    /**
     clean contact local cache
     **/
    func cleanUp() {
        lastUpdatedStore.contactsCached = 0
        
        let context = CoreDataService.shared.backgroundManagedObjectContext
        
        let fetch1 = NSFetchRequest<NSFetchRequestResult>(entityName: Contact.Attributes.entityName)
        fetch1.predicate = NSPredicate(format: "%K == %@", Contact.Attributes.userID, self.userID)
        let request1 = NSBatchDeleteRequest(fetchRequest: fetch1)
        _ = try? context.execute(request1)
        
        let fetch2 = NSFetchRequest<NSFetchRequestResult>(entityName: Email.Attributes.entityName)
        fetch2.predicate = NSPredicate(format: "%K == %@", Email.Attributes.userID, self.userID)
        let request2 = NSBatchDeleteRequest(fetchRequest: fetch2)
        _ = try? context.execute(request2)
        
        _ = context.saveUpstreamIfNeeded()
    }
    
    static func cleanUpAll() {
        let context = CoreDataService.shared.backgroundManagedObjectContext
        context.performAndWait {
            Contact.deleteAll(inContext: context)
            Email.deleteAll(inContext: context)
        }
    }
    
    /**
     get/build fetch results controller for contacts
     
     **/
    func resultController(isCombineContact: Bool = false) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let moc = CoreDataService.shared.mainManagedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Contact.Attributes.entityName)
        let strComp = NSSortDescriptor(key: Contact.Attributes.name,
                                       ascending: true,
                                       selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [strComp]
        
        if !isCombineContact {
            fetchRequest.predicate = NSPredicate(format: "%K == %@", Contact.Attributes.userID, self.userID)
        }
        
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: moc,
                                          sectionNameKeyPath: Contact.Attributes.name,
                                          cacheName: nil)
    }
    
    /**
     add a new contact
     
     - Parameter cards: vcard contact data -- 4 different types
     - Parameter completion: async add contact complete response
     **/
    func add(cards: [[CardData]],
             authCredential: AuthCredential?,
             completion: ContactAddComplete?) {
        let api = ContactAddRequest<ContactAddResponse>(cards: cards, authCredential: authCredential)
        api.call(api: self.apiService) { (task, response, hasError) in
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
                let context = CoreDataService.shared.mainManagedObjectContext
                context.performAndWait() {
                    do {
                        if let contacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                           fromJSONArray: contacts_json,
                                                                           in: context) as? [Contact] {
                            contacts.forEach { (c) in
                                c.userID = self.userID
                                if let emails = c.emails.allObjects as? [Email] {
                                    emails.forEach { (e) in
                                        e.userID = self.userID
                                    }
                                }
                            }
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
    func imports(cards: [[CardData]], authCredential: AuthCredential?, cancel: ContactImportCancel?, update: ContactImportUpdate?, completion: ContactImportComplete?) {
        
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
                    
                    let api = ContactAddRequest<ContactAddResponse>(cards: tempCards, authCredential: authCredential)
                    do {
                        let response = try api.syncCall(api: self.apiService)
                        
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
                            let context = CoreDataService.shared.mainManagedObjectContext
                            context.performAndWait() {
                                do {
                                    if let contacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                                       fromJSONArray: contacts_json,
                                                                                       in: context) as? [Contact] {
                                        contacts.forEach { (c) in
                                            c.userID = self.userID
                                            if let emails = c.emails.allObjects as? [Email] {
                                                emails.forEach { (e) in
                                                    e.userID = self.userID
                                                }
                                            }
                                        }
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
                completion: ContactUpdateComplete?) {
        let api = ContactUpdateRequest<ContactDetailResponse>(contactid: contactID, cards:cards)
        api.call(api: self.apiService) { (task, response, hasError) in
            if hasError {
                completion?(nil, response?.error)
            } else if var contactDict = response?.contact {
                //api is not returning the cards data so set it use request cards data
                //check is contactDict has cards if doesnt exsit set it here
                if contactDict["Cards"] == nil {
                    contactDict["Cards"] = cards.toDictionary()
                }
                let context = CoreDataService.shared.mainManagedObjectContext
                context.performAndWait() {
                    do {
                        // remove all emailID associated with the current contact in the core data
                        // since the new data will be added to the core data (parse from response)
                        if let origContact = Contact.contactForContactID(contactID,
                                                                         inManagedObjectContext: context) {
                            if let emailObjects = origContact.emails.allObjects as? [Email] {
                                for emailObject in emailObjects {
                                    context.delete(emailObject)
                                }
                            } else {
                                // TODO: handle error
                                PMLog.D("Conversion error")
                            }
                        } else {
                            // TODO: handle error
                            PMLog.D("Can't get Contact by ID error")
                        }
                        
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
        api.call(api: self.apiService) { (task, response, hasError) in
            if hasError {
                if let err = response?.error, err.code == 13043 { //not exsit
                    let context = CoreDataService.shared.backgroundManagedObjectContext
                    context.performAndWait() {
                        if let contact = Contact.contactForContactID(contactID, inManagedObjectContext: context) {
                            context.delete(contact)
                        }
                        if let error = context.saveUpstreamIfNeeded() {
                            PMLog.D(" error: \(error)")
                        }
                    }
                }
                completion(response?.error)
            } else {
                let context = CoreDataService.shared.backgroundManagedObjectContext
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
            }
        }
    }
    
    func fetch(byEmails emails: [String], context: NSManagedObjectContext?) -> Promise<[PreContact]> {
        let context = context ?? CoreDataService.shared.backgroundManagedObjectContext
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
            let fetchs : [Promise<Contact>] = noDetails.map { return self.details(contactID: $0.contactID, inContext: context) }
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
            }.catch { error in
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
                                    var pubKeys : Data?
                                    for key in keys {
                                        let kg = key.getGroup()
                                        if kg == group {
                                            let kp = key.getPref()
                                            let value = key.getBinary() //based 64 key
                                            if pubKeys == nil {
                                                pubKeys = Data()
                                            }
                                            if let isExpired = value.isPublicKeyExpired(), !isExpired {
                                                pubKeys?.append(value)
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
            return
        }
        
        if self.retries > 3 {
            lastUpdatedStore.contactsCached = 0
            self.isFetching = false;
            self.retries = 0
            {
                "Retried too many times when fetching contacts.".alertToast()
                 completion?(nil, nil)
            } ~> .main
            return
        }
        
        self.isFetching = true
        self.retries = self.retries + 1
        {
            let context = CoreDataService.shared.childBackgroundManagedObjectContext(forUseIn: Thread.current)
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
                    
                    let contactsApi = ContactsRequest(page: currentPage, pageSize: pageSize)
                    if let response = try contactsApi.syncCall(api: self.apiService) {
                        let contacts = response.contacts //TODO:: fix me set userID
                        if fetched == -1 {
                            fetched = contacts.count
                            total = response.total
                            loop = (total / pageSize) - (total % pageSize == 0 ? 1 : 0)
                        } else {
                            fetched = fetched + contacts.count
                        }
                        context.performAndWait() {
                            do {
                                if let contacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                                   fromJSONArray: contacts,
                                                                                   in: context) as? [Contact] {
                                    for c in contacts {
                                        c.userID = self.userID
                                        if let emails = c.emails.allObjects as? [Email] {
                                            emails.forEach { (e) in
                                                e.userID = self.userID
                                            }
                                        }
                                    }
                                    if let error = context.saveUpstreamIfNeeded() {
                                        PMLog.D(" error: \(error)");
                                        
                                        {
                                            error.alertErrorToast()
                                        } ~> .main
                                    }
                                }
                            } catch let ex as NSError {
                                PMLog.D(" error: \(ex)");
                                
                                {
                                    ex.alertErrorToast()
                                } ~> .main
                            }
                        }
                    }
                }
                
                // fetch contact groups  //TDOO:: this fetch could be removed.
                // TODO: if I don't manually store the labels first, the record won't be saved automatically? (cascade)
                self.labelDataService.fetchLabels(type: 2)
                
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
                    let api = ContactEmailsRequest<ContactEmailsResponse>(page: currentPage, pageSize: pageSize)
                    if let contactsRes = try api.syncCall(api: self.apiService) {
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
                        context.performAndWait() {
                            do {
                                if let contacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                                   fromJSONArray: contactsArray,
                                                                                   in: context) as? [Contact] {
                                    for contact in contacts {
                                        contact.userID = self.userID
                                        let _ = contact.fixName(force: true)
                                        if let emails = contact.emails.allObjects as? [Email] {
                                            emails.forEach { (e) in
                                                e.userID = self.userID
                                            }
                                        }
                                    }
                                    try context.save()
                                }
                            } catch let ex as NSError {
                                PMLog.D("GRTJSONSerialization contact emails error: \(ex) \(ex.userInfo)");
                                
                                {
                                    ex.alertErrorToast()
                                } ~> .main
                            }
                        }
                    }
                }
                
                lastUpdatedStore.contactsCached = 1
                self.isFetching = false
                self.retries = 0
                
                context.performAndWait {
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D(" error: \(error)");
                        {
                            error.alertErrorToast()
                        } ~> .main
                    }
                }
            } catch let ex as NSError {
                lastUpdatedStore.contactsCached = 0
                self.isFetching = false;
                
                {
                    completion?(nil, ex)
                } ~> .main
            }
        } ~> .async
    }
    
    /**
     get contact full details
     
     - Parameter contactID: contact id
     - Parameter completion: async complete response
     **/
    func details(contactID: String, inContext: NSManagedObjectContext? = nil) -> Promise<Contact> {
        return Promise { seal in
            let api = ContactDetailRequest<ContactDetailResponse>(cid: contactID)
            api.call(api: self.apiService) { (task, response, hasError) in
                if let contactDict = response?.contact {
                    let context = inContext ?? CoreDataService.shared.mainManagedObjectContext
                    context.performAndWait() {
                        do {
                            if let contact = try GRTJSONSerialization.object(withEntityName: Contact.Attributes.entityName, fromJSONDictionary: contactDict, in: context) as? Contact {
                                contact.isDownloaded = true
                                let _ = contact.fixName(force: true)
                                if let error = context.saveUpstreamIfNeeded() {
                                    PMLog.D(error.localizedDescription)
                                    seal.reject(error)
                                } else {
                                    context.processPendingChanges()
                                    seal.fulfill(contact)
                                }
                            } else {
                                seal.reject(NSError.unableToParseResponse(response))
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
        let context = CoreDataService.shared.mainManagedObjectContext
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
        
        let context = CoreDataService.shared.backgroundManagedObjectContext // VALIDATE
        async {
            let getEmail = UserEmailPubKeys(email: email, api: self.apiService).run()
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
                }.catch({ (error) in
                    PMLog.D(error.localizedDescription)
                    complete?(nil, -1)
                })
        }
    }
}

//// MARK: AddressBook contact extension
extension ContactDataService {
    typealias ContactVOCompletionBlock = ((_ contacts: [ContactVO], _ error: Error?) -> Void)
    
    func allContactVOs() -> [ContactVO] {
        var contacts: [ContactVO] = []
        
        for email in self.allEmails() {
            contacts.append(ContactVO(id: email.contactID,
                                      name: email.name,
                                      email: email.email,
                                      isProtonMailContact: true))
        }
        
        return contacts
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
            let context = CoreDataService.shared.backgroundManagedObjectContext // VALIDATE
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
