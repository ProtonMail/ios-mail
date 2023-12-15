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
import ProtonCoreDataModel
import ProtonCoreCrypto
@testable import ProtonMail

final class DeviceContactParserTests: XCTestCase {
    private var sut = DeviceContactParser.self
    private let userKey = Key(keyID: "", privateKey: KeyTestData.privateKey1)
    private let passphrase = KeyTestData.passphrash1

    func testParseDeviceContact_whenThereAreEmails_itShouldParseEmailsAndTypesCorrectly() throws {
        let result = try sut.parseDeviceContact(deviceContactWithEmails, userKey: userKey, userPassphrase: passphrase)
        XCTAssertEqual(result.emails.map(\.address), ["John-Appleseed@mac.com", "john.as@example.com"])
        XCTAssertEqual(
            result.emails.map(\.type.rawString),
            [ContactFieldType.work.rawString, ContactFieldType.internet.rawString]
        )
    }

    func testParseDeviceContact_whenNoEmails_itShouldReturnNoEmails() throws {
        let result = try sut.parseDeviceContact(deviceContactWithoutEmails, userKey: userKey, userPassphrase: passphrase)
        XCTAssertEqual(result.emails.map(\.address), [])
    }

    func testParseDeviceContact_itShouldParseCardDataCorrectly() throws {
        let result = try sut.parseDeviceContact(deviceContactWithEmails, userKey: userKey, userPassphrase: passphrase)

        XCTAssertEqual(result.cards.count, 2)
        XCTAssertEqual(result.cards[0].type, .SignedOnly)
        XCTAssertEqual(result.cards[1].type, .SignAndEncrypt)
    }
}

extension DeviceContactParserTests {
    private var testCardWithEmails: String {
    """
    BEGIN:VCARD\r\nVERSION:3.0\r\nPRODID:-//Apple Inc.//iPhone OS 17.0//EN\r\nN:Appleseed;John;;;\r\nFN:John Appleseed\r\nEMAIL;type=WORK;type=pref:John-Appleseed@mac.com\r\nEMAIL;type=INTERNET;type=HOME:john.as@example.com\r\nTEL;type=CELL;type=VOICE;type=pref:888-555-5512\r\nTEL;type=HOME;type=VOICE:5551212888\r\nitem1.ADR;type=WORK;type=pref:;;3494 Kuhl Avenue;Atlanta;GA;30303;USA\r\nitem1.X-ABADR:us\r\nitem2.ADR;type=HOME:;;1234 Laurel Street;Atlanta;GA;30303;USA\r\nitem2.X-ABADR:us\r\nBDAY:1980-06-22\r\nEND:VCARD\r\n
    """
    }
    private var testCardWithoutEmails: String {
    """
    BEGIN:VCARD\r\nVERSION:3.0\r\nPRODID:-//Apple Inc.//iPhone OS 17.0//EN\r\nN:Taylor;David;;;\r\nFN:David Taylor\r\nTEL;type=HOME;type=VOICE;type=pref:555-610-6679\r\nitem1.ADR;type=HOME;type=pref:;;1747 Steuart Street;Tiburon;CA;94920;USA\r\nitem1.X-ABADR:us\r\nBDAY:1998-06-15\r\nEND:VCARD\r\n
    """
    }
    private var deviceContactWithEmails: DeviceContact {
        DeviceContact(
            identifier: .init(uuidInDevice: "uuid-1", emails: ["irrelevant"]),
            fullName: "irrelevant",
            vCard: testCardWithEmails
        )
    }
    private var deviceContactWithoutEmails: DeviceContact {
        DeviceContact(
            identifier: .init(uuidInDevice: "uuid-1", emails: ["irrelevant"]),
            fullName: "irrelevant",
            vCard: testCardWithoutEmails
        )
    }
}
