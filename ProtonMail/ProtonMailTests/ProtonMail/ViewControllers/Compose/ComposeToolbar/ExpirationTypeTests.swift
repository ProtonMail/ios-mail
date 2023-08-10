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

final class ExpirationTypeTests: XCTestCase {
    typealias SUT = ComposeExpirationVC.ExpirationType

    func testTitle() throws {
        XCTAssertEqual(SUT.none.title, "None")
        XCTAssertEqual(SUT.oneHour.title, "1 hour")
        XCTAssertEqual(SUT.oneDay.title, "1 day")
        XCTAssertEqual(SUT.threeDays.title, "3 days")
        XCTAssertEqual(SUT.oneWeek.title, "1 week")
        XCTAssertEqual(SUT.custom.title, "Custom")
    }
}
