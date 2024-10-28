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
import InboxTesting

class MailboxActionBarViewSnapshotTests: BaseTestCase {

    func testMailboxActionBarLayoutsCorrectly() {
        let sut = MailboxActionBarView(
            state: MailboxActionBarPreviewProvider.state(),
            availableActions: MailboxActionBarPreviewProvider.availableActions(),
            selectedItems: .constant([.testData(id: 1), .testData(id: 2), .testData(id: 3)])
        )
        assertSnapshotsOnIPhoneX(of: sut, named: "mailbox_action_bar")
    }

}
