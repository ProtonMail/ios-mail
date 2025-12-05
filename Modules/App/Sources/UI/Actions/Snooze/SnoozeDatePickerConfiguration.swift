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
import InboxComposer
import InboxCore
import InboxCoreUI

struct SnoozeDatePickerConfiguration: DatePickerViewConfiguration {
    // MARK: - DatePickerViewConfiguration

    let title: LocalizedStringResource = L10n.Snooze.customSnoozeSheetTitle
    let selectTitle: LocalizedStringResource = L10n.Common.save
    let minuteInterval: TimeInterval = 1
    let initialSelectedDate: Date? = nil

    var range: ClosedRange<Date> {
        Date.currentDateRoundedUpToNextHalfHour...Date.distantFuture
    }

    func formatDate(_ date: Date) -> String {
        formatter.string(from: date, format: .medium)
    }

    // MARK: - Private

    private let formatter = ScheduleSendDateFormatter()
}

private extension Date {
    static var currentDateRoundedUpToNextHalfHour: Date {
        let interval: TimeInterval = 30 * 60
        let time = DateEnvironment.currentDate().timeIntervalSinceReferenceDate
        let roundedTime = ceil(time / interval) * interval
        return Date(timeIntervalSinceReferenceDate: roundedTime)
    }
}
