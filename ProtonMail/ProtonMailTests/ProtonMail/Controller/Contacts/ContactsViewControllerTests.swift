// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class ContactsViewControllerTests: XCTestCase {

    private var sut: ContactsViewController!
    private var viewModel: ContactsViewModel!
    private var userID: UserID!

    private var userContainer: UserContainer!
    private var mockUser: UserManager!
    private var mockContextProvider: MockCoreDataContextProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()
        userID = .init(String.randomString(20))
        mockUser = try .prepareUser(apiMock: APIServiceMock(), userID: userID)
        let globalContainer = GlobalContainer()
        mockContextProvider = .init()
        globalContainer.contextProviderFactory.register { self.mockContextProvider }
        userContainer = UserContainer(userManager: mockUser, globalContainer: globalContainer)
        viewModel = .init(dependencies: userContainer)
        sut = .init(viewModel: viewModel, dependencies: userContainer)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        sut = nil
        viewModel = nil
        mockUser = nil
        mockContextProvider = nil
        userID = nil
        userContainer = nil
    }

    func testInit_deleteDataInCache_viewIsUpdated() throws {
        var contactIDs: [ContactID] = []
        for _ in 0..<10 {
            contactIDs.append(.init(String.randomString(20)))
        }
        let contacts = try prepareTestData(contactIDs: contactIDs)
        sut.loadViewIfNeeded()
        wait(self.sut.tableView.visibleCells.count == contacts.count)

        for contact in contacts {
            XCTAssertNotNil(sut.tableView.find(UILabel.self, by: { $0.text == contact.name }))
        }

        // Delete contact
        try mockContextProvider.write(block: { context in
            if let contact = Contact.contactForContactID(contacts[0].contactID.rawValue, inManagedObjectContext: context) {
                context.delete(contact)
            }
            try context.save()
        })

        wait(self.sut.tableView.visibleCells.count == (contacts.count - 1))
    }

    func testInit_editDataInCache_viewIsUpdated() throws {
        let contactIDs: [ContactID] = [.init(String.randomString(20))]
        let contacts = try prepareTestData(contactIDs: contactIDs)
        let contactToEdit = try XCTUnwrap(contacts.first)
        let newName = String.randomString(10)
        sut.loadViewIfNeeded()
        wait(self.sut.tableView.visibleCells.count == 1)

        XCTAssertNotNil(sut.tableView.find(UILabel.self, by: { $0.text == contactToEdit.name }))

        // Edit contact
        try mockContextProvider.write(block: { context in
            if let contact = Contact.contactForContactID(contactToEdit.contactID.rawValue, inManagedObjectContext: context) {
                contact.name = newName
            }
            try context.save()
        })

        wait(self.sut.tableView.firstVisibleCell(ofType: ContactsTableViewCell.self, withLabel: newName) != nil)

        XCTAssertNil(self.sut.tableView.firstVisibleCell(ofType: ContactsTableViewCell.self, withLabel: contactToEdit.name))
    }

    func testSearch_searchResultIsExpected() throws {
        let contactIDs: [ContactID] = [.init(String.randomString(20)), .init(stringLiteral: String.randomString(20))]
        let contacts = try prepareTestData(contactIDs: contactIDs)
        let contactToBeSearched = try XCTUnwrap(contacts.first)
        sut.loadViewIfNeeded()
        wait(self.sut.tableView.visibleCells.count == contactIDs.count)

        // search
        sut.searchController?.simulateType(text: contactToBeSearched.name)
        wait(self.sut.tableView.visibleCells.count == 1)
        XCTAssertNotNil(
            sut.tableView.firstVisibleCell(ofType: ContactsTableViewCell.self, withLabel: contactToBeSearched.name)
        )
    }

    private func prepareTestData(contactIDs: [ContactID]) throws -> [ContactEntity] {
        return try mockContextProvider.write { context in
            var results: [ContactEntity] = []
            for contactID in contactIDs {
                let contact = Contact(context: context)
                contact.userID = self.userID.rawValue
                contact.contactID = contactID.rawValue
                contact.name = String.randomString(20)
                let emailsArray = contact.mutableSetValue(forKey: Contact.Attributes.emails)
                let email = Email(context: context)
                email.contact = contact
                email.email = "test@pm.me"
                emailsArray.add(email)
                results.append(.init(contact: contact))
            }
            try context.save()
            return results
        }
    }
}
