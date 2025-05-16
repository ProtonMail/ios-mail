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

public struct ScheduleSendDateFormatter {
    private let dateFormatter: DateFormatter

    public init(locale: Locale = .current, timeZone: TimeZone = .current) {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        self.dateFormatter = formatter
    }

    func string(from timestamp: UInt64) -> String {
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMM 'at' j:mm")
        return dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
    }

    public func stringWithRelativeDate(from timestamp: UInt64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let calendar = Calendar.current

        if calendar.isDateInToday(date) || calendar.isDateInTomorrow(date) {
            dateFormatter.doesRelativeDateFormatting = true
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: date)
        } else {
            return string(from: timestamp)
        }
    }
}
