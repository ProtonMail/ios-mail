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

struct LabelAsActionsProvider {
    private let mailbox: Mailbox
    private let availableLabelAsActions: AvailableLabelAsActions

    init(mailbox: Mailbox, availableLabelAsActions: AvailableLabelAsActions) {
        self.mailbox = mailbox
        self.availableLabelAsActions = availableLabelAsActions
    }

    func actions(for type: MailboxItemType, ids: [ID]) async throws -> [LabelAsAction] {
        switch type {
        case .conversation:
            try await availableLabelAsActions.conversation(mailbox, ids).get()
        case .message:
            try await availableLabelAsActions.message(mailbox, ids).get()
        }
    }
}

struct AvailableLabelAsActions {
    let message: (_ mailbox: Mailbox, _ messageIDs: [ID]) async -> AvailableLabelAsActionsForMessagesResult
    let conversation: (_ mailbox: Mailbox, _ conversationIDs: [ID]) async -> AvailableLabelAsActionsForConversationsResult
}

extension AvailableLabelAsActions {
    static var productionInstance: Self {
        .init(
            message: availableLabelAsActionsForMessages,
            conversation: availableLabelAsActionsForConversations
        )
    }
}
