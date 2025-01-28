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

final class SuggestionContactsRepositoryTests: BaseTestCase {
    
    var sut: SuggestionContactsRepository!
    var stubbedAllContacts: [ContactType]!
    
    private var contactStoreSpy: CNContactStoreSpy!
    private(set) var allContactsCallsWithDeviceContacts: [[PlatformDeviceContact]] = []
    
    override func setUp() {
        super.setUp()
        stubbedAllContacts = []
        contactStoreSpy = .init()
        sut = .init(
            contactStore: contactStoreSpy,
            allContactsProvider: .init(allContacts: { _, contacts in
                self.allContactsCallsWithDeviceContacts.append(contacts)
                return .ok(self.stubbedAllContacts)
            }),
            mailUserSession: MailUserSession(noPointer: .init())
        )
    }
    
    override func tearDown() {
        allContactsCallsWithDeviceContacts = []
        contactStoreSpy = nil
        stubbedAllContacts = nil
        sut = nil
        super.tearDown()
    }
    
    func testAllContacts_ItRequestForPermissions() {
        sut.allContacts(completion: { _ in })
        
        XCTAssertEqual(contactStoreSpy.requestAccessCalls.count, 1)
        XCTAssertEqual(contactStoreSpy.requestAccessCalls.last?.entityType, .contacts)
    }
    
    // MARK: - Permissions granted
    
    func testAllContacts_WhenPermissionsGranted_ItRequestForDeviceContacts() throws {
        sut.allContacts(completion: { _ in })
        
        let parameters = try XCTUnwrap(contactStoreSpy.requestAccessCalls.last)
        parameters.completionHandler(true, nil)
        
        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.count, 1)
        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.last?.keysToFetch.count, 2)
        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.last?.keysToFetch.map(\.description), [
            CNContactGivenNameKey.description,
            CNContactEmailAddressesKey.description
        ])
    }
    
    func testAllContacts_WhenPermissionsAreGranted_ItRequestsForAllContactsWithDeviceContacts() throws {
        contactStoreSpy.stubbedEnumerateContacts = [
            .jonathanHorotvitz,
            .travisHulkenberg
        ]
        
        sut.allContacts(completion: { _ in })
        
        let parameters = try XCTUnwrap(contactStoreSpy.requestAccessCalls.last)
        parameters.completionHandler(true, nil)
        
        XCTAssertEqual(allContactsCallsWithDeviceContacts.count, 1)
        XCTAssertEqual(allContactsCallsWithDeviceContacts.last, [
            .init(
                id: "E121E1F8-C36C-495A-93FC-0C247A3E6E5F",
                name: "Jonathan Horovitz",
                emails: ["jonathan@pm.me", "jonathan@gmail.com"]
            ),
            .init(
                id: "E221E1F8-C36C-495A-93FC-0C247A3E6E5F",
                name: "Travis Hulkenberg",
                emails: ["travis@pm.me", "travis@gmail.com"]
            )
        ])
    }
    
    func testAllContacts_WhenPermissionsAreGranted_ItReturnsDeviceAndProtonContacts() throws {
        contactStoreSpy.stubbedEnumerateContacts = [
            .jonathanHorotvitz,
            .travisHulkenberg
        ]
        
        var receivedContacts: [ContactType] = []
        
        sut.allContacts(completion: { contacts in
            receivedContacts = contacts
        })
        
        stubbedAllContacts = [
            .group(.businessGroup),
            .proton(.init(id: 1, email: "john@pm.me")),
            .proton(.init(id: 2, email: "mark@pm.me")),
            .device(.jonathanHorotvitz),
            .device(.travisHulkenberg)
        ]
        
        let parameters = try XCTUnwrap(contactStoreSpy.requestAccessCalls.last)
        parameters.completionHandler(true, nil)
        
        XCTAssertEqual(receivedContacts.count, 5)
        XCTAssertEqual(receivedContacts, [
            .group(.businessGroup),
            .proton(.init(id: 1, email: "john@pm.me")),
            .proton(.init(id: 2, email: "mark@pm.me")),
            .device(.jonathanHorotvitz),
            .device(.travisHulkenberg)
        ])
    }
    
    // MARK: - Permissions not granted
    
    func testAllContacts_WhenPermissionsNotGranted_ItDoesNotRequestForDeviceContacts() throws {
        sut.allContacts(completion: { _ in })
        
        let parameters = try XCTUnwrap(contactStoreSpy.requestAccessCalls.last)
        parameters.completionHandler(false, nil)
        
        XCTAssertEqual(contactStoreSpy.enumerateContactsCalls.count, 0)
    }
    
    func testAllContacts_WhenPermissionsNotGranted_ItRequestForAllContactsWithoutDeviceContacts() throws {
        contactStoreSpy.stubbedEnumerateContacts = [
            .jonathanHorotvitz,
            .travisHulkenberg
        ]
        
        sut.allContacts(completion: { _ in })
        
        stubbedAllContacts = [
            .group(.businessGroup),
            .proton(.init(id: 1, email: "john@pm.me")),
            .proton(.init(id: 2, email: "mark@pm.me")),
            .device(.jonathanHorotvitz),
            .device(.travisHulkenberg)
        ]
        
        let parameters = try XCTUnwrap(contactStoreSpy.requestAccessCalls.last)
        parameters.completionHandler(false, nil)
        
        XCTAssertEqual(allContactsCallsWithDeviceContacts.count, 1)
        XCTAssertEqual(allContactsCallsWithDeviceContacts.last, [])
    }
    
    func testAllContacts_WhenPermissionsNotGranted_ItReturnsProtonContactsOnly() throws {
        contactStoreSpy.stubbedEnumerateContacts = [
            .jonathanHorotvitz,
            .travisHulkenberg
        ]
        
        var receivedContacts: [ContactType] = []
        
        sut.allContacts(completion: { contacts in
            receivedContacts = contacts
        })
        
        stubbedAllContacts = [
            .proton(.init(id: 1, email: "john@pm.me")),
            .proton(.init(id: 2, email: "mark@pm.me"))
        ]
        
        let parameters = try XCTUnwrap(contactStoreSpy.requestAccessCalls.last)
        parameters.completionHandler(false, nil)
        
        XCTAssertEqual(receivedContacts.count, 2)
        XCTAssertEqual(receivedContacts, [
            .proton(.init(id: 1, email: "john@pm.me")),
            .proton(.init(id: 2, email: "mark@pm.me"))
        ])
    }
    
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

private extension DeviceContact {
    
    static var jonathanHorotvitz: Self {
        testData(from: .jonathanHorotvitz, with: .init(text: "JH", color: "#FF5733"))
    }
    
    static var travisHulkenberg: Self {
        testData(from: .travisHulkenberg, with: .init(text: "TH", color: "#A1FF33"))
    }
    
    private static func testData(from contact: CNContact, with avatarInformation: AvatarInformation) -> Self {
        .init(
            id: contact.id.uuidString,
            name: contact.givenName,
            emails: contact.emailAddresses.compactMap(\.label),
            avatarInformation: avatarInformation
        )
    }

}
