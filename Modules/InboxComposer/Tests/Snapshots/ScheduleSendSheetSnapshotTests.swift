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

import InboxSnapshotTesting
import SwiftUI
import Testing
import proton_app_uniffi

@testable import InboxComposer

@MainActor
@Suite(.calendarZurichEnUS)
final class ScheduleSendSheetSnapshotTests {
    let dateFormatter = ScheduleSendDateFormatter()

    @Test
    func testScheduleSend_whenFreeUser_itLayoutsCorrectOnIphoneX() throws {
        let options: DraftScheduleSendOptions =
            try ScheduleSendOptionsProvider.dummy(
                isCustomAvailable: false,
                stubTomorrowTime: 1_810_210_838,
                stubMondayTime: 1_810_729_238
            )
            .scheduleSendOptions().get()
        let scheduleSend = ScheduleSendPickerSheet(
            predefinedTimeOptions: options.toScheduleSendTimeOptions(lastScheduleSendTime: nil),
            isCustomOptionAvailable: options.isCustomOptionAvailable,
            dateFormatter: dateFormatter,
            onTimeSelected: { _ in }
        )
        assertSnapshotsOnIPhoneX(of: scheduleSend, precision: 0.98)
    }

    @Test
    func testScheduleSend_whenPaidUser_itLayoutsCorrectOnIphoneX() throws {
        let options: DraftScheduleSendOptions =
            try ScheduleSendOptionsProvider.dummy(
                isCustomAvailable: true,
                stubTomorrowTime: 1_810_210_838,
                stubMondayTime: 1_810_729_238
            )
            .scheduleSendOptions().get()
        let scheduleSend = ScheduleSendPickerSheet(
            predefinedTimeOptions: options.toScheduleSendTimeOptions(lastScheduleSendTime: nil),
            isCustomOptionAvailable: options.isCustomOptionAvailable,
            dateFormatter: dateFormatter,
            onTimeSelected: { _ in }
        )
        assertSnapshotsOnIPhoneX(of: scheduleSend)
    }

    @Test
    func testScheduleSend_whenPaidUser_andPreviouslySetTime_itLayoutsCorrectOnIphoneX() throws {
        let options: DraftScheduleSendOptions =
            try ScheduleSendOptionsProvider.dummy(
                isCustomAvailable: true,
                stubTomorrowTime: 1_810_210_838,
                stubMondayTime: 1_810_729_238
            )
            .scheduleSendOptions().get()
        let scheduleSend = ScheduleSendPickerSheet(
            predefinedTimeOptions: options.toScheduleSendTimeOptions(lastScheduleSendTime: 1_810_483_200),
            isCustomOptionAvailable: options.isCustomOptionAvailable,
            dateFormatter: dateFormatter,
            onTimeSelected: { _ in }
        )
        assertSnapshotsOnIPhoneX(of: scheduleSend)
    }
}
