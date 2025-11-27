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

import SwiftUI
import XCTest

@testable import InboxCoreUI

final class Color_HexTests: XCTestCase {
    func testColorInitWithHexString_ReturnsCorrectColor() {
        struct TestCase {
            let givenHexColor: String
            let expectedColor: Color
        }

        let testCases: [TestCase] = [
            .init(givenHexColor: "#FFFFFF", expectedColor: .white),
            .init(givenHexColor: "#000000", expectedColor: .black),
        ]

        testCases.forEach { testCase in
            XCTAssertEqual(Color(hex: testCase.givenHexColor), testCase.expectedColor)
        }
    }

    func testToHex_ForGivenColor_ReturnsCorrectHexValue() {
        struct TestCase {
            let givenColor: Color
            let expectedHexColor: String
        }

        let testCases: [TestCase] = [
            .init(givenColor: .white, expectedHexColor: "#FFFFFF"),
            .init(givenColor: .black, expectedHexColor: "#000000"),
        ]

        testCases.forEach { testCase in
            XCTAssertEqual(testCase.givenColor.toHex(), testCase.expectedHexColor)
        }
    }
}
