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
    private var allContactsCalls: [AllContactsParameters] = []
    
    override func setUp() {
        super.setUp()
        stubbedAllContacts = []
        contactStoreSpy = .init()
        sut = .init(
            permissionsHandler: CNContactStoreSpy.self,
            contactStore: contactStoreSpy,
            allContactsProvider: .init(contactSuggestions: { query, contacts, _ in
                let parameters = AllContactsParameters(query: query, deviceContacts: contacts)
                self.allContactsCalls.append(parameters)
                return .ok(self.stubbedAllContacts)
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
    
    func testAllContacts_WhenPermissionsDenied_ItDoesNotRequestForDeviceContacts() throws {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .denied]
        
        sut.allContacts(query: .empty, completion: { _ in })
        
        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.count, 0)
    }
    
    func testAllContacts_WhenPermissionsRestricted_ItDoesNotRequestForDeviceContacts() throws {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .restricted]
        
        sut.allContacts(query: .empty, completion: { _ in })
        
        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.count, 0)
    }
    
    // MARK: - Permissions granted
    
    func testAllContacts_WhenPermissionsGranted_ItRequestForDeviceContacts() throws {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .authorized]
        
        sut.allContacts(query: .empty, completion: { _ in })
        
        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.count, 1)
        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.last?.keysToFetch.count, 2)
        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.last?.keysToFetch.map(\.description), [
            CNContactGivenNameKey.description,
            CNContactEmailAddressesKey.description
        ])
    }
    
    func testAllContacts_WhenPermissionsGranted_ItRequestsForAllContactsWithDeviceContacts() throws {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .authorized]
        
        contactStoreSpy.stubbedEnumerateContacts = [
            .jonathanHorotvitz,
            .travisHulkenberg
        ]
        
        sut.allContacts(query: .empty, completion: { _ in })
        
        XCTAssertEqual(allContactsCalls.count, 1)
        XCTAssertEqual(allContactsCalls.last, .init(
            query: "",
            deviceContacts: [
                .init(
                    key: "E121E1F8-C36C-495A-93FC-0C247A3E6E5F",
                    name: "Jonathan Horovitz",
                    emails: ["jonathan@pm.me", "jonathan@gmail.com"]
                ),
                .init(
                    key: "E221E1F8-C36C-495A-93FC-0C247A3E6E5F",
                    name: "Travis Hulkenberg",
                    emails: ["travis@pm.me", "travis@gmail.com"]
                )
            ]
        ))
    }
    
    func testAllContacts_WhenPermissionsGranted_ItReturnsDeviceAndProtonContacts() throws {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .authorized]
        
        contactStoreSpy.stubbedEnumerateContacts = [
            .jonathanHorotvitz,
            .travisHulkenberg
        ]
        
        stubbedAllContacts = [
            .group(.businessGroup),
            .protonJohn,
            .protonMark,
            .deviceJonathanHorotvitz,
            .deviceTravisHulkenberg
        ]
        
        var receivedContacts: [ContactSuggestion] = []
        
        sut.allContacts(query: .empty, completion: { contacts in
            receivedContacts = contacts
        })
        
        XCTAssertEqual(receivedContacts.count, 5)
        XCTAssertEqual(receivedContacts, [
            .group(.businessGroup),
            .protonJohn,
            .protonMark,
            .deviceJonathanHorotvitz,
            .deviceTravisHulkenberg
        ])
    }
    
    // MARK: - Permissions not granted
    
    func testAllContacts_WhenPermissionsNotGranted_ItDoesNotRequestForDeviceContacts() throws {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .denied]
        
        sut.allContacts(query: .empty, completion: { _ in })
        
        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.count, 0)
    }
    
    func testAllContacts_WhenPermissionsNotGranted_ItRequestForAllContactsWithoutDeviceContacts() throws {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .denied]
        
        contactStoreSpy.stubbedEnumerateContacts = [
            .jonathanHorotvitz,
            .travisHulkenberg
        ]
        
        sut.allContacts(query: "Ab", completion: { _ in })
        
        stubbedAllContacts = [
            .group(.businessGroup),
            .protonJohn,
            .protonMark,
            .deviceJonathanHorotvitz,
            .deviceTravisHulkenberg
        ]
        
        XCTAssertEqual(allContactsCalls.count, 1)
        XCTAssertEqual(allContactsCalls.last, AllContactsParameters(query: "Ab", deviceContacts: []))
    }
    
    func testAllContacts_WhenPermissionsNotGranted_ItReturnsProtonContactsOnly() throws {
        CNContactStoreSpy.stubbedAuthorizationStatus = [.contacts: .denied]
        
        contactStoreSpy.stubbedEnumerateContacts = [
            .jonathanHorotvitz,
            .travisHulkenberg
        ]
        
        stubbedAllContacts = [
            .protonJohn,
            .protonMark
        ]
        
        var receivedContacts: [ContactSuggestion] = []
        
        sut.allContacts(query: .empty, completion: { contacts in
            receivedContacts = contacts
        })
        
        XCTAssertEqual(receivedContacts.count, 2)
        XCTAssertEqual(receivedContacts, [
            .protonJohn,
            .protonMark
        ])
    }
    
}

private struct AllContactsParameters: Equatable {
    let query: String
    let deviceContacts: [DeviceContact]
}

private class CNContactSpy: CNContact {
    let _id: UUID
    let _givenName: String
    let _emailAddresses: [String]
    
    init(id: UUID, givenName: String, emails: [String]) {
        _id = id
        _givenName = givenName
        _emailAddresses = emails
        super.init()
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override var id: UUID {
        _id
    }
    
    override var givenName: String {
        _givenName
    }
    
    override var emailAddresses: [CNLabeledValue<NSString>] {
        _emailAddresses.map { email in
            CNLabeledValue(label: email, value: email as NSString)
        }
    }
}

private extension UUID {
    
    static func testData(id: Int) -> UUID {
        .init(uuidString: "E\(id)21E1F8-C36C-495A-93FC-0C247A3E6E5F").unsafelyUnwrapped
    }
    
}

private extension CNContact {
    
    static var jonathanHorotvitz: CNContact {
        CNContactSpy(
            id: .testData(id: 1),
            givenName: "Jonathan Horovitz",
            emails: ["jonathan@pm.me", "jonathan@gmail.com"]
        )
    }
    
    static var travisHulkenberg: CNContact {
        CNContactSpy(
            id: .testData(id: 2),
            givenName: "Travis Hulkenberg",
            emails: ["travis@pm.me", "travis@gmail.com"]
        )
    }
    
}

private extension ContactSuggestion {

    static func group(_ groupItem: ContactGroupItem) -> Self {
        .init(
            key: "\(groupItem.id.value)",
            name: groupItem.name,
            avatarInformation: .init(text: "", color: groupItem.avatarColor),
            kind: .contactGroup(groupItem.contacts.flatMap(\.emails))
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
    
    // MARK: - Private
    
    private static func proton(_ emailItem: ContactEmailItem, _ initials: String) -> Self {
        .init(
            key: "\(emailItem.id.value)",
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
            key: contact.id.uuidString,
            name: contact.givenName,
            avatarInformation: avatarInformation,
            kind: .deviceContact(.init(email: email))
        )
    }
    
}
