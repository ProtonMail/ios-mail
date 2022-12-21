// Copyright (c) 2022 Proton Technologies AG
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
import XCTest

@testable import ProtonMail

final class ComposeViewModelTests: XCTestCase {
    typealias SUT = ComposeViewModelImpl

    private var sut: SUT!
    private var contactProvider: MockContactProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let apiMock = APIServiceMock()
        let coreDataContextProvider = MockCoreDataContextProvider()
        let user = UserManager(api: apiMock, role: .none)

        contactProvider = MockContactProvider(coreDataContextProvider: coreDataContextProvider)

        let dependencies = SUT.Dependencies(
            contactProvider: contactProvider,
            fetchAndVerifyContacts: FetchAndVerifyContacts(user: user))

        sut = ComposeViewModelImpl(
            msg: nil,
            action: .newDraft,
            msgService: user.messageService,
            user: user,
            coreDataContextProvider: coreDataContextProvider,
            dependencies: dependencies
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        contactProvider = nil

        try super.tearDownWithError()
    }

    func testDecodingRecipients_prefersMatchingLocalContactName() throws {
        let email = CoreDataService.shared.read { context in
            let email = Email(context: context)
            let contact = Contact(context: context)
            contact.name = "My friend I don't like"
            email.contact = contact
            return EmailEntity(email: email)
        }

        contactProvider.getEmailsByAddressStub.bodyIs { _, _, _ in
            [email]
        }

        let backendResponse = "[{\"Address\": \"friend@example.com\", \"Name\": \"My friend\", \"Group\": \"\"}]"

        let contacts = sut.toContacts(backendResponse)
        let contact = try XCTUnwrap(contacts.first)
        XCTAssertEqual(contact.displayName, "My friend I don't like")
    }

    func testDecodingRecipients_usesBackendName_ifNoLocalContact() throws {
        let backendResponse = "[{\"Address\": \"friend@example.com\", \"Name\": \"My friend\", \"Group\": \"\"}]"

        let contacts = sut.toContacts(backendResponse)
        let contact = try XCTUnwrap(contacts.first)
        XCTAssertEqual(contact.displayName, "My friend")
    }

    func testDecodingRecipients_usesEmailAsDisplayName_ifNothingElseIsFound() throws {
        let backendResponsesWithoutProperName: [String] = [
            "[{\"Address\": \"friend@example.com\", \"Name\": \" \", \"Group\": \"\"}]",
            "[{\"Address\": \"friend@example.com\", \"Name\": \"\", \"Group\": \"\"}]",
            "[{\"Address\": \"friend@example.com\", \"Group\": \"\"}]"
        ]

        for backendResponse in backendResponsesWithoutProperName {
            let contacts = sut.toContacts(backendResponse)
            let contact = try XCTUnwrap(contacts.first)
            XCTAssertEqual(contact.displayName, "friend@example.com")
        }
    }
}
