// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
import ProtonCore_DataModel
@testable import ProtonMail

class LinkOpenValidator: LinkOpeningValidator {
    var linkConfirmation: LinkOpeningMode = .openAtWill
}

class LinkOpeningValidatorTests: XCTestCase {

    var sut: LinkOpenValidator!

    override func setUp() {
        super.setUp()
        sut = LinkOpenValidator()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testShouldOpenPhishingAlert_notFromSpam_openAtWill_returnFalse() {
        let url = URL(string: "https://www.\(String.randomString(32)).ch")!
        sut.linkConfirmation = .openAtWill

        XCTAssertFalse(sut.shouldOpenPhishingAlert(url, isFromPhishingMsg: false))
    }

    func testShouldOpenPhishingAlert_notFromSpam_confirmationAlert_returnFalse() {
        let url = URL(string: "https://www.\(String.randomString(32)).ch")!
        sut.linkConfirmation = .confirmationAlert

        XCTAssertTrue(sut.shouldOpenPhishingAlert(url, isFromPhishingMsg: false))
    }

    func testShouldOpenPhishingAlert_fromSpam_returnTrue() {
        let url = URL(string: "https://www.\(String.randomString(32)).ch")!
        sut.linkConfirmation = .openAtWill
        XCTAssertTrue(sut.shouldOpenPhishingAlert(url, isFromPhishingMsg: true))
        sut.linkConfirmation = .confirmationAlert
        XCTAssertTrue(sut.shouldOpenPhishingAlert(url, isFromPhishingMsg: true))
    }

    func testShouldOpenPhishingAlert_withProtonUrl_fromSpam_returnFalse() {
        let url = URL(string: "https://protonmail.ch/")!
        sut.linkConfirmation = .openAtWill
        XCTAssertFalse(sut.shouldOpenPhishingAlert(url, isFromPhishingMsg: true))
        sut.linkConfirmation = .confirmationAlert
        XCTAssertFalse(sut.shouldOpenPhishingAlert(url, isFromPhishingMsg: true))
    }

    func testGeneratePhishingAlertContent_notFromSpam() {
        let url = URL(string: "https://www.\(String.randomString(32)).ch")!
        let result = sut.generatePhishingAlertContent(url, isFromPhishingMsg: false)
        XCTAssertEqual(result.0, LocalString._about_to_open_link)
        XCTAssertEqual(result.1, url.absoluteString)
    }

    func testGeneratePhishingAlertContent_fromSpam() {
        let url = URL(string: "https://www.\(String.randomString(32)).ch")!
        let result = sut.generatePhishingAlertContent(url, isFromPhishingMsg: true)
        XCTAssertEqual(result.0,
                       LocalString._spam_open_link_title)
        XCTAssertEqual(result.1,
                       String(format: LocalString._spam_open_link_content, url.absoluteString))
    }

    func testFeneratePhishingAlertContent_withLongUrl_notFromSpam() {
        let urlString = "https://www.\(String.randomString(32)).ch\(String.randomString(200))"
        let url = URL(string: urlString)!
        let expectedMsg = String(url.absoluteString.prefix(60) +
        "\n...\n" + url.absoluteString.suffix(40))

        let result = sut.generatePhishingAlertContent(url, isFromPhishingMsg: false)
        XCTAssertEqual(result.0, LocalString._about_to_open_link)
        XCTAssertEqual(result.1, expectedMsg)
    }

    func testFeneratePhishingAlertContent_withLongUrl_fromSpam() {
        let urlString = "https://www.\(String.randomString(32)).ch\(String.randomString(200))"
        let url = URL(string: urlString)!
        let expectedMsg = String(url.absoluteString.prefix(60) +
        "\n...\n" + url.absoluteString.suffix(40))

        let result = sut.generatePhishingAlertContent(url, isFromPhishingMsg: true)
        XCTAssertEqual(result.0,
                       LocalString._spam_open_link_title)
        XCTAssertEqual(result.1,
                       String(format: LocalString._spam_open_link_content, expectedMsg))
    }
}
