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
import Testing
import proton_app_uniffi

@testable import InboxComposer

@Suite(.calendarZurichEnUS)
final class ScheduleSendDateFormatterTests {
    private var sut: ScheduleSendDateFormatter! = .init()
    private var todayTime: Date {
        let calendar: Calendar = .zurich
        let startOfDay = calendar.startOfDay(for: .now)
        return calendar.date(byAdding: DateComponents(hour: 23, minute: 59), to: startOfDay)!
    }
    private var tomorrowTime: Date {
        try! ScheduleSendOptionsProvider
            .dummy(isCustomAvailable: false, calendar: .zurich)
            .scheduleSendOptions()
            .get()
            .tomorrowTime
            .date
    }
    private var distantFuture: Date { Date(timeIntervalSince1970: 1_889_427_600) }

    // MARK: Format.short

    @Test
    func testString_withRelativeDate_andShortFormat_itDoesNotReturnRelative() async {
        #expect(sut.string(from: tomorrowTime, format: .short).lowercased().contains("tomorrow") == false)
    }

    @Test
    func testString_withDistantFutureDate_andShortFormat() async {
        #expect(sut.string(from: distantFuture, format: .short) == "Nov 15 at 10:00 AM")
    }

    // MARK: Format.relativeOrShort

    @Test
    func testString_withRelativeDate_today_andRelativeFormat() async {
        #expect(sut.string(from: todayTime, format: .relativeOrShort) == "today at 11:59 PM")
    }

    @Test
    func testString_withRelativeDate_tomorrow_andRelativeFormat() async {
        #expect(sut.string(from: tomorrowTime, format: .relativeOrShort) == "tomorrow at 8:00 AM")
    }

    @Test
    func testString_withDistantFutureDate_andRelativeFormat() async {
        #expect(sut.string(from: distantFuture, format: .relativeOrShort) == "Nov 15 at 10:00 AM")
    }

    // MARK: Format.long

    @Test
    func testString_withRelativeDate_andLongFormat_itDoesNotReturnRelative() async {
        #expect(sut.string(from: tomorrowTime, format: .short).lowercased().contains("tomorrow") == false)
    }

    @Test
    func testString_withDistantFutureDate_andLongFormat() async {
        #expect(sut.string(from: distantFuture, format: .long) == "Thursday, November 15 at 10:00 AM")
    }
}
