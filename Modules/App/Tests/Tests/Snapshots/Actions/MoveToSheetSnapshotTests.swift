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
import XCTest

@MainActor
class MoveToSheetSnapshotTests: BaseTestCase {

    func testActionSheetLayoutsCorrectly() {
        let sut = MoveToSheet(
            input: .init(sheetType: .moveTo, ids: [], mailboxItem: .message(isLastMessageInCurrentLocation: false)),
            mailbox: .dummy,
            availableMoveToActions: MoveToSheetPreviewProvider.availableMoveToActions,
            moveToActions: .dummy,
            navigation: { _ in },
            mailUserSession: .dummy
        ).environmentObject(ToastStateStore(initialState: .initial))
        assertSnapshotsOnIPhoneX(of: sut, named: "move_to_sheet")
    }

}
