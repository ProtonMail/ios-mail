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

struct MailboxActionBarActionsProvider {
    let availableActions: AvailableMailboxActionBarActions
    let itemTypeForActionBar: MailboxItemType
    let mailbox: Mailbox

    func actions(forItemsWith ids: [ID]) async -> AllBottomBarMessageActions {
        switch itemTypeForActionBar {
        case .message:
            try! await availableActions.message(mailbox, ids).get()
        case .conversation:
            try! await availableActions.conversation(mailbox, ids).get()
        }
    }
}

struct AvailableMailboxActionBarActions {
    let message: MessageBottomBarActionsProvider
    let conversation: ConversationBottomBarActionsProvider
}

extension AvailableMailboxActionBarActions {

    static var productionInstance: Self {
        .init(
            message: allAvailableBottomBarActionsForMessages,
            conversation: allAvailableBottomBarActionsForConversations
        )
    }

}

typealias MessageBottomBarActionsProvider = (Mailbox, [Id]) async -> AllAvailableBottomBarActionsForMessagesResult
typealias ConversationBottomBarActionsProvider = (Mailbox, [Id]) async -> AllAvailableBottomBarActionsForConversationsResult
