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

extension Date {
    
    /**
     Mailbox date format

     The date will support the locale passed which migth bring some differences to the following examples:
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
}
