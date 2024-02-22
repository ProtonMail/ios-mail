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

struct EventDateIntervalFormatter {
    private static let partDayDateIntervalFormatter: DateIntervalFormatter = {
        let dateFormatter = DateIntervalFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    private static let allDayDateIntervalFormatter: DateIntervalFormatter = {
        let dateFormatter = DateIntervalFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()

    func string(from fromDate: Date, to toDate: Date, isAllDay: Bool) -> String {
        let formatter: DateIntervalFormatter
        var toDate = toDate

        if isAllDay {
            formatter = Self.allDayDateIntervalFormatter

            let isMultiDay = !Calendar.gmt.isDate(fromDate, inSameDayAs: toDate)

            if isMultiDay, let oneDayBeforeToDate = Calendar.gmt.date(byAdding: .day, value: -1, to: toDate) {
                toDate = oneDayBeforeToDate
            }
        } else {
            formatter = Self.partDayDateIntervalFormatter
        }

        return formatter.string(from: fromDate, to: toDate)
    }
}

private extension Calendar {
    static let gmt: Self = {
        var calendar = Calendar.current
        if #available(iOS 16, *) {
            calendar.timeZone = .gmt
        } else if let gmt = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = gmt
        }
        return calendar
    }()
}
