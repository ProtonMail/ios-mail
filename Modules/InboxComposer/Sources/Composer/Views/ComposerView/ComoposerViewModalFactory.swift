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

@MainActor
struct ComposerViewModalFactory {
    private let makeScheduleSend: () -> ScheduleSendPickerSheet
    private let makeAttachmentPicker: () -> AttachmentSourcePickerSheet

    init(pickerState: Binding<AttachmentPickersState>) {
        self.makeScheduleSend = {
            ScheduleSendPickerSheet(provider: .dummy(isCustomAvailable: false))  // TODO: use .productionInstance when SDK is ready
        }
        self.makeAttachmentPicker = {
            AttachmentSourcePickerSheet(pickerState: pickerState)
        }
    }

    @ViewBuilder
    func makeModal(for state: ComposerViewModalState) -> some View {
        switch state {
        case .scheduleSend:
            makeScheduleSend()
        case .attachmentPicker:
            makeAttachmentPicker()
        }
    }
}
