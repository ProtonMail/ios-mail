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

@testable import ProtonMail
import proton_mail_uniffi
import XCTest

final class UnsignedIntegerTests: XCTestCase {

    func testToBadgeCapped_whenValueBelowLimit_itReturnsTheValue() {
        XCTAssertEqual(UInt(0).toBadgeCapped(at: 1), "0")
        XCTAssertEqual(UInt(101).toBadgeCapped(at: 999), "101")
    }

    func testToBadgeCapped_whenValueEqualsTheLimit_itReturnsTheValue() {
        XCTAssertEqual(UInt(0).toBadgeCapped(at: 0), "0")
        XCTAssertEqual(UInt(99).toBadgeCapped(at: 99), "99")
    }

    func testToBadgeCapped_whenValueAboveTheLimit_itReturnsTheLimitFormatted() {
        XCTAssertEqual(UInt(1).toBadgeCapped(at: 0), "0+")
        XCTAssertEqual(UInt(1000).toBadgeCapped(at: 999), "999+")
    }
}
