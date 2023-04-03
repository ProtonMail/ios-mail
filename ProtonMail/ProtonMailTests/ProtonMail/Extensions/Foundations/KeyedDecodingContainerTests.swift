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

import Foundation
@testable import ProtonMail
import XCTest

struct TestObject: Parsable {
    let testField: Bool

    enum CodingKeys: String, CodingKey {
        case testField = "TestField"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        testField = container.decodeIfPresentBoolOrIntToBool(forKey: .testField, defaultValue: false)
    }
}

final class KeyedDecodingContainerTests: XCTestCase {
    func testDecodeIfPresentBoolOrIntToBool_valueIsMoreThan0_flagIsTrue() throws {
        let value = Int.random(in: 1...Int.max)
        let json: [String: Any] = [
            "TestField": value
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        let result = try decoder.decode(TestObject.self, from: data)
        XCTAssertTrue(result.testField)
    }

    func testDecodeIfPresentBoolOrIntToBool_valueIsSmallerThan1_flagIsFalse() throws {
        let value = Int.random(in: Int.min...0)
        let json: [String: Any] = [
            "TestField": value
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        let result = try decoder.decode(TestObject.self, from: data)
        XCTAssertFalse(result.testField)
    }

    func testDecodeIfPresentBoolOrIntToBool_valueIsTrue_flagIsTrue() throws {
        let json: [String: Any] = [
            "TestField": true
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        let result = try decoder.decode(TestObject.self, from: data)
        XCTAssertTrue(result.testField)
    }

    func testDecodeIfPresentBoolOrIntToBool_valueIsFalse_flagIsFalse() throws {
        let json: [String: Any] = [
            "TestField": false
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        let result = try decoder.decode(TestObject.self, from: data)
        XCTAssertFalse(result.testField)
    }

    func testDecodeIfPresentBoolOrIntToBool_valueIsString_flagIsFalse() throws {
        let json: [String: Any] = [
            "TestField": "false"
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        let result = try decoder.decode(TestObject.self, from: data)
        XCTAssertFalse(result.testField)
    }
}
