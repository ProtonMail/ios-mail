// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CoreData
import PromiseKit
import ProtonCoreTestingToolkitUnitTestsCore

@testable import ProtonMail

class MockContactProvider: ContactProviderProtocol {
    private let coreDataContextProvider: CoreDataContextProviderProtocol

    var allEmailsToReturn: [EmailEntity] = []
    var allContactsToReturn: [ContactEntity] = []
    private(set) var wasCleanUpCalled: Bool = false
    var fetchContactResult: ContactEntity = .make()

    init(coreDataContextProvider: CoreDataContextProviderProtocol) {
        self.coreDataContextProvider = coreDataContextProvider
    }

    func getContactsByIds(_ ids: [String]) -> [ContactEntity] {
        return allContactsToReturn
    }

    @FuncStub(MockContactProvider.getContactsByUUID, initialReturn: []) var getContactsByUUIDStub
    func getContactsByUUID(_ uuids: [String]) -> [ProtonMail.ContactEntity] {
        getContactsByUUIDStub(uuids)
    }

    @FuncStub(MockContactProvider.getContactsByEmailAddress, initialReturn: []) var getContactsByEmailAddressStub
    func getContactsByEmailAddress(_ emailAddresses: [String]) -> [ProtonMail.ContactEntity] {
        getContactsByEmailAddressStub(emailAddresses)
    }

    @FuncStub(MockContactProvider.getEmailsByAddress, initialReturn: []) var getEmailsByAddressStub
    func getEmailsByAddress(_ emailAddresses: [String]) -> [EmailEntity] {
        getEmailsByAddressStub(emailAddresses)
    }

    func getAllEmails() -> [EmailEntity] {
        return allEmailsToReturn
    }

    @FuncStub(MockContactProvider.getContactsWithoutVCards, initialReturn: []) var getContactsWithoutVCardsStub
    func getContactsWithoutVCards(from contactIDs: [ContactID]) -> [ContactID] {
        getContactsWithoutVCardsStub(contactIDs)
    }

    @ThrowingFuncStub(MockContactProvider.createLocalContact, initialReturn: "") var createLocalContactStub
    func createLocalContact(
        uuid: String,
        name: String,
        emails: [(address: String, type: ProtonMail.ContactFieldType)],
        cards: [ProtonMail.CardData]
    ) throws -> String {
        try createLocalContactStub(uuid, name, emails, cards)
    }

    @FuncStub(MockContactProvider.fetchContactsInParallel) var fetchContactsInParallelStub
    func fetchContactsInParallel(contactIDs: [ProtonMail.ContactID]) {
        fetchContactsInParallelStub(contactIDs)
    }

    @FuncStub(MockContactProvider.fetchContacts) var fetchContactsStub
    func fetchContacts(completion: ContactFetchComplete?) {
        fetchContactsStub(completion)
        completion?(nil)
    }

    func cleanUp() {
        wasCleanUpCalled = true
    }

    func fetchContact(contactID: ProtonMail.ContactID) async throws -> ProtonMail.ContactEntity {
        return fetchContactResult
    }

    func contactFetchedController(by contactID: ProtonMail.ContactID) -> NSFetchedResultsController<ProtonMail.Contact> {
        let moc = self.coreDataContextProvider.mainContext
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
}
