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

@testable import ProtonMail
import XCTest

final class DeviceContactsToImportTests: XCTestCase {
    let dummyDeviceIdentifier1 = DeviceContactIdentifier(uuidInDevice: "1", emails: ["1@1.com"])
    let dummyDeviceIdentifier2 = DeviceContactIdentifier(uuidInDevice: "2", emails: ["2@2.com"])
    let dummyDeviceIdentifier3 = DeviceContactIdentifier(uuidInDevice: "3", emails: ["3@3.com"])
    let dummyDeviceIdentifier4 = DeviceContactIdentifier(uuidInDevice: "4", emails: ["4@4.com"])

    func testCapNumberOfContactsIfNeeded_whenNoCapNeeded() {
        let contactsToImport = ImportDeviceContacts.DeviceContactsToImport(
            toCreate: [dummyDeviceIdentifier1],
            toUpdateByUuidMatch: [dummyDeviceIdentifier2],
            toUpdateByEmailMatch: [dummyDeviceIdentifier3]
        )

        let cappedContacts = contactsToImport.capNumberOfContactsIfNeeded(maxAllowed: 3)

        XCTAssertEqual(cappedContacts.toCreate.count, 1)
        XCTAssertEqual(cappedContacts.toUpdateByUuidMatch.count, 1)
        XCTAssertEqual(cappedContacts.toUpdateByEmailMatch.count, 1)
    }

    func testCapNumberOfContactsIfNeeded_whenCapNeeded_itCapsContactsToCreateFirst() {
        let contactsToImport = ImportDeviceContacts.DeviceContactsToImport(
            toCreate: [dummyDeviceIdentifier1, dummyDeviceIdentifier2],
            toUpdateByUuidMatch: [dummyDeviceIdentifier3],
            toUpdateByEmailMatch: [dummyDeviceIdentifier4]
        )

        let cappedContacts = contactsToImport.capNumberOfContactsIfNeeded(maxAllowed: 3)

        XCTAssertEqual(cappedContacts.toCreate.count, 1)
        XCTAssertEqual(cappedContacts.toUpdateByUuidMatch.count, 1)
        XCTAssertEqual(cappedContacts.toUpdateByEmailMatch.count, 1)
    }

    func testCapNumberOfContactsIfNeeded_whenCapNeeded_andOnlyToCreate_itCapsThem() {
        let contactsToImport = ImportDeviceContacts.DeviceContactsToImport(
            toCreate: [dummyDeviceIdentifier1, dummyDeviceIdentifier2],
            toUpdateByUuidMatch: [],
            toUpdateByEmailMatch: []
        )

        let cappedContacts = contactsToImport.capNumberOfContactsIfNeeded(maxAllowed: 1)

        XCTAssertEqual(cappedContacts.toCreate.count, 1)
        XCTAssertEqual(cappedContacts.toUpdateByUuidMatch.count, 0)
        XCTAssertEqual(cappedContacts.toUpdateByEmailMatch.count, 0)
    }

    func testCapNumberOfContactsIfNeeded_whenCapNeeded_andOnlyUpdates_itCapsMatchByEmailFirst() {
        let contactsToImport = ImportDeviceContacts.DeviceContactsToImport(
            toCreate: [],
            toUpdateByUuidMatch: [dummyDeviceIdentifier1, dummyDeviceIdentifier2],
            toUpdateByEmailMatch: [dummyDeviceIdentifier3, dummyDeviceIdentifier4]
        )

        let cappedContacts = contactsToImport.capNumberOfContactsIfNeeded(maxAllowed: 3)

        XCTAssertEqual(cappedContacts.toCreate.count, 0)
        XCTAssertEqual(cappedContacts.toUpdateByUuidMatch.count, 2)
        XCTAssertEqual(cappedContacts.toUpdateByEmailMatch.count, 1)
    }

    func testCapNumberOfContactsIfNeeded_whenCapNeeded_andOnlyMatchByEmail_itCapsThem() {
        let contactsToImport = ImportDeviceContacts.DeviceContactsToImport(
            toCreate: [],
            toUpdateByUuidMatch: [],
            toUpdateByEmailMatch: [dummyDeviceIdentifier1, dummyDeviceIdentifier2]
        )

        let cappedContacts = contactsToImport.capNumberOfContactsIfNeeded(maxAllowed: 1)

        XCTAssertEqual(cappedContacts.toCreate.count, 0)
        XCTAssertEqual(cappedContacts.toUpdateByUuidMatch.count, 0)
        XCTAssertEqual(cappedContacts.toUpdateByEmailMatch.count, 1)
    }
}
