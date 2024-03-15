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
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreServices

typealias ContactFetchComplete = (NSError?) -> Void
typealias ContactDeleteComplete = (NSError?) -> Void
typealias ContactUpdateComplete = (NSError?) -> Void

protocol ContactProviderProtocol: AnyObject {
    /// Returns the Contacts from the local storage for a given list of contact ids
    func getContactsByIds(_ ids: [String]) -> [ContactEntity]
    /// Returns the Contacts from the local storage for a given list of contact uuids
    func getContactsByUUID(_ uuids: [String]) -> [ContactEntity]
    /// Given a list of email addresses, returns all the contacts that exist in the local storage
    func getContactsByEmailAddress(_ emailAddresses: [String]) -> [ContactEntity]
    /// Given a list of email addresses, returns all the Email objects that exist in the local storage
    func getEmailsByAddress(_ emailAddresses: [String]) -> [EmailEntity]
    /// Returns the ids of those contacts without vCards out a given a list of contact ids
    func getContactsWithoutVCards(from contactIDs: [ContactID]) -> [ContactID]
    /// Call this function to store a Contact that has been created locally. This function will also create the associated Email objects
    /// - Returns: The CoreData objectID
    func createLocalContact(
        uuid: String,
        name: String,
        emails: [(address: String, type: ContactFieldType)],
        cards: [CardData]
    ) throws -> String

    func getAllEmails() -> [EmailEntity]
    func fetchContacts(completion: ContactFetchComplete?)
    func cleanUp()
    func fetchContact(contactID: ContactID) async throws -> ContactEntity
    /// Sends parallel fetch contact requests and saves them to Core Data
    func fetchContactsInParallel(contactIDs: [ContactID]) async
}

// sourcery:mock
protocol ContactDataServiceProtocol: AnyObject {
    #if !APP_EXTENSION
    func queueUpdate(objectID: NSManagedObjectID, cardDatas: [CardData], newName: String, emails: [ContactEditEmail], completion: ContactUpdateComplete?)
    func queueAddContact(cardDatas: [CardData], name: String, emails: [ContactEditEmail], importedFromDevice: Bool) -> NSError?
    func queueDelete(objectID: NSManagedObjectID, completion: ContactDeleteComplete?)
    #endif
}

class ContactDataService {

    private let addressBookService: AddressBookService
    private let labelDataService: LabelsDataService
    private let coreDataService: CoreDataContextProviderProtocol
    private let apiService: APIService
    private let userInfo: UserInfo
    private let cacheService: CacheService
    private weak var queueManager: QueueManager?
    private let userDefaults: UserDefaults

    private var userID: UserID {
        UserID(userInfo.userId)
    }

    init(api: APIService, labelDataService: LabelsDataService, userInfo: UserInfo, coreDataService: CoreDataContextProviderProtocol, cacheService: CacheService, queueManager: QueueManager, userDefaults: UserDefaults) {
        self.userInfo = userInfo
        self.apiService = api
        self.addressBookService = AddressBookService()
        self.labelDataService = labelDataService
        self.coreDataService = coreDataService
        self.cacheService = cacheService
        self.queueManager = queueManager
        self.userDefaults = userDefaults
    }

    /**
     clean contact local cache
     **/
    func cleanUp() {
            userDefaults[.areContactsCached] = 0
            let userID = userID.rawValue

            self.coreDataService.performAndWaitOnRootSavingContext { context in
                Contact.delete(
                    in: context,
                    basedOn: NSPredicate(format: "%K == %@", Contact.Attributes.userID, userID)
                )

                Email.delete(
                    in: context,
                    basedOn: NSPredicate(format: "%K == %@", Email.Attributes.userID, userID)
                )

                LabelUpdate.delete(
                    in: context,
                    basedOn: NSPredicate(format: "%K == %@", LabelUpdate.Attributes.userID, userID)
                )
        }
    }

    func fetchUUIDsForAllContact() throws -> [String] {
        return try coreDataService.read { context in
            let request = NSFetchRequest<Contact>(entityName: Contact.Attributes.entityName)
            let sortDescriptor = NSSortDescriptor(
                key: Contact.Attributes.name,
                ascending: true,
                selector: #selector(NSString.caseInsensitiveCompare(_:))
            )
            request.sortDescriptors = [sortDescriptor]
            request.predicate = NSPredicate(
                format: "%K == %@ AND %K == 0",
                Contact.Attributes.userID,
                userID.rawValue,
                Contact.Attributes.isSoftDeleted
            )
            return try context.fetch(request).map(\.uuid)
        }
    }

    /**
     add new contacts

     - Parameter contactsCards: array of array of vCards for multiple contacts (each contact has an array of vCards)
     - Parameter objectID: CoreData object ID of local contacts to delete
     - Parameter completion: async add contact complete response
     **/
    func add(
        contactsCards: [[CardData]],
        objectsURIs: [String],
        importFromDevice: Bool,
        completion: @escaping (Error?) -> Void
    ) {
        let route = ContactAddRequest(cards: contactsCards, importedFromDevice: importFromDevice)
        self.apiService.perform(
            request: route,
            response: ContactAddResponse(),
            callCompletionBlockUsing: .immediateExecutor
        ) { [weak self] _, response in
            guard let self = self else { return }
            if let error = response.error {
                completion(error.toNSError)
            } else {
                var contactsData: [[String: Any]] = []
                var lastError: NSError?

                let results = response.results
                guard !results.isEmpty, contactsCards.count == results.count else {
                    completion(lastError)
                    return
                }

                for (i, res) in results.enumerated() {
                    if let error = res as? NSError {
                        reportContactCreateError(error: error)
                        lastError = error
                    } else if var contact = res as? [String: Any] {
                        contact["Cards"] = contactsCards[i].toDictionary()
                        contactsData.append(contact)
                    }
                }

                if !contactsData.isEmpty {
                    self.cacheService.addNewContact(serverResponse: contactsData, localContactsURIs: objectsURIs) { error in
                        completion(error)
                    }
                } else {
                    completion(lastError)
                }
            }
        }
    }

    private func reportContactCreateError(error: NSError) {
        SystemLogger.log(error: error, category: .contacts)
        Analytics.shared.sendError(.contactCreateFailInBatch(error: error))
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
                self.reportContactUpdateError(error: error)
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

    private func reportContactUpdateError(error: ResponseError) {
        SystemLogger.log(error: error.toNSError, category: .contacts)
        if let httpCode = error.httpCode, (400...499).contains(httpCode) {
            Analytics.shared.sendError(.contactUpdateFail(error: error.toNSError))
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
                if error.responseCode == 13043 ||
                    error.responseCode == APIErrorCode.resourceDoesNotExist { // doesn't exist
                    self.cacheService.deleteContact(by: contactID) { _ in
                        DispatchQueue.main.async {
                            completion(nil)
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
        if userDefaults[.areContactsCached] == 1 || isFetching {
            completion?(nil)
            return
        }

        if self.retries > 3 {
            userDefaults[.areContactsCached] = 0
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
                self.userDefaults[.areContactsCached] = 1
                self.isFetching = false
                self.retries = 0

                completion?(nil)

            } catch let ex as NSError {
                self.userDefaults[.areContactsCached] = 0
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

    /// Returns the contacts in CoreData that match any of the UUID values passed. The UUID is not
    /// the ObjectId but the identifier used when a contact has been imported.
    func getContactsByUUID(_ uuids: [String]) -> [ContactEntity] {
        coreDataService.read { context in
            let request = NSFetchRequest<Contact>(entityName: Contact.Attributes.entityName)
            request.predicate = NSPredicate(
                format: "%K == %@ AND %K == 0 AND uuid IN %@",
                Contact.Attributes.userID,
                userID.rawValue,
                Contact.Attributes.isSoftDeleted,
                uuids
            )
            do {
                let result: [Contact] = try context.fetch(request)
                return result.map(ContactEntity.init)
            } catch {
                PMAssertionFailure(error)
                return []
            }
        }
    }

    func getContactsByEmailAddress(_ emailAddresses: [String]) -> [ContactEntity] {
        let emailEntities = getEmailsByAddress(emailAddresses)
        return getContactsByIds(emailEntities.map(\.contactID.rawValue))
    }

    func getEmailsByAddress(_ emailAddresses: [String]) -> [EmailEntity] {
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

    func getContactsWithoutVCards(from contactIDs: [ContactID]) -> [ContactID] {
        let contactIDsStr = contactIDs.map(\.rawValue)
        return coreDataService.read { context in
            let request = NSFetchRequest<Contact>(entityName: Contact.Attributes.entityName)
            request.predicate = NSPredicate(
                format: "%K == %@ AND %K in %@ AND (%K == nil OR %K == '')",
                Contact.Attributes.userID,
                userID.rawValue,
                Contact.Attributes.contactID,
                contactIDsStr,
                Contact.Attributes.cardData,
                Contact.Attributes.cardData
            )
            do {
                let requestResult: [Contact] = try context.fetch(request)
                return requestResult.map(\.contactID).compactMap(ContactID.init(rawValue:))
            } catch {
                PMAssertionFailure(error)
                return []
            }
        }
    }

    func createLocalContact(
        uuid: String,
        name: String,
        emails: [(address: String, type: ContactFieldType)],
        cards: [CardData]
    ) throws -> String {
        let userID = userID
        let contact = try coreDataService.write { context in
            let contact = Contact(context: context)
            contact.userID = userID.rawValue
            contact.contactID = UUID().uuidString
            contact.name = name
            contact.cardData = try cards.toJSONString()
            contact.size = NSNumber(value: 0)
            contact.uuid = uuid
            contact.createTime = Date()

            emails.forEach { email in
                let mail = Email(context: context)
                mail.userID = contact.userID
                mail.contactID = contact.contactID
                mail.name = contact.name
                mail.contact = contact
                mail.emailID = UUID().uuidString
                mail.email = email.address
                mail.type = email.type.rawString
                mail.defaults = NSNumber(value: 1)
            }
            return contact
        }
        return contact.objectID.uriRepresentation().absoluteString
    }

    func fetchContactsInParallel(contactIDs: [ContactID]) async {
        await withTaskGroup(of: Void.self) { [weak self] group in
            guard let self else { return }
            let maxConcurrentTasks = 3
            for (index, id) in contactIDs.enumerated() {
                group.addTask {
                    do {
                        _ = try await self.fetchContact(contactID: id)
                    } catch {
                        SystemLogger.log(message: "fetch contact error \(error)", category: .contacts, isError: true)
                    }
                }
                if index >= maxConcurrentTasks - 1 {
                    _ = await group.next()
                }
            }
            await group.waitForAll()
        }
    }

    func fetchContact(contactID: ContactID) async throws -> ContactEntity {
        let request = ContactDetailRequest(cid: contactID.rawValue)
        let result = await apiService.perform(request: request, response: ContactDetailResponse())
        if let error = result.1.error {
            throw error
        } else if let contactDict = result.1.contact {
            return try cacheService.updateContactDetail(serverResponse: contactDict)
        } else {
            throw NSError.unableToParseResponse(result.1)
        }
    }

    func allEmails() -> [EmailEntity] {
        return coreDataService.read { context in
            return allEmailsInManagedObjectContext(context)
                .compactMap(EmailEntity.init)
        }
    }

    func allAccountEmails() -> [EmailEntity] {
        return coreDataService.read { context in
            return allEmailsInManagedObjectContext(context)
                .filter { $0.userID == userID.rawValue }
                .compactMap(EmailEntity.init)
        }
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
        return coreDataService.read { context in
            do {
                let emails = try context.fetch(request)
                return emails.compactMap(EmailEntity.init)
            } catch {
                PMAssertionFailure(error)
                return []
            }
        }
    }

    private func fetchContacts(by contactIDs: [String]) -> [ContactEntity] {
        let request = NSFetchRequest<Contact>(entityName: Contact.Attributes.entityName)
        request.predicate = NSPredicate(format: "%K in %@ AND %K == 0 AND %K == %@",
                                        Contact.Attributes.contactID,
                                        contactIDs,
                                        Contact.Attributes.isSoftDeleted,
                                        Contact.Attributes.userID,
                                        self.userID.rawValue)
        return coreDataService.read { context in
            do {
                let contacts = try context.fetch(request)
                return contacts.compactMap(ContactEntity.init)
            } catch {
                PMAssertionFailure(error)
                return []
            }
        }
    }

    private func allEmailsInManagedObjectContext(_ context: NSManagedObjectContext) -> [Email] {
        let fetchRequest = NSFetchRequest<Email>(entityName: Email.Attributes.entityName)
        do {
            return try context.fetch(fetchRequest)
        } catch {
        }
        return []
    }
}

// MRAK: Queue related
extension ContactDataService: ContactDataServiceProtocol {
    #if !APP_EXTENSION
    func queueAddContact(cardDatas: [CardData], name: String, emails: [ContactEditEmail], importedFromDevice: Bool) -> NSError? {
        let userID = self.userID
        var error: NSError?
        var objectID: String?
        coreDataService.performAndWaitOnRootSavingContext { context in
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
                objectID = contact.objectID.uriRepresentation().absoluteString
            } catch {
                return
            }
        }
        if let objectID = objectID {
            let action: MessageAction = .addContacts(
                objectIDs: [objectID],
                contactsCards: [cardDatas],
                importFromDevice: importedFromDevice
            )
            let task = QueueManager.Task(messageID: "", action: action, userID: userID, dependencyIDs: [], isConversation: false)
            _ = self.queueManager?.addTask(task)
        }
        return error
    }

    func queueUpdate(objectID: NSManagedObjectID, cardDatas: [CardData], newName: String, emails: [ContactEditEmail], completion: ContactUpdateComplete?) {
        var result: Swift.Result<Void, NSError>!
        coreDataService.performAndWaitOnRootSavingContext { context in
            do {
                guard let contactInContext = try context.existingObject(with: objectID) as? Contact else {
                    let error = NSError(domain: "", code: -1,
                                        localizedDescription: LocalString._error_no_object)
                    result = .failure(error)
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
                    result = .failure(error)
                } else {
                    result = .success(())
                }
            } catch {
                result = .failure(error as NSError)
            }
        }

        switch result {
        case .failure(let error):
            completion?(error)
        case .success(_):
            let idString = objectID.uriRepresentation().absoluteString
            let action: MessageAction = .updateContact(objectID: idString,
                                                       cardDatas: cardDatas)
            let task = QueueManager.Task(messageID: "", action: action, userID: self.userID, dependencyIDs: [], isConversation: false)
            _ = self.queueManager?.addTask(task)
            completion?(nil)
        case .none:
            break
        }
    }

    func queueDelete(objectID: NSManagedObjectID, completion: ContactDeleteComplete?) {
        var result: Swift.Result<Void, NSError>!
        coreDataService.performAndWaitOnRootSavingContext { context in
            do {
                guard let contactInContext = try context.existingObject(with: objectID) as? Contact else {
                    let error = NSError(domain: "", code: -1,
                                        localizedDescription: LocalString._error_no_object)
                    result = .failure(error)
                    return
                }
                contactInContext.isSoftDeleted = true
                if let error = context.saveUpstreamIfNeeded() {
                    result = .failure(error as NSError)
                } else {
                    result = .success(())
                }
            } catch {
                result = .failure(error as NSError)
            }
        }

        switch result {
        case .failure(let error):
            completion?(error)
        case .success(_):
            let idString = objectID.uriRepresentation().absoluteString
            let action: MessageAction = .deleteContact(objectID: idString)
            let task = QueueManager.Task(messageID: "", action: action, userID: self.userID, dependencyIDs: [], isConversation: false)
            _ = self.queueManager?.addTask(task)
            completion?(nil)
        case .none:
            break
        }
    }
    #endif
}

// MARK: AddressBook contact extension
extension ContactDataService {
    typealias ContactVOCompletionBlock = ((_ contacts: [ContactVO], _ error: Error?) -> Void)

    func allContactVOs() -> [ContactVO] {
        return coreDataService.read { context in
            self.allEmailsInManagedObjectContext(context)
                .filter { $0.userID == userID.rawValue }
                .map { ContactVO(name: $0.name, email: $0.email, isProtonMailContact: true) }
        }
    }

    func getContactVOsFromPhone(_ completion: @escaping ContactVOCompletionBlock) {
        guard addressBookService.hasAccessToAddressBook() else {
            addressBookService.requestAuthorizationWithCompletion { granted, error in
                if granted {
                    self.addressBookService.fetchDeviceContactsInContactVO { contactVOs in
                        completion(contactVOs, nil)
                    }
                } else {
                    completion([], error)
                }
            }
            return
        }
        addressBookService.fetchDeviceContactsInContactVO { contactVOs in
            completion(contactVOs, nil)
        }
    }
}

extension ContactDataService: ContactProviderProtocol {
    func getAllEmails() -> [EmailEntity] {
        return allAccountEmails()
    }
}
