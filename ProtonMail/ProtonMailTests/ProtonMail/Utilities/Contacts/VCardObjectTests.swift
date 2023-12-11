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
@testable import ProtonMail
import VCard

final class VCardObjectTests: XCTestCase {
    private var sut: VCardObject!

    override func setUp() {
        super.setUp()
        sut = VCardObject(object: PMNIEzvcard.parseFirst(testVCard)!)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    // MARK: read methods

    func testName() {
        let expected = ContactField.Name(firstName: "Dirk", lastName: "Schröder")
        XCTAssertEqual(sut.name(), expected)
    }

    func testEmails() {
        let expected = [
            ContactField.Email(type: .home, emailAddress: "dirk@example.com", vCardGroup: "ITEM0"),
            ContactField.Email(type: .work, emailAddress: "schroder@proton.me", vCardGroup: "")
        ]
        XCTAssertEqual(sut.emails(), expected)
    }

    func testAddresses() {
        let expected = [
            ContactField.Address(
                type: .work,
                street: "1600 Pennsylania Avenue",
                streetTwo: "",
                locality: "Washington D.C",
                region: "",
                postalCode: "20500",
                country: "United States",
                poBox: ""
            )
        ]
        XCTAssertEqual(sut.addresses(), expected)
    }

    func testPhoneNumbers() {
        let expected = [
            ContactField.PhoneNumber(type: .custom("CELL"), number: "(911) 555-511"),
            ContactField.PhoneNumber(type: .home, number: "1 (234) 567-89")
        ]
        XCTAssertEqual(sut.phoneNumbers(), expected)
    }

    func testUrls() {
        let expected = [ContactField.Url(type: .home, url: "www.dirkschroder.com")]
        XCTAssertEqual(sut.urls(), expected)
    }

    func testOtherInfo_organization() {
        let expected = [ContactField.OtherInfo(type: .organization, value: "Proton A.G.")]
        XCTAssertEqual(sut.otherInfo(infoType: .organization), expected)
    }

    func testOtherInfo_birthday() {
        let expected = [ContactField.OtherInfo(type: .birthday, value: "2003-11-11")]
        XCTAssertEqual(sut.otherInfo(infoType: .birthday), expected)
    }

    func testOtherInfo_title() {
        let expected = [ContactField.OtherInfo(type: .title, value: "Portfolio Manager")]
        XCTAssertEqual(sut.otherInfo(infoType: .title), expected)
    }

    // MARK: write methods

    func testReplaceEmails_itShouldReplaceTheEmailInfo_andKeepVCardGroup() {
        // prerequisite: we check the value of the existing emails
        let emailsBefore = sut.emails()
        let expectedBefore = [
            ContactField.Email(type: .home, emailAddress: "dirk@example.com", vCardGroup: "ITEM0"),
            ContactField.Email(type: .work, emailAddress: "schroder@proton.me", vCardGroup: "")
        ]
        XCTAssertEqual(emailsBefore, expectedBefore)

        let first = emailsBefore.first!
        let updatedEmails = [
            ContactField.Email(type: .work, emailAddress: first.emailAddress, vCardGroup: first.vCardGroup)
        ]
        sut.replaceEmails(with: updatedEmails)

        let expectedAfter = [
            ContactField.Email(type: .work, emailAddress: "dirk@example.com", vCardGroup: "ITEM0")
        ]
        XCTAssertEqual(sut.emails(), expectedAfter)
    }
}

private extension VCardObjectTests {

    var testVCard: String {
        """
        BEGIN:VCARD
        VERSION:3.0
        PRODID:-//Apple Inc.//iPhone OS 17.0//EN
        N:Schröder;Dirk;;;
        FN:Dirk Schröder
        ORG:Proton A.G.;
        TITLE:Portfolio Manager
        ITEM0.EMAIL;type=HOME;type=pref:dirk@example.com
        EMAIL;type=WORK:schroder@proton.me
        TEL;type=CELL;type=VOICE;type=pref:(911) 555-511
        TEL;type=HOME;type=VOICE:1 (234) 567-89
        ITEM1.ADR;type=WORK;type=pref:;;1600 Pennsylania Avenue;Washington D.C;;20500;United States
        ITEM1.X-ABADR:us
        URL;type=HOME;type=pref:www.dirkschroder.com
        BDAY:2003-11-11
        ITEM0.X-PM-MIMETYPE:text/plain
        ITEM0.X-PM-SCHEME:pgp-inline
        END:VCARD
        """
    }

}
