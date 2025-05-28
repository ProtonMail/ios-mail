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

@testable import InboxCoreUI
@testable import InboxComposer
import InboxSnapshotTesting
import Testing
import SwiftUI

@MainActor
final class ScheduleSendDatePickerSnapshotTests {
    let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
    let dateFormatter = ScheduleSendDateFormatter(locale: Locale.enUS, timeZone: TimeZone.zurich)

    @Test
    func testScheduleSendDatePicker_itLayoutsCorrectOnIphoneX() throws {
        let scheduleSendDatePicker = DatePickerView(
            configuration: ScheduleDatePickerConfiguration(dateFormatter: dateFormatter, referenceDate: referenceDate),
            onCancel: {},
            onSelect: { _ in }
        )
        // these environemnts are provided for the native DatePicker component
        .environment(\.calendar, Calendar(identifier: .gregorian))
        .environment(\.locale, Locale.enUS)
        .environment(\.timeZone, TimeZone.zurich)

        assertSnapshotsOnIPhoneX(of: scheduleSendDatePicker)
    }
}
