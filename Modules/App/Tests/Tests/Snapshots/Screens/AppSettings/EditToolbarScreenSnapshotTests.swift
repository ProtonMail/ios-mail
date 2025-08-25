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
import SwiftUI
import Testing

@MainActor
struct EditToolbarScreenSnapshotTests {

    @Test
    func editToolbarScreenScreenLayoutsCorrectly() {
        let sut = EditToolbarScreen(
            state: .init(
                toolbarType: .message,
                toolbarActions: .init(
                    current: .init(
                        selected: [.toggleRead, .archive, .label],
                        unselected: [.move, .spam, .trash, .snooze, .toggleStar]
                    ),
                    defaultActions: .init(selected: [], unselected: [])
                )
            ),
            customizeToolbarService: CustomizeToolbarServiceSpy()
        )

        assertSnapshotsOnIPhoneX(of: sut, drawHierarchyInKeyWindow: true)
    }

}
