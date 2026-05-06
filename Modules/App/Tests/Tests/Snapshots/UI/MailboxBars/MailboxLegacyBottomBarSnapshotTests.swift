// Copyright (c) 2026 Proton Technologies AG
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

@testable import ProtonMail

@MainActor
struct MailboxLegacyBottomBarSnapshotTests {
    struct TestCase: Sendable {
        let state: UnreadButtonState
        let name: String
    }

    @Test(arguments: [
        TestCase(
            state: .init(isSelected: false, counterState: .known(unreadCount: 5)),
            name: "unread_deselected_known_count"
        ),
        TestCase(
            state: .init(isSelected: true, counterState: .known(unreadCount: 5)),
            name: "unread_selected_known_count"
        ),
        TestCase(
            state: .init(isSelected: false, counterState: .unknown),
            name: "unread_deselected_unknown_count"
        ),
    ])
    func snapshotLegacyBottomBar(_ testCase: TestCase) {
        assertSelfSizingSnapshot(
            of: MailboxLegacyBottomBarView(state: testCase.state, action: { _ in }),
            named: testCase.name
        )
    }
}
