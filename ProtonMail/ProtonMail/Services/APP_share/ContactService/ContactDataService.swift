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

typealias ContactFetchComplete = (NSError?) -> Void
typealias ContactDeleteComplete = (NSError?) -> Void
typealias ContactUpdateComplete = (NSError?) -> Void

protocol ContactProviderProtocol: AnyObject {
    /// Returns the Contacts for a given list of contact ids from the local storage
    func getContactsByIds(_ ids: [String]) -> [ContactEntity]
    /// Given a user and a list of email addresses, returns all the contacts that exist in the local storage
    func getEmailsByAddress(_ emailAddresses: [String], for userId: UserID) -> [EmailEntity]

    func getAllEmails() -> [Email]
    func fetchContacts(completion: ContactFetchComplete?)
    func cleanUp() -> Promise<Void>
}

class ContactDataService: Service {

    private let addressBookService: AddressBookService
    private let labelDataService: LabelsDataService
    private let coreDataService: CoreDataService
    private let apiService: APIService
    private let userInfo: UserInfo
    private let contactCacheStatus: ContactCacheStatusProtocol
    private let cacheService: CacheService
    private weak var queueManager: QueueManager?

    private var userID: UserID {
        UserID(userInfo.userId)
    }

    init(api: APIService, labelDataService: LabelsDataService, userInfo: UserInfo, coreDataService: CoreDataService, contactCacheStatus: ContactCacheStatusProtocol, cacheService: CacheService, queueManager: QueueManager) {
        self.userInfo = userInfo
        self.apiService = api
        self.addressBookService = AddressBookService()
        self.labelDataService = labelDataService
        self.coreDataService = coreDataService
        self.contactCacheStatus = contactCacheStatus
        self.cacheService = cacheService
        self.queueManager = queueManager
    }

    /**
     clean contact local cache
     **/
    func cleanUp() -> Promise<Void> {
        return Promise { seal in
            self.contactCacheStatus.contactsCached = 0
            self.coreDataService.performOnRootSavingContext { context in
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
            coreDataService.enqueueOnRootSavingContext { context in
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
             completion: @escaping (Error?) -> Void) {
        let route = ContactAddRequest(cards: cards, authCredential: authCredential, importedFromDevice: importFromDevice)
        self.apiService.perform(request: route, response: ContactAddResponse()) { [weak self] _, response in
            guard let self = self else { return }
            var contactsData: [[String: Any]] = []
            var lastError: NSError?

            let results = response.results
            guard !results.isEmpty,
                  cards.count == results.count else {
                DispatchQueue.main.async {
                    completion(lastError)
                }
                return
            }

            for (i, res) in results.enumerated() {
                if let error = res as? NSError {
                    lastError = error
                } else if var contact = res as? [String: Any] {
                    contact["Cards"] = cards[i].toDictionary()
                    contactsData.append(contact)
                }
            }

            if !contactsData.isEmpty {
                self.cacheService.addNewContact(serverResponse: contactsData, localContactObjectID: objectID) { error in
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(lastError)
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
                cards: [CardData], completion: @escaping ContactUpdateComplete) {
        let api = ContactUpdateRequest(contactid: contactID.rawValue, cards:cards)
        self.apiService.perform(request: api, response: ContactDetailResponse()) { _, response in
            if let error = response.error {
                completion(error.toNSError)
            } else if var contactDict = response.contact {
                // api is not returning the cards data so set it use request cards data
                // check is contactDict has cards if doesnt exsit set it here
                if contactDict["Cards"] == nil {
                    contactDict["Cards"] = cards.toDictionary()
                }

                self.cacheService.updateContact(contactID: contactID, cardsJson: contactDict, completion: completion)
            } else {
                completion(NSError.unableToParseResponse(response))
            }
        }
    }

    /**
     delete a contact

     - Parameter contactID: delete contact id
     - Parameter completion: async delete process complete response
     **/
    func delete(contactID: ContactID, completion: @escaping ContactDeleteComplete) {
        guard let api = ContactDeleteRequest(ids: [contactID.rawValue]) else {
            completion(NSError.badParameter(contactID.rawValue))
            return
        }
        self.apiService.perform(request: api, response: VoidResponse()) { [weak self] _, response in
            guard let self = self else { return }
            if let error = response.error {
                if error.responseCode == 13043 { // doesn't exist
                    self.cacheService.deleteContact(by: contactID) { _ in
                        DispatchQueue.main.async {
                            completion(error.toNSError)
                        }
                    }
                } else {
                    self.coreDataService.performOnRootSavingContext { context in
                        let contact = Contact.contactForContactID(contactID.rawValue, inManagedObjectContext: context)
                        contact?.isSoftDeleted = false
                        _ = context.saveUpstreamIfNeeded()
                        
                        DispatchQueue.main.async {
                            completion(error.toNSError)
                        }
                    }
                }
            } else {
                self.cacheService.deleteContact(by: contactID) { (error) in
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            }
        }
    }

    /**
     get all contacts from server

     - Parameter completion: async complete response
     **/
    fileprivate var isFetching: Bool = false
    fileprivate var retries: Int = 0
    func fetchContacts(completion: ContactFetchComplete?) {
        if contactCacheStatus.contactsCached == 1 || isFetching {
            completion?(nil)
            return
        }

        if self.retries > 3 {
            contactCacheStatus.contactsCached = 0
            self.isFetching = false
            self.retries = 0
            completion?(nil)
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
                        self.cacheService.addNewContact(serverResponse: contacts, shouldFixName: true) { error in
                            if let err = error {
                                DispatchQueue.main.async {
                                    (err as NSError).alertErrorToast()
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
                        group.enter()
                        self.cacheService.addNewContact(serverResponse: contactsArray) { error in
                            if let err = error {
                                DispatchQueue.main.async {
                                    (err as NSError).alertErrorToast()
                                }
                            }
                            group.leave()
                        }
                        group.wait()
                    }
                }
                self.contactCacheStatus.contactsCached = 1
                self.isFetching = false
                self.retries = 0

                completion?(nil)

            } catch let ex as NSError {
                self.contactCacheStatus.contactsCached = 0
                self.isFetching = false; {
                    completion?(ex)
                } ~> .main
            }
        }
    }

    func getContactsByIds(_ ids: [String]) -> [ContactEntity] {
        coreDataService.read { context in
            let contacts: [Contact] = cacheService.selectByIds(context: context, ids: ids)
            return contacts.map(ContactEntity.init)
        }
    }

    func getEmailsByAddress(_ emailAddresses: [String], for userId: UserID) -> [EmailEntity] {
        let request = NSFetchRequest<Email>(entityName: Email.Attributes.entityName)
        let emailPredicate = NSPredicate(format: "%K in %@", Email.Attributes.email, emailAddresses)
        let userIDPredicate = NSPredicate(format: "%K == %@", Email.Attributes.userID, userID.rawValue)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            emailPredicate,
            userIDPredicate
        ])
        request.sortDescriptors = [NSSortDescriptor(key: Email.Attributes.email, ascending: false)]

        return coreDataService.read { newContext in
            let result = (try? newContext.fetch(request)) ?? []
            return result.map(EmailEntity.init)
        }
    }

    /**
     get contact full details

     - Parameter contactID: contact id
     - Parameter completion: async complete response
     **/
    func details(contactID: String) -> Promise<ContactEntity> {
        return Promise { seal in
            let api = ContactDetailRequest(cid: contactID)
            self.apiService.perform(request: api, response: ContactDetailResponse()) { _, response in
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
        let userID = self.userID
        var error: NSError?
        coreDataService.performAndWaitOnRootSavingContext { [weak self] context in
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

    func queueUpdate(objectID: NSManagedObjectID, cardDatas: [CardData], newName: String, emails: [ContactEditEmail], completion: ContactUpdateComplete?) {
        coreDataService.performOnRootSavingContext { [weak self] context in
            guard let self = self else { return }
            do {
                guard let contactInContext = try context.existingObject(with: objectID) as? Contact else {
                    let error = NSError(domain: "", code: -1,
                                        localizedDescription: LocalString._error_no_object)
                    completion?(error)
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
                    completion?(error)
                } else {
                    let idString = objectID.uriRepresentation().absoluteString
                    let action: MessageAction = .updateContact(objectID: idString,
                                                               cardDatas: cardDatas)
                    let task = QueueManager.Task(messageID: "", action: action, userID: self.userID, dependencyIDs: [], isConversation: false)
                    _ = self.queueManager?.addTask(task)
                    completion?(nil)
                }
            } catch {
                completion?(error as NSError)
            }
        }
    }

    func queueDelete(objectID: NSManagedObjectID, completion: ContactDeleteComplete?) {
        coreDataService.performOnRootSavingContext { context in
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
            .map { ContactVO(name: $0.name, email: $0.email, isProtonMailContact: true) }
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

    func makeAllEmailsFetchedResultController() -> NSFetchedResultsController<Email>? {
        let context = coreDataService.mainContext
        let isContactCombine = userCachedStatus.isCombineContactOn
        let fetchRequest = NSFetchRequest<Email>(entityName: Email.Attributes.entityName)
        let predicate = isContactCombine ? nil : NSPredicate(format: "%K == %@", Email.Attributes.userID, self.userID.rawValue)
        fetchRequest.predicate = predicate
        let sortByTime = NSSortDescriptor(
            key: Email.Attributes.lastUsedTime,
            ascending: false
        )
        let sortByName = NSSortDescriptor(
            key: Email.Attributes.name,
            ascending: true,
            selector: #selector(NSString.caseInsensitiveCompare(_:))
        )
        let sortByEmail = NSSortDescriptor(
            key: Email.Attributes.email,
            ascending: true,
            selector: #selector(NSString.caseInsensitiveCompare(_:))
        )
        fetchRequest.sortDescriptors = [sortByTime, sortByName, sortByEmail]
        let fetchedResultController = NSFetchedResultsController<Email>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        return fetchedResultController
    }
}

extension ContactDataService: ContactProviderProtocol {
    func getAllEmails() -> [Email] {
        return allAccountEmails()
    }
}
