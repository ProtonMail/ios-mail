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
import InboxCore

extension Date {

    /**
     Mailbox date format
    
     The date will support the current locale which migth bring some differences to the following examples:
     ```
     Today:       11:24
     This year:   Feb 24
     Past years:  Mar 02, 2021
     ```
     */
    func mailboxFormat(calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(self) {
            return formatted(.dateTime.hour().minute())
        }
        else if calendar.isDate(self, equalTo: .now, toGranularity: .year) {
            return formatted(.dateTime.month().day())
        }
        else {
            return formatted(date: .abbreviated, time: .omitted)
        }
    }

    /**
     Mailbox date format
    
     The date will support the current locale which migth bring some differences to the following examples:
     ```
     Format Example
     Thu, Feb 24, 17:00
     ```
     */
    func snoozeFormat() -> String {
        formatted(.dateTime.weekday().month().day().hour().minute())
    }

    /**
     Mailbox date format for voice over support
    
     The date will support the current locale which migth bring some differences to the following examples:
     ```
     Today:       11:24
     This year:   February 24
     Past years:  October 17, 2020
     ```
     */
    func mailboxVoiceOverSupport(calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(self) {
            return formatted(.dateTime.hour().minute())
        }
        else if calendar.isDate(self, equalTo: .now, toGranularity: .year) {
            return formatted(.dateTime.month(.wide).day())
        }
        else {
            return formatted(date: .long, time: .omitted)
        }
    }

    /**
     Returns the time remaining to a future date.
    
     The returned values will be positive if the given date is in the future or negative if the date is in the past.
     ```
     For a date:
    
     24 hours from now:      year: 0 month: 0 day: 1 hour: 0 minute: 0 second: 0
     90 minutes from now:    year: 0 month: 0 day: 0 hour: 1 minute: 30 second: 0
     30 days in the past:    year: 0 month: -1 day: 0 hour: 0 minute: 0 second: 0
     ```
     */
    func remainingTimeFromNow() -> DateComponents {
        let now = DateEnvironment.currentDate()
        let calendar = DateEnvironment.calendar

        return calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now, to: self)
    }

    /**
     Returns the localised string for the time remaining to a future date
    
     The result unit will be that of the highest value only
     ```
     For a date:
    
     30 hours from now:      1 day
     150 minutes from now:   2 hours
     ```
     */
    func localisedRemainingTimeFromNow() -> String {
        DateComponentsFormatter.remainingTimeFromNowFormatter.string(from: remainingTimeFromNow()) ?? ""
    }
}
