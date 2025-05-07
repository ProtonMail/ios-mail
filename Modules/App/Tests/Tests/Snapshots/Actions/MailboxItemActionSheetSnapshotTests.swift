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

@testable import ProtonMail
import InboxCoreUI
import InboxSnapshotTesting
import InboxTesting

@MainActor
class MailboxItemActionSheetSnapshotTests: BaseTestCase {

    func testMessageConversationActionSheetLayoutsCorrectly() {
        for forceLightMode in [false, true] {
            let id = ID.random()
            let messageAppearanceOverrideStore = MessageAppearanceOverrideStore()

            if forceLightMode {
                messageAppearanceOverrideStore.forceLightMode(forMessageWithId: id)
            }

            let sut = MailboxItemActionSheet(
                input: .init(id: id, type: .message, title: "Hello".notLocalized),
                mailbox: .dummy,
                actionsProvider: MailboxItemActionSheetPreviewProvider.actionsProvider(),
                starActionPerformerActions: .dummy,
                readActionPerformerActions: .dummy,
                deleteActions: .dummy,
                moveToActions: .dummy,
                generalActions: .dummy,
                replyActions: { _, _ in },
                mailUserSession: .dummy,
                navigation: { _ in }
            )
                .environmentObject(ToastStateStore(initialState: .initial))
                .environment(\.messageAppearanceOverrideStore, messageAppearanceOverrideStore)

            assertSnapshotsOnIPhoneX(
                of: sut,
                named: "lightMode\(forceLightMode ? "" : "Not")Forced"
            )
        }
    }

}
