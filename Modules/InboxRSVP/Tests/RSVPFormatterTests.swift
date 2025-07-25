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
import Foundation
import InboxTesting
import Testing

@Suite(.calendarZurichEnUS, .currentDate(.fixture("2025-07-25 12:00:00")))
final class RSVPFormatterTests {
    typealias EventInput = (from: Date, to: Date)

    // MARK: - All-Day Events (.date)

    @Test(
        arguments: zip(
            [
                // Yesterday
                EventInput(from: .fixture("2025-07-24 00:00:00"), to: .fixture("2025-07-25 00:00:00")),
                // Today
                EventInput(from: .fixture("2025-07-25 00:00:00"), to: .fixture("2025-07-26 00:00:00")),
                // Tomorrow
                EventInput(from: .fixture("2025-07-26 00:00:00"), to: .fixture("2025-07-27 00:00:00")),
                // Single day in the future
                EventInput(from: .fixture("2025-08-01 00:00:00"), to: .fixture("2025-08-02 00:00:00")),
                // Multi-day (2 days)
                EventInput(from: .fixture("2025-09-15 00:00:00"), to: .fixture("2025-09-17 00:00:00")),
                // Multi-day spanning a month
                EventInput(from: .fixture("2025-09-30 00:00:00"), to: .fixture("2025-10-02 00:00:00")),
                // Multi-day spanning a year
                EventInput(from: .fixture("2025-12-30 00:00:00"), to: .fixture("2026-01-02 00:00:00")),
            ],
            [
                "Yesterday",
                "Today",
                "Tomorrow",
                "Aug 1, 2025",
                "Sep 15 – 16, 2025",
                "Sep 30 – Oct 1, 2025",
                "Dec 30, 2025 – Jan 1, 2026",
            ]
        )
    )
    func testAllDay(given: EventInput, expected: String) {
        #expect(formattedString(given, occurrence: .date) == expected)
    }

    // MARK: - Timed Events (.dateTime)

    @Test(
        arguments: zip(
            [
                // Single day, zero duration event (UTC 08:42 is 10:42 in Zurich)
                EventInput(from: .fixture("2025-07-24 08:42:00"), to: .fixture("2025-07-24 08:42:00")),
                // Single day, short duration (UTC 08:00 is 10:00 in Zurich)
                EventInput(from: .fixture("2025-08-20 08:00:00"), to: .fixture("2025-08-20 09:30:00")),
                // Spanning midnight (UTC 21:00 is 23:00 / 11 PM in Zurich)
                EventInput(from: .fixture("2025-08-21 21:00:00"), to: .fixture("2025-08-22 01:00:00")),
                // Multi-day timed event
                EventInput(from: .fixture("2025-11-10 14:00:00"), to: .fixture("2025-11-12 10:00:00")),
            ],
            [
                "Jul 24, 2025 at 10:42 AM",
                "Aug 20, 2025, 10:00 – 11:30 AM",
                "Aug 21, 2025 at 11:00 PM – Aug 22, 2025 at 3:00 AM",
                "Nov 10, 2025 at 3:00 PM – Nov 12, 2025 at 11:00 AM",
            ]
        )
    )
    func testDateTime(given: EventInput, expected: String) {
        #expect(formattedString(given, occurrence: .dateTime) == expected)
    }

    // MARK: - Private

    private func formattedString(_ given: EventInput, occurrence: RsvpOccurrence) -> String {
        let from = UInt64(given.from.timeIntervalSince1970)
        let to = UInt64(given.to.timeIntervalSince1970)

        return RSVPDateFormatter.string(from: from, to: to, occurrence: occurrence)
    }
}
