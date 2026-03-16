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

import InboxCoreUI
import InboxSnapshotTesting
import InboxTesting
import ProtonUIFoundations
import Testing

@testable import InboxComposer

@MainActor
struct ComposerScreenSnapshotTests {
    @Test(.disabled("Recording empty snapshot after the changes with Liquid Glass"))
    func composerScreen_whenEmpty_itLayoutsCorrectOnIphoneX() throws {
        let toastStateStore = ToastStateStore.init(initialState: .initial)
        let composerView = ComposerView(
            draft: .emptyMock,
            draftOrigin: .new,
            draftLastScheduledTime: nil,
            contactProvider: .mockInstance,
            isAddingAttachmentsEnabled: true,
            onDismiss: { _ in }
        )
        .environmentObject(toastStateStore)
        assertSnapshotsOnIPhoneX(of: composerView, record: true)
    }
}
