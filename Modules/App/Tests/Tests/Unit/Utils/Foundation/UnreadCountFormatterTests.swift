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

import XCTest
import proton_app_uniffi

@testable import ProtonMail

final class UnreadCountFormatterTests: XCTestCase {

    struct TestCase {
        struct Given {
            let count: UInt64
            let maxCount: UInt64
        }

        let given: Given
        let expected: String?
    }

    func testString_ForGivenCountAndMaxCount_HasCorrectValue() {
        let testCases: [TestCase] = [
            .init(given: .init(count: 0, maxCount: 1), expected: "0"),
            .init(given: .init(count: 101, maxCount: 999), expected: "101"),
            .init(given: .init(count: 0, maxCount: 0), expected: "0"),
            .init(given: .init(count: 99, maxCount: 99), expected: "99"),
            .init(given: .init(count: 1, maxCount: 0), expected: "0+"),
            .init(given: .init(count: 1_000, maxCount: 999), expected: "999+"),
        ]

        testCases.forEach { testCase in
            let formattedCount = UnreadCountFormatter.string(
                count: testCase.given.count,
                maxCount: testCase.given.maxCount
            )
            XCTAssertEqual(formattedCount, testCase.expected!)
        }
    }

    func testStringIfGreaterThan0_ForGivenCountAndMaxCount_HasCorrectValue() {
        let testCases: [TestCase] = [
            .init(given: .init(count: 0, maxCount: 1), expected: nil),
            .init(given: .init(count: 101, maxCount: 999), expected: "101"),
            .init(given: .init(count: 0, maxCount: 0), expected: nil),
            .init(given: .init(count: 99, maxCount: 99), expected: "99"),
            .init(given: .init(count: 1, maxCount: 0), expected: "0+"),
            .init(given: .init(count: 1_000, maxCount: 999), expected: "999+"),
        ]

        testCases.forEach { testCase in
            let formattedCount = UnreadCountFormatter.stringIfGreaterThan0(
                count: testCase.given.count,
                maxCount: testCase.given.maxCount
            )

            if let expectedValue = testCase.expected {
                XCTAssertEqual(formattedCount, expectedValue)
            } else {
                XCTAssertNil(formattedCount)
            }
        }
    }

}
