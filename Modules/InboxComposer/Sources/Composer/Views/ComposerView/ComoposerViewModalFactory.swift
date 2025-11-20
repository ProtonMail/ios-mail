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

import SwiftUI
import proton_app_uniffi

@MainActor
struct ComposerViewModalFactory {
    private let makeSenderAddressPicker: () -> SenderAddressPickerSheet
    private let makeScheduleSend: (DraftScheduleSendOptions, UInt64?) -> ScheduleSendPickerSheet
    private let makeAttachmentPicker: () -> AttachmentSourcePickerSheet
    private let makePasswordProtection: (_ password: String, _ hint: String) -> ComposerPasswordSheet
    private let makeCustomExpirationDatePicker: (Date?) -> CustomExpirationTimePickerSheet

    init(
        senderAddressPickerSheetModel: SenderAddressPickerSheetModel,
        scheduleSendAction: @escaping (Date) async -> Void,
        attachmentPickerState: Binding<AttachmentPickersState>,
        setPasswordAction: @escaping (_ password: String, _ hint: String?) async -> Void,
        setCustomExpirationDate: @escaping (UnixTimestamp) async -> Void
    ) {
        self.makeSenderAddressPicker = {
            SenderAddressPickerSheet(model: senderAddressPickerSheetModel)
        }
        self.makeScheduleSend = { schduleSendOptions, lastScheduledTime in
            ScheduleSendPickerSheet(
                predefinedTimeOptions: schduleSendOptions.toScheduleSendTimeOptions(lastScheduleSendTime: lastScheduledTime),
                isCustomOptionAvailable: schduleSendOptions.isCustomOptionAvailable,
                onTimeSelected: scheduleSendAction
            )
        }
        self.makeAttachmentPicker = {
            AttachmentSourcePickerSheet(pickerState: attachmentPickerState)
        }
        self.makePasswordProtection = { password, hint in
            ComposerPasswordSheet(state: .init(password: password, hint: hint), onSave: setPasswordAction)
        }
        self.makeCustomExpirationDatePicker = { date in
            CustomExpirationTimePickerSheet(selectedDate: date, onSelect: setCustomExpirationDate)
        }
    }

    @ViewBuilder
    func makeModal(for state: ComposerViewModalState) -> some View {
        switch state {
        case .senderPicker:
            makeSenderAddressPicker()
        case .scheduleSend(let sendTimeOptions, let lastScheduledTime):
            makeScheduleSend(sendTimeOptions, lastScheduledTime)
        case .attachmentPicker:
            makeAttachmentPicker()
        case .passwordProtection(let password, let hint):
            makePasswordProtection(password, hint)
        case .customExpirationDatePicker(let date):
            makeCustomExpirationDatePicker(date)
        }
    }
}
