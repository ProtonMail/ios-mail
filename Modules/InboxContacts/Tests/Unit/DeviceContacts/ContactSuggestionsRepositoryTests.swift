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
import Contacts
import InboxTesting
import proton_app_uniffi
import XCTest

final class ContactSuggestionsRepositoryTests: BaseTestCase {

    var sut: ContactSuggestionsRepository!
    var stubbedAllContacts: [ContactSuggestion]!

    private var contactStoreSpy: CNContactStoreSpy!
    private var allContactsCalls: [[DeviceContact]] = []

    override func setUp() {
        super.setUp()
        stubbedAllContacts = []
        contactStoreSpy = .init()
        sut = .init(
            permissionsHandler: CNContactStoreSpy.self,
            contactStore: contactStoreSpy,
            allContactsProvider: .init(contactSuggestions: { contacts, _ in
                self.allContactsCalls.append(contacts)
                let result = ContactSuggestionsStub(all: self.stubbedAllContacts)
                return .ok(result)
            }),
            mailUserSession: MailUserSession(noPointer: .init())
        )
    }

    override func tearDown() {
        allContactsCalls = []
        contactStoreSpy = nil
        stubbedAllContacts = nil
        sut = nil
        CNContactStoreSpy.cleanUp()
        super.tearDown()
    }

    func testAllContacts_WhenPermissionsDenied_ItDoesNotRequestForDeviceContacts() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .denied]

        _ = await sut.allContacts()

        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.count, 0)
    }

    func testAllContacts_WhenPermissionsRestricted_ItDoesNotRequestForDeviceContacts() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .restricted]

        _ = await sut.allContacts()

        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.count, 0)
    }

    // MARK: - Permissions granted

    func testAllContacts_WhenPermissionsGranted_ItRequestForDeviceContacts() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .authorized]

        _ = await sut.allContacts()

        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.count, 1)
        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.last?.keysToFetch.count, 3)
        XCTAssertEqual(
            contactStoreSpy.enumerateContactsCalls.last?.keysToFetch.map(\.description),
            [
                CNContactGivenNameKey.description,
                CNContactFamilyNameKey.description,
                CNContactEmailAddressesKey.description,
            ])
    }

    func testAllContacts_WhenPermissionsGranted_ItRequestsForAllContactsWithDeviceContacts() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .authorized]

        contactStoreSpy.stubbedEnumerateContacts = [
            .jonathanHorotvitz,
            .travisHulkenberg,
        ]

        _ = await sut.allContacts()

        XCTAssertEqual(allContactsCalls.count, 1)
        XCTAssertEqual(
            allContactsCalls.last,
            [
                .init(
                    key: "1",
                    name: "Jonathan Horovitz",
                    emails: ["jonathan@pm.me", "jonathan@gmail.com"]
                ),
                .init(
                    key: "2",
                    name: "Travis Hulkenberg",
                    emails: ["travis@pm.me", "travis@gmail.com"]
                ),
            ])
    }

    func testAllContacts_WhenPermissionsGranted_ItReturnsDeviceAndProtonContacts() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .authorized]

        contactStoreSpy.stubbedEnumerateContacts = [
            .jonathanHorotvitz,
            .travisHulkenberg,
            .marcus,
        ]

        stubbedAllContacts = [
            .group(.businessGroup),
            .protonJohn,
            .protonMark,
            .deviceJonathanHorotvitz,
            .deviceTravisHulkenberg,
            .deviceMarcus,
        ]

        let receivedContacts = await sut.allContacts()?.all() ?? []

        XCTAssertEqual(receivedContacts.count, 6)
        XCTAssertEqual(
            receivedContacts,
            [
                .group(.businessGroup),
                .protonJohn,
                .protonMark,
                .deviceJonathanHorotvitz,
                .deviceTravisHulkenberg,
                .deviceMarcus,
            ])
    }

    // MARK: - Permissions not granted

    func testAllContacts_WhenPermissionsNotGranted_ItDoesNotRequestForDeviceContacts() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .denied]

        _ = await sut.allContacts()

        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.count, 0)
    }

    func testAllContacts_WhenPermissionsNotGranted_ItRequestForAllContactsWithoutDeviceContacts() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .denied]

        contactStoreSpy.stubbedEnumerateContacts = [
            .jonathanHorotvitz,
            .travisHulkenberg,
        ]

        _ = await sut.allContacts()

        stubbedAllContacts = [
            .group(.businessGroup),
            .protonJohn,
            .protonMark,
            .deviceJonathanHorotvitz,
            .deviceTravisHulkenberg,
        ]

        XCTAssertEqual(allContactsCalls.count, 1)
        XCTAssertEqual(allContactsCalls.last, [])
    }

    func testAllContacts_WhenPermissionsNotGranted_ItReturnsProtonContactsOnly() async {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .denied]

        contactStoreSpy.stubbedEnumerateContacts = [
            .jonathanHorotvitz,
            .travisHulkenberg,
        ]

        stubbedAllContacts = [
            .protonJohn,
            .protonMark,
        ]

        let receivedContacts = await sut.allContacts()?.all() ?? []

        XCTAssertEqual(receivedContacts.count, 2)
        XCTAssertEqual(
            receivedContacts,
            [
                .protonJohn,
                .protonMark,
            ])
    }

}

private class CNContactSpy: CNContact {
    let _id: String
    let _givenName: String
    let _familyName: String
    let _emailAddresses: [String]

    init(id: String, givenName: String, familyName: String, emails: [String]) {
        _id = id
        _givenName = givenName
        _familyName = familyName
        _emailAddresses = emails
        super.init()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var identifier: String {
        _id
    }

    override var givenName: String {
        _givenName
    }

    override var familyName: String {
        _familyName
    }

    override var emailAddresses: [CNLabeledValue<NSString>] {
        _emailAddresses.map { email in
            CNLabeledValue(label: email, value: email as NSString)
        }
    }
}

private extension CNContact {

    static var jonathanHorotvitz: CNContact {
        CNContactSpy(
            id: "1",
            givenName: "Jonathan",
            familyName: "Horovitz",
            emails: ["jonathan@pm.me", "jonathan@gmail.com"]
        )
    }

    static var travisHulkenberg: CNContact {
        CNContactSpy(
            id: "2",
            givenName: "Travis",
            familyName: "Hulkenberg",
            emails: ["travis@pm.me", "travis@gmail.com"]
        )
    }

    static var marcus: CNContact {
        CNContactSpy(
            id: "3",
            givenName: "Marcus",
            familyName: "",
            emails: ["marcus@pm.me"]
        )
    }

}

private extension ContactSuggestion {

    static func group(_ groupItem: ContactGroupItem) -> Self {
        .init(
            key: "\(groupItem.id.value)",
            name: groupItem.name,
            avatarInformation: .init(text: "", color: groupItem.avatarColor),
            kind: .contactGroup(groupItem.contactEmails)
        )
    }

    static var protonJohn: Self {
        .proton(.init(id: 1, email: "john@pm.me"), "JD")
    }

    static var protonMark: Self {
        .proton(.init(id: 2, email: "mark@pm.me"), "MW")
    }

    static var deviceJonathanHorotvitz: Self {
        device(from: .jonathanHorotvitz, with: .init(text: "JH", color: "#FF5733"))
    }

    static var deviceTravisHulkenberg: Self {
        device(from: .travisHulkenberg, with: .init(text: "TH", color: "#A1FF33"))
    }

    static var deviceMarcus: Self {
        device(from: .marcus, with: .init(text: "M", color: "#FF5755"))
    }

    // MARK: - Private

    private static func proton(_ emailItem: ContactEmailItem, _ initials: String) -> Self {
        .init(
            key: "\(emailItem.contactId.value)",
            name: "name_\(emailItem.email)",
            avatarInformation: .init(text: initials, color: "#A1FF33"),
            kind: .contactItem(emailItem)
        )
    }

    private static func device(
        from contact: CNContact,
        with avatarInformation: AvatarInformation
    ) -> Self {
        let email: String = contact.emailAddresses.first!.label!

        return .init(
            key: contact.identifier,
            name: [contact.givenName, contact.familyName].joined(separator: " "),
            avatarInformation: avatarInformation,
            kind: .deviceContact(.init(email: email))
        )
    }

}

private class ContactSuggestionsStub: ContactSuggestions {

    private let _all: [ContactSuggestion]

    init(all: [ContactSuggestion]) {
        _all = all
        super.init(noPointer: .init())
    }

    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    override func all() -> [ContactSuggestion] {
        _all
    }

    override func filtered(query: String) -> [ContactSuggestion] {
        return []
    }

}
