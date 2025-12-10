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
import proton_app_uniffi

enum EventDateFormatter {
    static func string(
        from fromTimestamp: UnixTimestamp,
        to toTimestamp: UnixTimestamp,
        occurrence: RsvpOccurrence
    ) -> String {
        let fromDate = Date(timeIntervalSince1970: TimeInterval(fromTimestamp))
        let toDate = Date(timeIntervalSince1970: TimeInterval(toTimestamp))
        let now = DateEnvironment.currentDate()

        switch occurrence {
        case .date:
            let calendar = DateEnvironment.calendarGMT
            let isMultiDay = !calendar.isDate(fromDate, inSameDayAs: toDate)

            var adjustedToDate = toDate

            if isMultiDay, let oneDayBefore = calendar.previousDay(before: toDate) {
                adjustedToDate = oneDayBefore
            }

            if calendar.isDate(fromDate, inSameDayAs: adjustedToDate) {
                let realNow = Date()
                var relativeDate: Date?

                if calendar.isDate(fromDate, inSameDayAs: now) {
                    relativeDate = realNow
                } else if calendar.isDateInTomorrow(fromDate) {
                    relativeDate = calendar.nextDay(after: realNow)
                } else if calendar.isDateInYesterday(fromDate) {
                    relativeDate = calendar.previousDay(before: realNow)
                }

                if let relativeDate {
                    return relativeFormatter.string(from: relativeDate)
                }

                var allDayStyle = Date.FormatStyle(
                    date: .abbreviated,
                    time: .omitted,
                    locale: calendar.locale!,
                    calendar: calendar,
                    timeZone: calendar.timeZone
                )
                .weekday()

                if calendar.isDate(fromDate, equalTo: now, toGranularity: .year) {
                    if #available(iOS 18, *) {
                        allDayStyle = allDayStyle.year(.omitted)
                    }
                }

                return fromDate.formatted(allDayStyle)
            }

            let allDayIntervalStyle = Date.IntervalFormatStyle(
                date: .abbreviated,
                time: .omitted,
                locale: calendar.locale!,
                calendar: calendar,
                timeZone: calendar.timeZone
            )
            .weekday()

            return allDayIntervalStyle.format(fromDate..<adjustedToDate)
        case .dateTime:
            let calendar = DateEnvironment.calendar
            let dateTimeStyle = Date.IntervalFormatStyle(
                date: .abbreviated,
                time: .shortened,
                locale: calendar.locale!,
                timeZone: calendar.timeZone
            )
            .weekday()

            return dateTimeStyle.format(fromDate..<toDate)
        }
    }

    private static let relativeFormatter: DateFormatter = {
        let formatter = DateFormatter.withGMTCalendar()
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
