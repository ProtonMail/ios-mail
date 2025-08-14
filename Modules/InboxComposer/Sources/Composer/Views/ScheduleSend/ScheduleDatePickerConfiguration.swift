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

import InboxCoreUI
import Foundation

struct ScheduleDatePickerConfiguration: DatePickerViewConfiguration {
    private let referenceDate: Date
    private let dateFormatter: ScheduleSendDateFormatter
    private let minimumTimeBufferInMinutes: TimeInterval = 10

    private var rangeStart: Date {
        referenceDate.roundedUp(by: minuteInterval, withInitialBuffer: minimumTimeBufferInMinutes)
    }

    private var rangeEnd: Date {
        // we use 89 to keep the date below 90 considering the time of the day value
        Calendar.current.date(byAdding: .day, value: 89, to: rangeStart)!
    }

    let title: LocalizedStringResource = L10n.ScheduleSend.title
    let selectTitle: LocalizedStringResource = L10n.Composer.send
    let minuteInterval: TimeInterval = 5

    init(dateFormatter: ScheduleSendDateFormatter, referenceDate: Date = .now) {
        self.referenceDate = referenceDate
        self.dateFormatter = dateFormatter
    }

    var range: ClosedRange<Date> {
        rangeStart...rangeEnd
    }

    let initialSelectedDate: Date? = nil

    func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date, format: .medium)
    }

}
