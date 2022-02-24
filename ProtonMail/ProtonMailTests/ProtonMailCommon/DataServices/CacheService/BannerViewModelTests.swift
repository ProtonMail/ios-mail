// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

class BannerViewModelTests: XCTestCase {

    func testDurationsBySecond() {
        let sut = BannerViewModel.durationsBySecond
        let result = sut(1000)
        XCTAssertEqual(result.days, 0)
        XCTAssertEqual(result.hours, 0)
        XCTAssertEqual(result.minutes, 16)

        let result2 = sut(1000000)
        XCTAssertEqual(result2.days, 11)
        XCTAssertEqual(result2.hours, 13)
        XCTAssertEqual(result2.minutes, 46)
    }

    func testCalculateExpirationTitle_withMinusInput_getExpiredMsg() {
        let sut = BannerViewModel.calculateExpirationTitle
        let result = sut(-1)
        XCTAssertEqual(result, LocalString._message_expired)
    }

    func testCalculateExpirationTitle_withInput0_getExpiredMsg() {
        let sut = BannerViewModel.calculateExpirationTitle
        let result = sut(0)
        XCTAssertEqual(result, LocalString._message_expired)
    }

    func testCalculateExpirationTitle_withInput1000() {
        let sut = BannerViewModel.calculateExpirationTitle
        let expected = String(format: LocalString._expires_in_days_hours_mins_seconds, 0, 0, 17)

        let result = sut(1000)
        XCTAssertEqual(result, expected)
    }

    func testCalculateExpirationTitle_withInput1000000() {
        let sut = BannerViewModel.calculateExpirationTitle
        let expected = String(format: LocalString._expires_in_days_hours_mins_seconds, 11, 13, 47)

        let result = sut(1000000)
        XCTAssertEqual(result, expected)
    }
}
