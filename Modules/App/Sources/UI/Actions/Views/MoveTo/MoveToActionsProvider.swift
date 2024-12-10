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

import proton_app_uniffi

struct MoveToActionsProvider {
    private let mailbox: Mailbox
    private let availableMoveToActions: AvailableMoveToActions

    init(mailbox: Mailbox, availableMoveToActions: AvailableMoveToActions) {
        self.mailbox = mailbox
        self.availableMoveToActions = availableMoveToActions
    }

    func actions(for type: MailboxItemType, ids: [ID]) async -> [MoveAction] {
        switch type {
        case .message:
            try! await availableMoveToActions.message(mailbox, ids).get()
        case .conversation:
            try! await availableMoveToActions.conversation(mailbox, ids).get()
        }
    }
}

struct AvailableMoveToActions {
    let message: (_ mailbox: Mailbox, _ messageIDs: [ID]) async -> AvailableMoveToActionsForMessagesResult
    let conversation: (_ mailbox: Mailbox, _ conversationIDs: [ID]) async -> AvailableMoveToActionsForConversationsResult
}

extension AvailableMoveToActions {
    static var productionInstance: Self {
        .init(
            message: availableMoveToActionsForMessages,
            conversation: availableMoveToActionsForConversations
        )
    }
}
