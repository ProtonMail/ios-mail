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

import InboxDesignSystem
import XCTest

@testable import ProtonMail

class DateMapTests: XCTestCase {

    func test_toExpirationDateUIModel_whenDateInThePast_itReturnsNil() {
        let pastDate = Date().addingTimeInterval(-1)

        XCTAssertNil(pastDate.toExpirationDateUIModel)
    }

    func test_toExpirationDateUIModel_whenExpiresInMoreThanOneHour_itReturnsTheRemainingTimeData() {
        let oneHourAndOneMinuteInSeconds: TimeInterval = 3601
        let futureDate = Date().addingTimeInterval(oneHourAndOneMinuteInSeconds)

        let result = futureDate.toExpirationDateUIModel

        XCTAssertEqual(result?.color, DS.Color.Text.norm)
        XCTAssertEqual(result?.text, L10n.Mailbox.Item.expiresIn(value: futureDate.localisedRemainingTimeFromNow()))
    }

    func test_toExpirationDateUIModel_whenExpiresIn30Minutes_itReturnsTheRemainingTimeData() {
        let thirtyMinutesInSeconds: TimeInterval = 1800
        let futureDate = Date().addingTimeInterval(thirtyMinutesInSeconds)

        let result = futureDate.toExpirationDateUIModel

        XCTAssertEqual(result?.color, DS.Color.Notification.warning)
        XCTAssertEqual(result?.text, L10n.Mailbox.Item.expiresIn(value: futureDate.localisedRemainingTimeFromNow()))
    }

    func test_toExpirationDateUIModel_whenExpiresInLessThanAMinute_itReturnsTheRemainingTimeData() {
        let thirtySeconds: TimeInterval = 30
        let futureDate = Date().addingTimeInterval(thirtySeconds)

        let result = futureDate.toExpirationDateUIModel

        XCTAssertEqual(result?.color, DS.Color.Notification.warning)
        XCTAssertEqual(result?.text, L10n.Mailbox.Item.expiresInLessThanOneMinute)
    }
}
