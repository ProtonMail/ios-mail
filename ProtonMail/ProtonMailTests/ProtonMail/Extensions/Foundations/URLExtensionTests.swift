// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
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
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

class URLExtensionTests: XCTestCase {

    func testRemoveProtonSchemeIfNeeded() throws {
        var url = try XCTUnwrap(URL(string: "http://abc.com"), "Invalid url")
        url = url.removeProtonSchemeIfNeeded()
        XCTAssertEqual(url.absoluteString, "http://abc.com")

        url = try XCTUnwrap(URL(string: "https://abc.com"), "Invalid url")
        url = url.removeProtonSchemeIfNeeded()
        XCTAssertEqual(url.absoluteString, "https://abc.com")

        url = try XCTUnwrap(URL(string: "ftp://abc.com"), "Invalid url")
        url = url.removeProtonSchemeIfNeeded()
        XCTAssertEqual(url.absoluteString, "ftp://abc.com")

        url = try XCTUnwrap(URL(string: "pm-incoming-mail://0ba37cbb-0637-4af7-9862-6213cf5c9013.proton/www.protonmail.com"), "Invalid url")
        url = url.removeProtonSchemeIfNeeded()
        XCTAssertEqual(url.absoluteString, "https://www.protonmail.com")
    }

    func testIsOwnedByProton() {
        var url = URL(string: "https://proton.me")!
        XCTAssertTrue(url.isOwnedByProton)

        url = URL(string: "https://sldkfjixvle.protonmail.com")!
        XCTAssertTrue(url.isOwnedByProton)

        url = URL(string: "https://protonmail.ch/test")!
        XCTAssertTrue(url.isOwnedByProton)

        url = URL(string: "https://gdpr.eu.fake")!
        XCTAssertFalse(url.isOwnedByProton)
    }
}
