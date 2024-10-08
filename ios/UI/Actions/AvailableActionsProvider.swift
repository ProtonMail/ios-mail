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
import proton_app_uniffi
import SwiftUI

struct AvailableActionsProvider {
    let actionsProvider: ActionsProvider
    let mailbox: Mailbox

    func actions(for type: MailboxItemType, ids: [ID]) async -> Result<AvailableActions, Error> {
        let provider = actionsProvider(for: type)
        do {
            let actions = try await provider(mailbox, ids).availableActions
            return .success(actions)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Private

    private func actionsProvider(
        for type: MailboxItemType
    ) -> (_ mailbox: Mailbox, _ ids: [ID]) async throws -> AvailableActionsConvertible {
        switch type {
        case .message:
            actionsProvider.message
        case .conversation:
            actionsProvider.conversation
        }
    }
}

protocol AvailableActionsConvertible {
    var availableActions: AvailableActions { get }
}

extension MessageAvailableActions: AvailableActionsConvertible {

    var availableActions: AvailableActions {
        .init(
            replyActions: replyActions,
            mailboxItemActions: messageActions.map(\.action),
            moveActions: .mocked(), // FIXME: - Waiting for Rust SDK
            generalActions: generalActions
        )
    }

}

extension ConversationAvailableActions: AvailableActionsConvertible {

    var availableActions: AvailableActions {
        .init(
            replyActions: replyActions,
            mailboxItemActions: conversationActions.map(\.action),
            moveActions: .mocked(), // FIXME: - Waiting for Rust SDK
            generalActions: generalActions
        )
    }

}

// FIXME: - Waiting for Rust SDK
extension Array where Element == MoveToAction {

    static func mocked() -> Self {
        [
            .system(.init(localId: .init(value: 1), systemLabel: .inbox)),
            .system(.init(localId: .init(value: 2), systemLabel: .archive)),
            .system(.init(localId: .init(value: 3), systemLabel: .spam)),
            .system(.init(localId: .init(value: 4), systemLabel: .trash)),
            .moveTo
        ]
    }

}
