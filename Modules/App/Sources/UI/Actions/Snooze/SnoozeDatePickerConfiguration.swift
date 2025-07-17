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
import InboxCoreUI
import InboxComposer

struct SnoozeDatePickerConfiguration: DatePickerViewConfiguration {
    let title: LocalizedStringResource = L10n.Snooze.customSnoozeSheetTitle
    let selectTitle: LocalizedStringResource = L10n.Common.save
    let minuteInterval: TimeInterval = 30

    var range: ClosedRange<Date> {
        let start = DateEnvironment.currentDate()
        let end = Date.distantFuture
        return start...end
    }

    let formatter = ScheduleSendDateFormatter()

    func formatDate(_ date: Date) -> String {
        formatter.string(from: date, format: .medium)
    }
}
