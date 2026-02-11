// Copyright (c) 2026 Proton Technologies AG
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

@testable import InboxCore

final class CaseInsensitiveRawRepresentableTests: XCTestCase {

    private enum TestStatus: String, CaseInsensitiveRawRepresentable {
        case active = "Active"
        case inactive = "Inactive"
        case pending = "PENDING"
        case archived = "archived"
    }

    func testInit_WithExactMatch_ReturnsCorrectCase() {
        XCTAssertEqual(TestStatus(caseInsensitive: "Active"), .active)
        XCTAssertEqual(TestStatus(caseInsensitive: "Inactive"), .inactive)
        XCTAssertEqual(TestStatus(caseInsensitive: "PENDING"), .pending)
        XCTAssertEqual(TestStatus(caseInsensitive: "archived"), .archived)
    }

    func testInit_WithLowercaseInput_ReturnsCorrectCase() {
        XCTAssertEqual(TestStatus(caseInsensitive: "active"), .active)
        XCTAssertEqual(TestStatus(caseInsensitive: "inactive"), .inactive)
        XCTAssertEqual(TestStatus(caseInsensitive: "pending"), .pending)
        XCTAssertEqual(TestStatus(caseInsensitive: "archived"), .archived)
    }

    func testInit_WithUppercaseInput_ReturnsCorrectCase() {
        XCTAssertEqual(TestStatus(caseInsensitive: "ACTIVE"), .active)
        XCTAssertEqual(TestStatus(caseInsensitive: "INACTIVE"), .inactive)
        XCTAssertEqual(TestStatus(caseInsensitive: "PENDING"), .pending)
        XCTAssertEqual(TestStatus(caseInsensitive: "ARCHIVED"), .archived)
    }

    func testInit_WithMixedCaseInput_ReturnsCorrectCase() {
        XCTAssertEqual(TestStatus(caseInsensitive: "AcTiVe"), .active)
        XCTAssertEqual(TestStatus(caseInsensitive: "InAcTiVe"), .inactive)
        XCTAssertEqual(TestStatus(caseInsensitive: "PeNdInG"), .pending)
        XCTAssertEqual(TestStatus(caseInsensitive: "ArChIvEd"), .archived)
    }

    func testInit_WithNonExistentValue_ReturnsNil() {
        XCTAssertNil(TestStatus(caseInsensitive: "unknown"))
        XCTAssertNil(TestStatus(caseInsensitive: "UNKNOWN"))
        XCTAssertNil(TestStatus(caseInsensitive: "deleted"))
        XCTAssertNil(TestStatus(caseInsensitive: "suspended"))
    }

    func testInit_WithEmptyString_ReturnsNil() {
        XCTAssertNil(TestStatus(caseInsensitive: ""))
    }
}
