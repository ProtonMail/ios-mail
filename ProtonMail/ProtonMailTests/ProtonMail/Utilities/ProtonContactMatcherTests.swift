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

import XCTest
import ProtonCoreCrypto
@testable import ProtonMail

final class ProtonContactMatcherTests: XCTestCase {
    private var sut: ProtonContactMatcher!
    private var mockContactProvider: MockContactProvider!

    override func setUp() {
        super.setUp()
        mockContactProvider = .init(coreDataContextProvider: MockCoreDataContextProvider())
        sut = ProtonContactMatcher(contactProvider: mockContactProvider)
    }

    override func tearDown() {
        super.tearDown()
        mockContactProvider = nil
        sut = nil
    }

    func testMatchProtonContacts_whenOnlyMatchByUUID_returnsOnlyTheMatchingOnes() {
        mockContactProvider.getContactsByUUIDStub.bodyIs { _, _ in
            [ContactEntity.make(uuid: "uuid-2")]
        }

        let identifiers = [DeviceContactIdentifier(uuid: "uuid-2", emails: [])]
        let result = sut.matchProtonContacts(with: identifiers)

        let expectedResult = ["uuid-2"]
        XCTAssertEqual(result.count, expectedResult.count)
        XCTAssertEqual(result.map(\.uuid), expectedResult)
    }

    func testMatchProtonContacts_whenOnlyMatchByUUID_itOnlyTriesToMatchByEmailTheOnesNotMatchedByUUID() {
        mockContactProvider.getContactsByUUIDStub.bodyIs { _, _ in
            [ContactEntity.make(uuid: "uuid-2")]
        }

        mockContactProvider.getEmailsByAddressStub.bodyIs { _, emails in
            XCTAssertEqual(emails, ["1a@example.com", "1b@example.com", "4a@example.com"])
            return []
        }

        let identifiers = [
            DeviceContactIdentifier(uuid: "uuid-1", emails: ["1a@example.com", "1b@example.com"]),
            DeviceContactIdentifier(uuid: "uuid-2", emails: ["2a@example.com"]),
            DeviceContactIdentifier(uuid: "uuid-3", emails: []),
            DeviceContactIdentifier(uuid: "uuid-4", emails: ["4a@example.com"])
        ]
        _ = sut.matchProtonContacts(with: identifiers)
    }

    func testMatchProtonContacts_whenOnlyMatchByEmail_returnsOnlyTheMatchingOnes() {
        mockContactProvider.getEmailsByAddressStub.bodyIs { _, emailsRequested in
            [EmailEntity.make(email:"1@example.com"), EmailEntity.make(email:"3@example.com")]
        }

        let identifiers = [
            DeviceContactIdentifier(uuid: "uuid-A", emails: ["1@example.com", "2@example.com"]),
            DeviceContactIdentifier(uuid: "uuid-B", emails: ["3@example.com"]),
            DeviceContactIdentifier(uuid: "uuid-C", emails: ["4@example.com", "5@example.com"])
        ]
        let result = sut.matchProtonContacts(with: identifiers)

        let expectedResult = ["uuid-A", "uuid-B"]
        XCTAssertEqual(result.count, expectedResult.count)
        XCTAssertEqual(result.map(\.uuid), expectedResult)
    }

    func testMatchProtonContacts_whenMatchAnyAttribute_returnsOnlyTheMatchingOnes() {
        mockContactProvider.getContactsByUUIDStub.bodyIs { _, _ in
            [ContactEntity.make(uuid: "uuid-A"), ContactEntity.make(uuid: "uuid-D")]
        }
        mockContactProvider.getEmailsByAddressStub.bodyIs { _, emailsRequested in
            XCTAssertEqual(emailsRequested, ["3@example.com", "4@example.com", "5@example.com"])
            return [EmailEntity.make(email:"3@example.com")]
        }

        let identifiers = [
            DeviceContactIdentifier(uuid: "uuid-A", emails: ["1@example.com", "2@example.com"]),
            DeviceContactIdentifier(uuid: "uuid-B", emails: ["3@example.com"]),
            DeviceContactIdentifier(uuid: "uuid-C", emails: ["4@example.com", "5@example.com"]),
            DeviceContactIdentifier(uuid: "uuid-D", emails: [])
        ]
        let result = sut.matchProtonContacts(with: identifiers)

        let expectedResult = ["uuid-A", "uuid-D", "uuid-B"]
        XCTAssertEqual(result.count, expectedResult.count)
        XCTAssertEqual(result.map(\.uuid), expectedResult)
    }

    func testMatchProtonContacts_whenNoMatches_returnsEmptyArray() {
        mockContactProvider.getContactsByUUIDStub.bodyIs { _, _ in [] }
        mockContactProvider.getEmailsByAddressStub.bodyIs { _, _ in [] }

        let identifiers = [
            DeviceContactIdentifier(uuid: "uuid-A", emails: ["1@example.com"]),
            DeviceContactIdentifier(uuid: "uuid-B", emails: ["3@example.com"]),
            DeviceContactIdentifier(uuid: "uuid-C", emails: ["5@example.com"]),
            DeviceContactIdentifier(uuid: "uuid-D", emails: [])
        ]
        let result = sut.matchProtonContacts(with: identifiers)

        let expectedResult: [DeviceContactIdentifier] = []
        XCTAssertEqual(result.count, expectedResult.count)
    }
}
