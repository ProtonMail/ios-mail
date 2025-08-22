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

@testable import ProtonMail
import InboxSnapshotTesting
import InboxTesting
import SwiftUI
import Testing

@MainActor
struct MessageActionsSheetSnapshotTests {

    @Test
    func actionSheetLayoutsCorrectly() {
        let state = MessageActionsSheetState(
            messageID: .init(value: 5),
            title: "Message action sheet",
            actions: .init(
                replyActions: [.reply, .replyAll, .forward],
                messageActions: [.markUnread, .star, .labelAs],
                moveActions: [.moveTo, .moveToSystemFolder(.init(localId: .random(), name: .archive))],
                generalActions: [.viewHtml, .print]
            ),
            colorScheme: .light
        )
        let sut = MessageActionsSheet(
            state: state,
            mailbox: .dummy,
            service: { _, _, _ in
                .ok(.init(replyActions: [], messageActions: [], moveActions: [], generalActions: []))
            },
            actionSelected: { _ in }
        )
        assertSnapshotsOnIPhoneX(
            of: NavigationStack { sut }
                .environment(\.messageAppearanceOverrideStore, MessageAppearanceOverrideStore())
        )
    }

}
