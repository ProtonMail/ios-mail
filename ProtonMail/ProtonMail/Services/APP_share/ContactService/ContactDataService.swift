//
//  ContactDataService.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import CoreData
import Contacts
import Groot
import PromiseKit
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services

typealias ContactFetchComplete = (([Contact]?, NSError?) -> Void)
typealias ContactAddComplete = (([Contact]?, NSError?) -> Void)

typealias ContactDeleteComplete = ((NSError?) -> Void)
typealias ContactUpdateComplete = (([Contact]?, NSError?) -> Void)

protocol ContactProviderProtocol: AnyObject {
    /// Returns the Contacts for a given list of contact ids from the local storage
    func getContactsByIds(_ ids: [String]) -> [ContactEntity]
    /// Given a user and a list of email addresses, returns all the contacts that exist in the local storage
    func getEmailsByAddress(_ emailAddresses: [String], for userId: UserID) -> [EmailEntity]

    func fetchAndVerifyContacts(byEmails emails: [String]) -> Promise<[PreContact]>
    func getAllEmails() -> [Email]
    func fetchContacts(fromUI: Bool, completion: ContactFetchComplete?)
    func cleanUp() -> Promise<Void>
}

class ContactDataService: Service, HasLocalStorage {

    private let addressBookService: AddressBookService
    private let labelDataService: LabelsDataService
    private let coreDataService: CoreDataService
    private let apiService: APIService
    private let userInfo: UserInfo
    private var lastUpdatedStore: LastUpdatedStoreProtocol
    private let cacheService: CacheService
    private weak var queueManager: QueueManager?

    private var userID: UserID {
        UserID(userInfo.userId)
    }

    init(api: APIService, labelDataService: LabelsDataService, userInfo: UserInfo, coreDataService: CoreDataService, lastUpdatedStore: LastUpdatedStoreProtocol, cacheService: CacheService, queueManager: QueueManager) {
        self.userInfo = userInfo
        self.apiService = api
        self.addressBookService = AddressBookService()
        self.labelDataService = labelDataService
        self.coreDataService = coreDataService
        self.lastUpdatedStore = lastUpdatedStore
        self.cacheService = cacheService
        self.queueManager = queueManager
    }

    /**
     clean contact local cache
     **/
    func cleanUp() -> Promise<Void> {
        return Promise { seal in
            lastUpdatedStore.contactsCached = 0
            let context = self.coreDataService.operationContext
            context.perform {
                let fetch1 = NSFetchRequest<NSFetchRequestResult>(entityName: Contact.Attributes.entityName)
                fetch1.predicate = NSPredicate(format: "%K == %@", Contact.Attributes.userID, self.userID.rawValue)
                let request1 = NSBatchDeleteRequest(fetchRequest: fetch1)
                try? context.executeAndMergeChanges(using: request1)

                let fetch2 = NSFetchRequest<NSFetchRequestResult>(entityName: Email.Attributes.entityName)
                fetch2.predicate = NSPredicate(format: "%K == %@", Email.Attributes.userID, self.userID.rawValue)
                let request2 = NSBatchDeleteRequest(fetchRequest: fetch2)
                try? context.executeAndMergeChanges(using: request2)

                let fetch3 = NSFetchRequest<NSFetchRequestResult>(entityName: LabelUpdate.Attributes.entityName)
                fetch3.predicate = NSPredicate(format: "%K == %@", LabelUpdate.Attributes.userID, self.userID.rawValue)
                let request3 = NSBatchDeleteRequest(fetchRequest: fetch3)
                try? context.executeAndMergeChanges(using: request3)

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
    func resultController(context: NSManagedObjectContext? = nil) -> NSFetchedResultsController<Contact> {
        let moc = context ?? coreDataService.mainContext
        let fetchRequest = NSFetchRequest<Contact>(entityName: Contact.Attributes.entityName)
        let strComp = NSSortDescriptor(key: Contact.Attributes.name,
                                       ascending: true,
                                       selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [strComp]
        fetchRequest.predicate = NSPredicate(format: "%K == %@ AND %K == 0", Contact.Attributes.userID, self.userID.rawValue, Contact.Attributes.isSoftDeleted)

        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: moc,
                                          sectionNameKeyPath: Contact.Attributes.sectionName,
                                          cacheName: nil)
    }

    func contactFetchedController(by contactID: ContactID) -> NSFetchedResultsController<Contact> {
        let moc = self.coreDataService.mainContext
        let fetchRequest = NSFetchRequest<Contact>(entityName: Contact.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Contact.Attributes.contactID, contactID.rawValue)
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
     - Parameter objectID: CoreData object ID of group label
     - Parameter completion: async add contact complete response
     **/
    func add(cards: [[CardData]],
             authCredential: AuthCredential?,
             objectID: String? = nil,
             importFromDevice: Bool,
             completion: ContactAddComplete?) {
        let route = ContactAddRequest(cards: cards, authCredential: authCredential, importedFromDevice: importFromDevice)
        self.apiService.exec(route: route, responseObject: ContactAddResponse()) { [weak self] response in
            guard let self = self else { return }
            let context = self.coreDataService.operationContext
            var contacts_json: [[String: Any]] = []
            var lasterror: NSError?
            let results = response.results
            context.perform {
                guard !results.isEmpty,
                      cards.count == results.count else {
                    DispatchQueue.main.async {
                        completion?(nil, lasterror)
                    }
                    return
                }

                for (i, res) in results.enumerated() {
                    if let error = res as? NSError {
                        lasterror = error
                        guard let objectID = objectID,
                              let managedID = self.coreDataService.managedObjectIDForURIRepresentation(objectID),
                              let managedObject = try? context.existingObject(with: managedID) else {
                            continue
                        }
                        context.delete(managedObject)
                    } else if var contact = res as? [String: Any] {
                        contact["Cards"] = cards[i].toDictionary()
                        contacts_json.append(contact)
                    }
                }

                if !contacts_json.isEmpty {
                    self.cacheService.addNewContact(serverResponse: contacts_json, objectID: objectID) { (contacts, error) in
                        DispatchQueue.main.async {
                            completion?(contacts, error)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(nil, lasterror)
                    }
                }
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
    func update(contactID: ContactID,
                cards: [CardData], completion: ContactUpdateComplete?) {
        let api = ContactUpdateRequest(contactid: contactID.rawValue, cards:cards)
        self.apiService.exec(route: api, responseObject: ContactDetailResponse()) { (task, response) in
            if let error = response.error {
                completion?(nil, error.toNSError)
            } else if var contactDict = response.contact {
                // api is not returning the cards data so set it use request cards data
                // check is contactDict has cards if doesnt exsit set it here
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
    func delete(contactID: ContactID, completion: @escaping ContactDeleteComplete) {
        let api = ContactDeleteRequest(ids: [contactID.rawValue])
        self.apiService.exec(route: api, responseObject: VoidResponse()) { [weak self] (task, response) in
            guard let self = self else { return }
            let context = self.coreDataService.operationContext
            context.perform {
                if let error = response.error {
                    if error.responseCode == 13043 { // not exsit
                        self.cacheService.deleteContact(by: contactID) { _ in
                        }
                    } else {
                        let contact = Contact.contactForContactID(contactID.rawValue, inManagedObjectContext: context)
                        contact?.isSoftDeleted = false
                        _ = context.saveUpstreamIfNeeded()
                    }
                    DispatchQueue.main.async {
                        completion(error.toNSError)
                    }
                    return
                }
                self.cacheService.deleteContact(by: contactID) { (error) in
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            }
        }
    }

    func fetchAndVerifyContacts(byEmails emails: [String]) -> Promise<[PreContact]> {
        let context = coreDataService.rootSavingContext
        let cardDataParser = CardDataParser(userKeys: userInfo.userKeys)

        return Promise { seal in
            guard let fetchController = Email.findEmailsController(emails, inManagedObjectContext: context) else {
                seal.fulfill([])
                return
            }
            guard let contactEmails = fetchController.fetchedObjects else {
                seal.fulfill([])
                return
            }

            context.performAsPromise { () -> [Promise<ContactEntity>] in
                let noDetails: [Email] = contactEmails.filter { $0.managedObjectContext != nil && $0.defaults == 0 && $0.contact.isDownloaded == false && $0.userID == self.userID.rawValue }
                return noDetails.map { return self.details(contactID: $0.contactID) }
            }.then { fetches in
                when(resolved: fetches)
            }.then { (result: [Result<ContactEntity>]) -> Guarantee<[Promise<PreContact>]> in
                context.performAsPromise {
                    var allEmails = contactEmails
                    if let newFetched = fetchController.fetchedObjects {
                        allEmails = newFetched
                    }

                    let details: [Email] = allEmails.filter { $0.defaults == 0 && $0.contact.isDownloaded && $0.userID == self.userID.rawValue }
                    var parsers: [Promise<PreContact>] = details.map {
                        return cardDataParser.verifyAndParseContact(with: $0.email, from: $0.contact.getCardData())
                    }
                    for r in result {
                        switch r {
                        case .fulfilled(let value):
                            if let fEmail = contactEmails.first(where: { (e) -> Bool in
                                e.contactID == value.contactID.rawValue
                            }) {
                                parsers.append(cardDataParser.verifyAndParseContact(with: fEmail.email, from: value.cardDatas))
                            }
                        case .rejected:
                            break
                        }
                    }

                    return parsers
                }
            }.then { parsers -> Guarantee<[Result<PreContact>]> in
                return when(resolved: parsers)
            }.then { contacts -> Promise<[PreContact]> in
                var completedItems: [PreContact] = [PreContact]()
                for c in contacts {
                    switch c {
                    case .fulfilled(let value):
                        completedItems.append(value)
                    case .rejected:
                        break
                    }
                }
                return .value(completedItems)
            }.done { result in
                seal.fulfill(result)
            }.catch(policy: .allErrors) { error in
                seal.reject(error)
            }
        }
    }

    /**
     get all contacts from server

     - Parameter completion: async complete response
     **/
    fileprivate var isFetching: Bool = false
    fileprivate var retries: Int = 0
    func fetchContacts(fromUI: Bool = true, completion: ContactFetchComplete?) {
        if lastUpdatedStore.contactsCached == 1 || isFetching {
            completion?(nil, nil)
            return
        }

        if self.retries > 3 {
            lastUpdatedStore.contactsCached = 0
            self.isFetching = false
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
                while true {
                    if loop <= 0 || fetched >= total {
                        break
                    }
                    loop = loop - 1

                    let response: ContactsResponse = try `await`(self.apiService.run(route: ContactsRequest()))
                    if response.error == nil {
                        let contacts = response.contacts // TODO:: fix me set userID
                        if fetched == -1 {
                            fetched = contacts.count
                            total = response.total
                            loop = (total / pageSize) - (total % pageSize == 0 ? 1 : 0)
                        } else {
                            fetched = fetched + contacts.count
                        }
                        self.cacheService.addNewContact(serverResponse: contacts, shouldFixName: true) { (_, error) in
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
                while true {
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

                        let group = DispatchGroup()
                        if fromUI {
                            let contactsChunks = contactsArray.chunked(into: 50)
                            for chunk in contactsChunks {
                                group.enter()
                                self.cacheService.addNewContact(serverResponse: chunk, shouldFixName: true) { (_, error) in
                                    if let err = error {
                                        DispatchQueue.main.async {
                                            err.alertErrorToast()
                                        }
                                    }
                                    group.leave()
                                }
                                group.wait()
                                // sleep 50ms to avoid UI glitch
                                usleep(50000)
                            }
                        } else {
                            group.enter()
                            self.cacheService.addNewContact(serverResponse: contactsArray) { _, error in
                                if let err = error {
                                    DispatchQueue.main.async {
                                        err.alertErrorToast()
                                    }
                                }
                                group.leave()
                            }
                            group.wait()
                        }
                    }
                }
                self.lastUpdatedStore.contactsCached = 1
                self.isFetching = false
                self.retries = 0

                completion?(nil, nil)

            } catch let ex as NSError {
                self.lastUpdatedStore.contactsCached = 0
                self.isFetching = false; {
                    completion?(nil, ex)
                } ~> .main
            }
        }
    }

    func getContactsByIds(_ ids: [String]) -> [ContactEntity] {
        let context = coreDataService.makeNewBackgroundContext()
        var result = [ContactEntity]()
        context.performAndWait {
            let contacts: [Contact] = cacheService.selectByIds(context: context, ids: ids)
            result = contacts.map(ContactEntity.init)
        }
        return result
    }

    func getEmailsByAddress(_ emailAddresses: [String], for userId: UserID) -> [EmailEntity] {
        let newContext = coreDataService.makeNewBackgroundContext()
        let request = NSFetchRequest<Email>(entityName: Email.Attributes.entityName)
        let emailPredicate = NSPredicate(format: "%K in %@", Email.Attributes.email, emailAddresses)
        let userIDPredicate = NSPredicate(format: "%K == %@", Email.Attributes.userID, userID.rawValue)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            emailPredicate,
            userIDPredicate
        ])
        request.sortDescriptors = [NSSortDescriptor(key: Email.Attributes.email, ascending: false)]
        var emailEntities = [EmailEntity]()
        newContext.performAndWait {
            let result = (try? newContext.fetch(request)) ?? []
            emailEntities = result.map(EmailEntity.init)
        }
        return emailEntities
    }

    /**
     get contact full details

     - Parameter contactID: contact id
     - Parameter completion: async complete response
     **/
    func details(contactID: String) -> Promise<ContactEntity> {
        return Promise { seal in
            let api = ContactDetailRequest(cid: contactID)
            self.apiService.exec(route: api, responseObject: ContactDetailResponse()) { (task, response) in
                if let error = response.error {
                    seal.reject(error)
                } else if let contactDict = response.contact {
                    self.cacheService.updateContactDetail(serverResponse: contactDict) { (contact, error) in
                        if let err = error {
                            seal.reject(err)
                        } else if let c = contact {
                            seal.fulfill(ContactEntity(contact: c))
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

    func allAccountEmails() -> [Email] {
        let context = coreDataService.mainContext
        return allEmailsInManagedObjectContext(context).filter { $0.userID == userID.rawValue }
    }

    /// Get name from user contacts by the given mail address
    /// - Parameter mailAddress: mail address
    /// - Returns: Contact name or nil if user contact can't find the given address
    func getName(of mailAddress: String) -> String? {
        let mails = self.fetchEmails(with: mailAddress)
            .sorted { mail1, mail2 in
                guard let time1 = mail1.contactCreateTime,
                      let time2 = mail2.contactCreateTime else {
                          return true
                      }
                return time1 < time2
            }
        let contactIDsToFetch = mails.map(\.contactID.rawValue)
        let contacts = fetchContacts(by: contactIDsToFetch)
        var contactsMap: [ContactID: ContactEntity] = [:]
        contacts.forEach { contactsMap[$0.contactID] = $0 }
        for mail in mails {
            guard let contact = contactsMap[mail.contactID] else {
                continue
            }
            let priority: [String] = [contact.name, mail.name]
            guard let value = priority.first(where: { !$0.isEmpty }) else {
                continue
            }
            return value
        }
        return nil
    }

    private func fetchEmails(with address: String) -> [EmailEntity] {
        let request = NSFetchRequest<Email>(entityName: Email.Attributes.entityName)
        request.predicate = NSPredicate(format: "%K == %@", Email.Attributes.email, address)
        var result: [EmailEntity] = []
        coreDataService.mainContext.performAndWait {
            do {
                let emails = try coreDataService.mainContext.fetch(request)
                result = emails.compactMap(EmailEntity.init)
            } catch {
                assertionFailure("\(error)")
            }
        }
        return result
    }

    private func fetchContacts(by contactIDs: [String]) -> [ContactEntity] {
        let request = NSFetchRequest<Contact>(entityName: Contact.Attributes.entityName)
        request.predicate = NSPredicate(format: "%K in %@ AND %K == 0 AND %K == %@",
                                        Contact.Attributes.contactID,
                                        contactIDs,
                                        Contact.Attributes.isSoftDeleted,
                                        Contact.Attributes.userID,
                                        self.userID.rawValue)
        var result: [ContactEntity] = []
        coreDataService.mainContext.performAndWait {
            do {
                let contacts = try coreDataService.mainContext.fetch(request)
                result = contacts.compactMap(ContactEntity.init)
            } catch {
                assertionFailure("\(error)")
            }
        }
        return result
    }
    
    private func allEmailsInManagedObjectContext(_ context: NSManagedObjectContext) -> [Email] {
        let fetchRequest = NSFetchRequest<Email>(entityName: Email.Attributes.entityName)
        do {
            return try context.fetch(fetchRequest)
        } catch {
        }
        return []
    }

    private func allEmailsInManagedObjectContext(_ context: NSManagedObjectContext, isContactCombine: Bool) -> [Email] {
        let fetchRequest = NSFetchRequest<Email>(entityName: Email.Attributes.entityName)
        let predicate = isContactCombine ? nil : NSPredicate(format: "%K == %@", Email.Attributes.userID, self.userID.rawValue)
        fetchRequest.predicate = predicate
        do {
            return try context.fetch(fetchRequest)
        } catch {
        }
        return []
    }
}

// MRAK: Queue related
extension ContactDataService {
    #if !APP_EXTENSION
    func queueAddContact(cardDatas: [CardData], name: String, emails: [ContactEditEmail], importedFromDevice: Bool) -> NSError? {
        let context = self.coreDataService.operationContext
        let userID = self.userID
        var error: NSError?
        context.performAndWait { [weak self] in
            guard let self = self else { return }
            do {
                let contact = try Contact.makeTempContact(context: context,
                                                          userID: userID.rawValue,
                                                          name: name,
                                                          cardDatas: cardDatas,
                                                          emails: emails)
                if let err = context.saveUpstreamIfNeeded() {
                    error = err
                    return
                }
                let objectID = contact.objectID.uriRepresentation().absoluteString
                let action: MessageAction = .addContact(objectID: objectID,
                                                        cardDatas: cardDatas,
                                                        importFromDevice: importedFromDevice)
                let task = QueueManager.Task(messageID: "", action: action, userID: userID, dependencyIDs: [], isConversation: false)
                _ = self.queueManager?.addTask(task)
            } catch {
                return
            }
        }
        return error
    }

    func queueUpdate(objectID: NSManagedObjectID, contactID: String, cardDatas: [CardData], newName: String, emails: [ContactEditEmail], completion: ContactUpdateComplete?) {
        let context = self.coreDataService.operationContext
        context.perform { [weak self] in
            guard let self = self else { return }
            do {
                guard let contactInContext = try context.existingObject(with: objectID) as? Contact else {
                    let error = NSError(domain: "", code: -1,
                                        localizedDescription: LocalString._error_no_object)
                    completion?(nil, error)
                    return
                }
                contactInContext.cardData = try cardDatas.toJSONString()
                contactInContext.name = newName
                if let emailObjects = contactInContext.emails.allObjects as? [Email] {
                    for emailObject in emailObjects {
                        context.delete(emailObject)
                    }
                }
                // These temp emails will be removed when process real api response
                // CacheService > updateContact(contactID:...)
                _ = emails.map { $0.makeTempEmail(context: context, contact: contactInContext) }
                if let error = context.saveUpstreamIfNeeded() {
                    completion?(nil, error)
                } else {
                    let idString = objectID.uriRepresentation().absoluteString
                    let action: MessageAction = .updateContact(objectID: idString,
                                                               cardDatas: cardDatas)
                    let task = QueueManager.Task(messageID: "", action: action, userID: self.userID, dependencyIDs: [], isConversation: false)
                    _ = self.queueManager?.addTask(task)
                    completion?(nil, nil)
                }
            } catch {
                completion?(nil, error as NSError)
            }
        }
    }

    func queueDelete(objectID: NSManagedObjectID, completion: ContactDeleteComplete?) {
        let context = self.coreDataService.operationContext
        context.perform {
            do {
                guard let contactInContext = try context.existingObject(with: objectID) as? Contact else {
                    let error = NSError(domain: "", code: -1,
                                        localizedDescription: LocalString._error_no_object)
                    completion?(error)
                    return
                }
                contactInContext.isSoftDeleted = true
                if let error = context.saveUpstreamIfNeeded() {
                    completion?(error as NSError)
                    return
                }
                let idString = objectID.uriRepresentation().absoluteString
                let action: MessageAction = .deleteContact(objectID: idString)
                let task = QueueManager.Task(messageID: "", action: action, userID: self.userID, dependencyIDs: [], isConversation: false)
                _ = self.queueManager?.addTask(task)
                completion?(nil)
            } catch {
                completion?(error as NSError)
            }
        }
    }
    #endif
}

// MARK: AddressBook contact extension
extension ContactDataService {
    typealias ContactVOCompletionBlock = ((_ contacts: [ContactVO], _ error: Error?) -> Void)

    func allContactVOs() -> [ContactVO] {
        allEmails()
            .filter { $0.userID == userID.rawValue }
            .map { ContactVO(id: $0.contactID, name: $0.name, email: $0.email, isProtonMailContact: true) }
    }

    func getContactVOs(_ completion: @escaping ContactVOCompletionBlock) {
        self.processContacts(lastError: nil, completion: completion)
    }

    func getContactVOsFromPhone(_ completion: @escaping ContactVOCompletionBlock) {
        guard addressBookService.hasAccessToAddressBook() else {
            addressBookService.requestAuthorizationWithCompletion { granted, error in
                if granted {
                    completion(self.addressBookService.contacts(), nil)
                } else {
                    completion([], error)
                }
            }
            return
        }
        completion(addressBookService.contacts(), nil)
    }

    private func processContacts(lastError: Error?, completion: @escaping ContactVOCompletionBlock) {
        struct ContactWrapper: Hashable {
            let contact: ContactVO
            let lastUsedTime: Date?
        }

        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            var contacts: [ContactWrapper] = []

            // merge address book and core data contacts
            let context = self.coreDataService.operationContext // VALIDATE
            context.performAndWait {
                let emailsCache = self.allEmailsInManagedObjectContext(context,
                                                                       isContactCombine: userCachedStatus.isCombineContactOn)
                var pm_contacts: [ContactWrapper] = []
                for email in emailsCache {
                    if email.managedObjectContext != nil {
                        let contact = ContactVO(id: email.contactID, name: email.name, email: email.email, isProtonMailContact: true)
                        pm_contacts.append(ContactWrapper(contact: contact, lastUsedTime: email.lastUsedTime))
                    }
                }
                contacts.append(contentsOf: pm_contacts)
            }

            // sort rule: 1. lastUsedTime 2. name 3. email
            contacts.sort(by: { (first: ContactWrapper, second: ContactWrapper) -> Bool in
                if let t1 = first.lastUsedTime, let t2 = second.lastUsedTime {
                    let result = t1.compare(t2)
                    if result == .orderedAscending {
                        return false
                    } else if result == .orderedDescending {
                        return true
                    }
                }

                if first.lastUsedTime != nil && second.lastUsedTime == nil {
                    return true
                }

                if second.lastUsedTime != nil && first.lastUsedTime == nil {
                    return false
                }

                if first.contact.name.lowercased() != second.contact.name.lowercased() {
                    return first.contact.name.lowercased() < second.contact.name.lowercased()
                } else {
                    return first.contact.email.lowercased() < second.contact.email.lowercased()
                }
            })

            // Remove the duplicated items
            var set = Set<ContactVO>()
            var filteredResult = [ContactVO]()
            for wrapper in contacts {
                if !set.contains(wrapper.contact) {
                    set.insert(wrapper.contact)
                    filteredResult.append(wrapper.contact)
                }
            }

            DispatchQueue.main.async {
                completion(filteredResult, lastError)
            }
        }
    }
}

extension ContactDataService: ContactProviderProtocol {
    func getAllEmails() -> [Email] {
        return allAccountEmails()
    }
}
