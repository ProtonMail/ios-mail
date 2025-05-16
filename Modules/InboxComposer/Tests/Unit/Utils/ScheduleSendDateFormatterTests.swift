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

import Foundation
@testable import InboxComposer
import proton_app_uniffi
import Testing

final class ScheduleSendDateFormatterTests {
    private var sut: ScheduleSendDateFormatter! = .init(locale: .enUS, timeZone: .zurich)
    private var todayTime: UInt64 {
        let calendar: Calendar = .zurich
        let startOfDay = calendar.startOfDay(for: .now)
        let todayAt2359 = calendar.date(byAdding: DateComponents(hour: 23, minute: 59), to: startOfDay)!
        return UInt64(todayAt2359.timeIntervalSince1970)
    }
    private var tomorrowTime: UInt64 {
        ScheduleSendOptionsProvider.dummy(isCustomAvailable: false, calendar: .zurich).options().tomorrowTime
    }
    private var distantFutureTimestamp: UInt64 = 1889427600

    // MARK: string(from:)

    @Test
    func testString_withRelativeDate() async {
        #expect(sut.string(from: tomorrowTime).lowercased().contains("tomorrow") == false)
    }

    @Test
    func testString_withDistantFutureDate() async {
        #expect(sut.string(from: distantFutureTimestamp) == "Nov 15 at 10:00 AM")
    }

    // MARK: stringWithRelativeDate(from:)

    @Test
    func testStringWithRelativeDate_withRelativeDate_today() async {
        #expect(sut.stringWithRelativeDate(from: todayTime) == "Today at 11:59 PM")
    }

    @Test
    func testStringWithRelativeDate_withRelativeDate_tomorrow() async {
        #expect(sut.stringWithRelativeDate(from: tomorrowTime) == "Tomorrow at 8:00 AM")
    }

    @Test
    func testStringWithRelativeDate_withDistantFutureDate() async {
        #expect(sut.stringWithRelativeDate(from: distantFutureTimestamp) == "Nov 15 at 10:00 AM")
    }
}
