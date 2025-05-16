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

@testable import InboxComposer
import InboxSnapshotTesting
import Testing
import SwiftUI

@MainActor
final class ScheduleSendSheetSnapshotTests {
    let dateFormatter = ScheduleSendDateFormatter(locale: Locale.enUS, timeZone: TimeZone.zurich)

    @Test
    func testScheduleSend_whenFreeUser_itLayoutsCorrectOnIphoneX() {
        let provider: ScheduleSendOptionsProvider = .dummy(
            isCustomAvailable: false,
            stubTomorrowTime: 1810210838,
            stubMondayTime: 1810729238
        )
        let scheduleSend = ScheduleSendPickerSheet(provider: provider, dateFormatter: dateFormatter)
        assertSnapshotsOnIPhoneX(of: scheduleSend, precision: 0.98)
    }

    @Test
    func testScheduleSend_whenPaidUser_itLayoutsCorrectOnIphoneX() {
        let provider: ScheduleSendOptionsProvider = .dummy(
            isCustomAvailable: true,
            stubTomorrowTime: 1810210838,
            stubMondayTime: 1810729238
        )
        let scheduleSend = ScheduleSendPickerSheet(provider: provider, dateFormatter: dateFormatter)
        assertSnapshotsOnIPhoneX(of: scheduleSend)
    }

    @Test
    func testScheduleSend_whenPaidUser_andPreviouslySetTime_itLayoutsCorrectOnIphoneX() {
        let provider: ScheduleSendOptionsProvider = .dummy(
            isCustomAvailable: true,
            stubTomorrowTime: 1810210838,
            stubMondayTime: 1810729238
        )
        let scheduleSend = ScheduleSendPickerSheet(
            provider: provider,
            dateFormatter: dateFormatter,
            lastScheduleSendTime: 1810483200
        )
        assertSnapshotsOnIPhoneX(of: scheduleSend)
    }
}
