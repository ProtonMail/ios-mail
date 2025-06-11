// Copyright (c) 2024 Proton Technologies AG
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

@testable import InboxContacts
import InboxCoreUI
import InboxTesting
import proton_app_uniffi
import XCTest

final class ContactDetailsStateStoreTests: BaseTestCase {
    private var sut: ContactDetailsStateStore!
    private var initialState: ContactDetails!
    private var contactItem: ContactItem!
    private var providerSpy: ContactDetailsProviderSpy!
    private var urlOpener: EnvironmentURLOpenerSpy!
    private var toastStateStore: ToastStateStore!

    override func setUp() {
        super.setUp()
        contactItem = .elenaErickson
        initialState = .init(contact: contactItem, details: .none)
        providerSpy = .init()
        urlOpener = .init()
        toastStateStore = .init(initialState: .initial)

        sut = ContactDetailsStateStore(
            state: initialState,
            item: contactItem,
            provider: .init(contactDetails: { [unowned self] contact in
                providerSpy.contactDetailsCalls.append(contact)
                return providerSpy.stubbedContactDetails[contact]!
            }),
            urlOpener: urlOpener,
            toastStateStore: toastStateStore
        )
    }

    override func tearDown() {
        sut = nil
        initialState = nil
        contactItem = nil
        providerSpy = nil
        urlOpener = nil
        toastStateStore = nil
        super.tearDown()
    }

    func testInitialState_isSetCorrectly() {
        XCTAssertEqual(sut.state, initialState)
    }

    func testOnLoadAction_ItFetchesDetailsAndUpdatesState() async {
        let details = ContactDetailCard(id: contactItem.id, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        await sut.handle(action: .onLoad)

        XCTAssertEqual(sut.state, .init(contact: contactItem, details: details))
    }

    func testCallToPhoneNumberAction_ItOpensURLWithTelPrefix() async {
        let details = ContactDetailCard(id: contactItem.id, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        let phone = "+41772223344"

        await sut.handle(action: .onLoad)
        await sut.handle(action: .call(phoneNumber: phone))

        XCTAssertEqual(urlOpener.callAsFunctionInvokedWithURL, [URL(string: "tel://\(phone)")])
    }

    func testOpenURLAction_ItOpensURL() async {
        let details = ContactDetailCard(id: contactItem.id, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        let url = URL(string: "https://www.proton.me")!

        await sut.handle(action: .onLoad)
        await sut.handle(action: .openURL(urlString: url.absoluteString))

        XCTAssertEqual(urlOpener.callAsFunctionInvokedWithURL, [url])
    }

    func testShareContactAction_ItPresentsComingSoon() async {
        let details = ContactDetailCard(id: contactItem.id, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        await sut.handle(action: .onLoad)
        await sut.handle(action: .shareContact)

        XCTAssertEqual(toastStateStore.state.toasts, [.comingSoon])
        XCTAssertEqual(toastStateStore.state.toastHeights, [:])
    }
}

private class ContactDetailsProviderSpy {
    var stubbedContactDetails: [ContactItem: ContactDetails] = [:]

    var contactDetailsCalls: [ContactItem] = []
}

private extension Array where Element == ContactField {

    static var testItems: [ContactField] {
        [
            .emails([
                .init(name: "Work", email: "elena.erickson@example.com")
            ]),
            .telephones([
                .init(number: "+41771234567", telTypes: [.home])
            ]),
            .anniversary(.string("Feb 28, 2019")),
            .gender(.male),
            .languages(["english", "german"]),
        ]
    }

}
