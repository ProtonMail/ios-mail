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

import Foundation
import InboxCore

enum RSVPDateFormatter {
    static func string(
        from fromTimestamp: UnixTimestamp,
        to toTimestamp: UnixTimestamp,
        occurrence: RsvpOccurrence
    ) -> String {
        let fromDate = Date(timeIntervalSince1970: TimeInterval(fromTimestamp))
        let toDate = Date(timeIntervalSince1970: TimeInterval(toTimestamp))

        switch occurrence {
        case .date:
            let calendar = DateEnvironment.calendarUTC
            let isMultiDay = !calendar.isDate(fromDate, inSameDayAs: toDate)

            var adjustedToDate = toDate

            if isMultiDay, let oneDayBefore = calendar.previousDay(before: toDate) {
                adjustedToDate = oneDayBefore
            }

            if calendar.isDate(fromDate, inSameDayAs: adjustedToDate) {
                let now = DateEnvironment.currentDate()
                let realNow = Date()

                var dateForStringFetching: Date?

                if calendar.isDate(fromDate, inSameDayAs: now) {
                    dateForStringFetching = realNow
                } else if calendar.isDateInTomorrow(fromDate) {
                    dateForStringFetching = calendar.nextDay(after: realNow)
                } else if calendar.isDateInYesterday(fromDate) {
                    dateForStringFetching = calendar.previousDay(before: realNow)
                }

                if let effectiveDate = dateForStringFetching {
                    return relativeFormatter.string(from: effectiveDate)
                }

                return allDayDateFormatter.string(from: fromDate)
            }

            return allDayDateIntervalFormatter.string(from: fromDate, to: adjustedToDate)
        case .dateTime:
            return partDayDateIntervalFormatter.string(from: fromDate, to: toDate)
        }
    }

    // MARK: - Private

    private static let partDayDateIntervalFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter.withEnvCalendar()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let allDayDateIntervalFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter.withUTCCalendar()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let allDayDateFormatter: DateFormatter = {
        let formatter = DateFormatter.withUTCCalendar()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let relativeFormatter: DateFormatter = {
        let formatter = DateFormatter.withUTCCalendar()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}

extension Calendar {

    func nextDay(after date: Date) -> Date? {
        self.date(byAdding: .day, value: 1, to: date)
    }

    func previousDay(before date: Date) -> Date? {
        self.date(byAdding: .day, value: -1, to: date)
    }

}
