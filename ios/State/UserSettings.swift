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

import Foundation

final class UserSettings: ObservableObject {
    var mailboxActions: MailboxActionSettings

    var leadingSwipeAction: SwipeAction = .toggleReadStatus
    var trailingSwipeAction: SwipeAction = .moveToTrash

    init(mailboxActions: MailboxActionSettings) {
        self.mailboxActions = mailboxActions
    }
}

struct MailboxActionSettings {
    let action1: MailboxItemAction
    let action2: MailboxItemAction
    let action3: MailboxItemAction
    let action4: MailboxItemAction

    init(
        action1: MailboxItemAction = .conditional(.toggleReadStatus),
        action2: MailboxItemAction = .conditional(.toggleStarStatus),
        action3: MailboxItemAction = .conditional(.moveToArchive),
        action4: MailboxItemAction = .action(.moveTo)
    ) {
        self.action1 = action1
        self.action2 = action2
        self.action3 = action3
        self.action4 = action4
    }
}
