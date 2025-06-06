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
    public enum Format {
        /** Nov 15 at 10:00 AM */
        case short
        /** tomorrow at 10:00 AM */
        case relativeOrShort
        /** 27 May 2029 */
        case medium
        /** Thursday, November 15 at 10:00 AM */
        case long
    }

    private let dateFormatter: DateFormatter

    public init(locale: Locale = .current, timeZone: TimeZone = .current) {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        self.dateFormatter = formatter
    }

    public func string(from date: Date, format: Format) -> String {
        switch format {
        case .short:
            stringShortFormat(from: date)
        case .relativeOrShort:
            stringWithRelativeDate(from: date)
        case .medium:
            stringMediumFormat(from: date)
        case .long:
            stringLongFormat(from: date)
        }
    }

    private func stringShortFormat(from date: Date) -> String {
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMM 'at' j:mm")
        return dateFormatter.string(from: date)
    }

    private func stringWithRelativeDate(from date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) || calendar.isDateInTomorrow(date) {
            dateFormatter.doesRelativeDateFormatting = true
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            dateFormatter.formattingContext = .middleOfSentence
            return dateFormatter.string(from: date)
        } else {
            return string(from: date, format: .short)
        }
    }

    private func stringMediumFormat(from date: Date) -> String {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }

    private func stringLongFormat(from date: Date) -> String {
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEE, d MMMM 'at' j:mm")
        return dateFormatter.string(from: date)
    }
}
