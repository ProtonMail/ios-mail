// Copyright (c) 2022 Proton AG
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

final class PhantomTests: XCTestCase {

    func testPhantom() {
        let id = Phantom<ContactIDTag, String>.init(rawValue: "aaa")
        let id2 = Phantom<ContactIDTag, String>.init(rawValue: "aaa")
        XCTAssertTrue(id == id2)
        XCTAssertEqual(id.rawValue, "aaa")
    }

    func testConversionToString() {
        let labelID = LabelID("foo")
        XCTAssertEqual("\(labelID)", "foo")

        let predicate = NSPredicate(format: "%K IN %@", labelID.rawValue, [labelID, labelID])
        XCTAssertEqual(predicate.description, "foo IN {foo, foo}")
    }

    func testCodableSupport() throws {
        let phantomTag = UserID(rawValue: "foo")

        let encodedPhantomTag = try JSONEncoder().encode(phantomTag)
        let decodedPhantomTag = try JSONDecoder().decode(UserID.self, from: encodedPhantomTag)

        XCTAssertEqual(decodedPhantomTag, phantomTag)
    }

    func testEncodesToRawValue() throws {
        let rawValue = "foo"
        let phantomTag = UserID(rawValue: rawValue)

        let encodedPhantomTag = try JSONEncoder().encode(phantomTag)
        let encodedRawValue = try JSONEncoder().encode(rawValue)

        XCTAssertEqual(encodedPhantomTag, encodedRawValue)
    }
}
