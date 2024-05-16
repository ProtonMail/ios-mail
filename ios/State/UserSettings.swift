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
    var mailboxViewMode: MailboxViewMode
    var mailboxActions: MailboxActionSettings

    var leadingSwipeAction: SwipeAction = .toggleReadStatus
    var trailingSwipeAction: SwipeAction = .delete

    init(
        mailboxViewMode: MailboxViewMode,
        mailboxActions: MailboxActionSettings
    ) {
        self.mailboxViewMode = mailboxViewMode
        self.mailboxActions = mailboxActions
    }
}

enum MailboxViewMode {
    case message
    case conversation
}

struct MailboxActionSettings {
    let action1: MailboxAction
    let action2: MailboxAction
    let action3: MailboxAction
    let action4: MailboxAction

    init(
        action1: MailboxAction = .toggleReadStatus,
        action2: MailboxAction = .toggleStarStatus,
        action3: MailboxAction = .moveToArchive,
        action4: MailboxAction = .labelAs
    ) {
        self.action1 = action1
        self.action2 = action2
        self.action3 = action3
        self.action4 = action4
    }
}
