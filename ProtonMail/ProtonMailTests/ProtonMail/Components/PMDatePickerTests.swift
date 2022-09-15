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

final class PMDatePickerTests: XCTestCase {

    func testBaseDateForScheduleSend() {
        // Sun Aug 28 2022 23:44:30 GMT+0000
        var date = Date(timeIntervalSince1970: 1661730270)
        // Sun Aug 28 2022 23:45:00 GMT+0000
        var result = PMDatePicker.referenceDate(from: date)
        XCTAssertEqual(result.timeIntervalSince1970, 1661730300)

        // Sun Aug 28 2022 23:46:00 GMT+0000
        date = Date(timeIntervalSince1970: 1661730360)
        // Sun Aug 28 2022 23:50:00 GMT+0000
        result = PMDatePicker.referenceDate(from: date)
        XCTAssertEqual(result.timeIntervalSince1970, 1661730600)
    }

}
