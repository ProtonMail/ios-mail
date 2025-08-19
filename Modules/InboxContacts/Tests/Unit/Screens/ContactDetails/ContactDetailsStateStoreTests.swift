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
import Foundation
import InboxCoreUI
import InboxTesting
import proton_app_uniffi
import Testing

@MainActor
final class ContactDetailsStateStoreTests {
    private var sut: ContactDetailsStateStore!
    private var initialState: ContactDetails!
    private var contactItem: ContactsRoute.ContactContext!
    private var providerSpy: ContactDetailsProviderSpy!
    private var urlOpener: EnvironmentURLOpenerSpy!
    private var draftPresenterSpy: ContactsDraftPresenterSpy!
    private var toastStateStore: ToastStateStore!

    init() {
        contactItem = .init(ContactItem.elenaErickson)
        initialState = .init(contact: contactItem, details: .none)
        providerSpy = .init()
        urlOpener = .init()
        draftPresenterSpy = .init()
        toastStateStore = .init(initialState: .initial)

        sut = ContactDetailsStateStore(
            state: initialState,
            item: contactItem,
            provider: .init(contactDetails: { [unowned self] contact in
                providerSpy.contactDetailsCalls.append(.init(contact))
                return providerSpy.stubbedContactDetails[.init(contact)]!
            }),
            urlOpener: urlOpener,
            draftPresenter: draftPresenterSpy,
            toastStateStore: toastStateStore
        )
    }

    @Test
    func testInitialState_isSetCorrectly() {
        #expect(sut.state == initialState)
    }

    @Test
    func testOnLoadAction_ItFetchesDetailsAndUpdatesState() async {
        let details = ContactDetailCard.testData(contact: contactItem, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        await sut.handle(action: .onLoad)

        #expect(sut.state == .init(contact: contactItem, details: details))
    }

    @Test
    func testCallTappedAction_ItOpensURLWithTelPrefix() async {
        let details = ContactDetailCard.testData(contact: contactItem, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        let phoneNumber = "+41771234567"

        await sut.handle(action: .onLoad)
        await sut.handle(action: .callTapped)

        #expect(urlOpener.callAsFunctionInvokedWithURL.map(\.absoluteString) == ["tel:\(phoneNumber)"])
    }

    @Test
    func testPhoneNumberTappedAction_ItOpensURLWithTelPrefix() async {
        let details = ContactDetailCard.testData(contact: contactItem, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        let phoneNumber = "+44883334477"

        await sut.handle(action: .onLoad)
        await sut.handle(action: .phoneNumberTapped(phoneNumber))

        #expect(urlOpener.callAsFunctionInvokedWithURL.map(\.absoluteString) == ["tel:\(phoneNumber)"])
    }

    @Test
    func testOpenURLAction_ItOpensURL() async {
        let details = ContactDetailCard.testData(contact: contactItem, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        let url = URL(string: "https://www.proton.me")!

        await sut.handle(action: .onLoad)
        await sut.handle(action: .openURL(urlString: url.absoluteString))

        #expect(urlOpener.callAsFunctionInvokedWithURL == [url])
    }

    @Test
    func testOpenURLActionWithURLMissingScheme_ItNormalizesAndOpensURL() async {
        let details = ContactDetailCard.testData(contact: contactItem, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        let url = URL(string: "proton.me")!

        await sut.handle(action: .onLoad)
        await sut.handle(action: .openURL(urlString: url.absoluteString))

        #expect(urlOpener.callAsFunctionInvokedWithURL == [URL(string: "https://proton.me")!])
    }

    @Test
    func testShareTappedAction_ItPresentsComingSoon() async {
        let details = ContactDetailCard.testData(contact: contactItem, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        await sut.handle(action: .onLoad)
        await sut.handle(action: .shareTapped)

        #expect(toastStateStore.state.toasts == [.comingSoon])
        #expect(toastStateStore.state.toastHeights == [:])
    }

    @Test
    func testNewMessageTappedAction_ItPresentsDraftWithPrimaryContact() async {
        let details = ContactDetailCard.testData(contact: contactItem, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        await sut.handle(action: .onLoad)
        await sut.handle(action: .newMessageTapped)

        #expect(draftPresenterSpy.openDraftContactCalls.count == 1)
        #expect(
            draftPresenterSpy.openDraftContactCalls == [
                .init(name: "🌟 Elena Erickson", email: "elena.erickson@protonmail.com")
            ])
    }

    @Test
    func testEmailTappedAction_ItPresentsDraftWithGivenContact() async {
        let details = ContactDetailCard.testData(contact: contactItem, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        let stubbedEmail = ContactDetailsEmail(emailType: [.home], email: "elena@pm.me")

        await sut.handle(action: .onLoad)
        await sut.handle(action: .emailTapped(stubbedEmail))

        #expect(draftPresenterSpy.openDraftContactCalls.count == 1)
        #expect(draftPresenterSpy.openDraftContactCalls == [.init(name: contactItem.name, email: stubbedEmail.email)])
    }

    @Test
    func testEmailTappedAction_AndOpeningDraftFails_ItPresentsToastWithError() async {
        let expectedError: TestError = .test
        let details = ContactDetailCard.testData(contact: contactItem, fields: .testItems)

        providerSpy.stubbedContactDetails[contactItem] = .init(
            contact: contactItem,
            details: details
        )

        draftPresenterSpy.stubbedOpenDraftContactError = expectedError

        let stubbedEmail = ContactDetailsEmail(emailType: [.work], email: "elena.erickson@protonmail.com")

        await sut.handle(action: .onLoad)
        await sut.handle(action: .emailTapped(stubbedEmail))

        #expect(draftPresenterSpy.openDraftContactCalls.count == 1)
        #expect(draftPresenterSpy.openDraftContactCalls == [.init(name: contactItem.name, email: stubbedEmail.email)])
        #expect(toastStateStore.state.toasts == [.error(message: expectedError.localizedDescription)])
    }
}

private class ContactDetailsProviderSpy {
    var stubbedContactDetails: [ContactsRoute.ContactContext: ContactDetails] = [:]

    var contactDetailsCalls: [ContactsRoute.ContactContext] = []
}

private extension Array where Element == ContactField {

    static var testItems: [ContactField] {
        [
            .emails([
                .init(emailType: [.work], email: "elena.erickson@protonmail.com"),
                .init(emailType: [.home], email: "elena@pm.me"),
            ]),
            .telephones([
                .init(number: "+41771234567", telTypes: [.home]),
                .init(number: "+44883334477", telTypes: [.work]),
            ]),
            .anniversary(.string("Feb 28, 2019")),
            .gender(.male),
            .languages(["english", "german"]),
        ]
    }

}
