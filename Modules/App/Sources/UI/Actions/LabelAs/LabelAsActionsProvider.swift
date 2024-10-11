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
    private let labelAsAvailableActionsProvider: LabelAsAvailableActionsProvider

    init(mailbox: Mailbox, labelAsAvailableActionsProvider: LabelAsAvailableActionsProvider) {
        self.mailbox = mailbox
        self.labelAsAvailableActionsProvider = labelAsAvailableActionsProvider
    }

    func actions(for type: MailboxItemType, ids: [ID]) async -> Result<[LabelAsAction], Error> {
        let provider = actionsProvider(for: type)
        do {
            let actions = try await provider(mailbox, ids)
            return .success(actions)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Private

    private func actionsProvider(
        for type: MailboxItemType
    ) -> (_ mailbox: Mailbox, _ ids: [ID]) async throws -> [LabelAsAction] {
        switch type {
        case .message:
            labelAsAvailableActionsProvider.message
        case .conversation:
            labelAsAvailableActionsProvider.conversation
        }
    }
}

struct LabelAsAvailableActionsProvider {
    let message: (_ mailbox: Mailbox, _ messageIDs: [ID]) async throws -> [LabelAsAction]
    let conversation: (_ mailbox: Mailbox, _ conversationIDs: [ID]) async throws -> [LabelAsAction]
}

extension LabelAsAvailableActionsProvider {
    static var instance: Self {
        .init(
            message: availableLabelAsActionsForMessages,
            conversation: availableLabelAsActionsForConversations
        )
    }
}
