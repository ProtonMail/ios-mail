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

import InboxCore
import InboxCoreUI
import SwiftUI

struct CustomExpirationTimePickerConfiguration: DatePickerViewConfiguration {
    let title: LocalizedStringResource = L10n.MessageExpiration.datePickerTitle
    let selectTitle: LocalizedStringResource = CommonL10n.save
    let minuteInterval: TimeInterval = 30
    let initialSelectedDate: Date?
    private let minimumTimeBufferInMinutes: TimeInterval = 60

    private var rangeStart: Date {
        Date.now.roundedUp(by: minuteInterval, withInitialBuffer: minimumTimeBufferInMinutes)
    }

    private var rangeEnd: Date {
        Calendar.current.date(byAdding: .day, value: 28, to: rangeStart)!
    }

    var range: ClosedRange<Date> {
        rangeStart...rangeEnd
    }

    let formatter = ScheduleSendDateFormatter()

    func formatDate(_ date: Date) -> String {
        formatter.string(from: date, format: .medium)
    }

    init(initialSelectedDate: Date?) {
        self.initialSelectedDate = initialSelectedDate
    }
}
