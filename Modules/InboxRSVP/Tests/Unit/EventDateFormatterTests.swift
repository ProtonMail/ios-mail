// Copyright (c) 2025 Proton Technologies AG
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

@testable import InboxRSVP
import InboxCore
import Foundation
import InboxTesting
import proton_app_uniffi
import Testing

@Suite(.calendarZurichEnUS, .calendarGMTEnUS)
final class EventDateFormatterTests {
    typealias EventInput = (from: Date, to: Date)

    // MARK: - All‑Day Events (.date)

    @Test(
        arguments: zip(
            [
                EventInput(from: .yesterday(), to: .today()),
                EventInput(from: .today(), to: .tomorrow()),
                EventInput(from: .tomorrow(), to: .dayAfterTomorrow()),
            ],
            [
                "Yesterday",
                "Today",
                "Tomorrow",
            ]
        )
    )
    func testAllDayRelative(given: EventInput, expected: String) {
        #expect(formattedString(given, occurrence: .date) == expected)
    }

    @Test(
        .currentDate(.fixture("2025-06-25 12:00:00")),
        arguments: zip(
            [
                // Single day this year → no year
                EventInput(from: .fixture("2025-06-01 00:00:00"), to: .fixture("2025-06-02 00:00:00")),
                // Multi‑day within this year
                EventInput(from: .fixture("2025-04-15 00:00:00"), to: .fixture("2025-04-17 00:00:00")),
                // Spanning month in this year
                EventInput(from: .fixture("2025-04-30 00:00:00"), to: .fixture("2025-05-02 00:00:00")),
                // Spanning into next year → show both years
                EventInput(from: .fixture("2024-12-30 00:00:00"), to: .fixture("2025-01-02 00:00:00")),
                // Entirely in last year
                EventInput(from: .fixture("2024-06-05 00:00:00"), to: .fixture("2024-06-06 00:00:00")),
                // Entirely in future year
                EventInput(from: .fixture("2042-03-10 00:00:00"), to: .fixture("2042-03-11 00:00:00")),
            ],
            [
                "Sun, Jun 1",
                "Tue, Apr 15 – Wed, Apr 16, 2025",
                "Wed, Apr 30 – Thu, May 1, 2025",
                "Mon, Dec 30, 2024 – Wed, Jan 1, 2025",
                "Wed, Jun 5, 2024",
                "Mon, Mar 10, 2042",
            ]
        )
    )
    func testAllDayConditionalYear(given: EventInput, expected: String) {
        #expect(formattedString(given, occurrence: .date) == expected)
    }

    // MARK: - Timed Events (.dateTime)

    @Test(
        .currentDate(.fixture("2025-07-25 12:00:00")),
        arguments: zip(
            [
                // Single‑day zero‑length in current year
                EventInput(from: .fixture("2025-07-24 08:42:00"), to: .fixture("2025-07-24 08:42:00")),
                // Single‑day short in current year
                EventInput(from: .fixture("2025-08-20 08:00:00"), to: .fixture("2025-08-20 09:30:00")),
                // Spanning midnight in current year
                EventInput(from: .fixture("2025-08-21 21:00:00"), to: .fixture("2025-08-22 01:00:00")),
                // Multi‑day future year
                EventInput(from: .fixture("2026-11-09 14:00:00"), to: .fixture("2026-11-12 10:00:00")),
                // Entirely last year
                EventInput(from: .fixture("2024-04-01 07:00:00"), to: .fixture("2024-04-01 08:00:00")),
            ],
            [
                "Thu, Jul 24, 2025 at 10:42 AM",
                "Wed, Aug 20, 2025, 10:00 – 11:30 AM",
                "Thu, Aug 21, 2025 at 11:00 PM – Fri, Aug 22, 2025 at 3:00 AM",
                "Mon, Nov 9, 2026 at 3:00 PM – Thu, Nov 12, 2026 at 11:00 AM",
                "Mon, Apr 1, 2024, 9:00 – 10:00 AM",
            ]
        )
    )
    func testDateTimeConditionalYear(given: EventInput, expected: String) {
        #expect(formattedString(given, occurrence: .dateTime) == expected)
    }

    // MARK: - Private

    private func formattedString(_ given: EventInput, occurrence: RsvpOccurrence) -> String {
        let from = UInt64(given.from.timeIntervalSince1970)
        let to = UInt64(given.to.timeIntervalSince1970)

        return EventDateFormatter.string(from: from, to: to, occurrence: occurrence)
    }
}

private extension Date {

    static func yesterday() -> Date {
        calendar.previousDay(before: today())!
    }

    static func today() -> Date {
        calendar.startOfDay(for: Date())
    }

    static func tomorrow() -> Date {
        calendar.nextDay(after: today())!
    }

    static func dayAfterTomorrow() -> Date {
        calendar.nextDay(after: tomorrow())!
    }

    private static var calendar: Calendar {
        DateEnvironment.calendarGMT
    }

}
