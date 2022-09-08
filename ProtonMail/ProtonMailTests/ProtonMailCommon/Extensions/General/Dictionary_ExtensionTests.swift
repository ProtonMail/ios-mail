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

final class Dictionary_ExtensionTests: XCTestCase {
    func testToString() {
        let dict = ["name": "Tester", "age": 100] as [String: Any]
        let possible1 = ["{\"age\":100,\"name\":\"Tester\"}",
                         "{\"name\":\"Tester\",\"age\":100}"]
        XCTAssertTrue(possible1.contains(dict.toString()!))

        let invalid: [String: Any] = ["a": UIView()]
        XCTAssertNil(invalid.toString())
    }

    func testDictionaryConcat() {
        let dict1 = ["name": "Tester"]
        let dict2 = ["age": 100]
        let concat: [String: Any] = dict1 + dict2
        let possible1 = ["{\"age\":100,\"name\":\"Tester\"}",
                         "{\"name\":\"Tester\",\"age\":100}"]
        XCTAssertTrue(possible1.contains(concat.json()))
    }

    func testAttachmentOrderField() throws {
        let attachment1 = ["attID": 1]
        let attachment2 = ["attID": 2]
        var input: [String: Any] = ["Attachments": [attachment1, attachment2]]

        input.addAttachmentOrderField()

        let attachments = try XCTUnwrap(input["Attachments"] as? [[String: Any]])
        for index in attachments.indices {
            XCTAssertEqual(attachments[index]["Order"] as? Int, index)
        }
    }
}
