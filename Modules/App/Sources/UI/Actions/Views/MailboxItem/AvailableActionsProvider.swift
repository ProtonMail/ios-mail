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

    func actions(for type: MailboxItemType, ids: [ID]) async -> AvailableActions {
        switch type {
        case .conversation:
            try! await actionsProvider.conversation(mailbox, ids).get().availableActions
        case .message:
            try! await actionsProvider.message(mailbox, ids).get().availableActions
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
            moveActions: moveActions.map(\.moveToAction),
            generalActions: generalActions
        )
    }

}

extension ConversationAvailableActions: AvailableActionsConvertible {

    var availableActions: AvailableActions {
        .init(
            replyActions: nil,
            mailboxItemActions: conversationActions.map(\.action),
            moveActions: moveActions.map(\.moveToAction),
            generalActions: generalActions
        )
    }

}

private extension MoveItemAction {

    var moveToAction: MoveToAction {
        switch self {
        case .moveToSystemFolder(let systemFolder):
            return .system(systemFolder.moveToSystemFolderLocation)
        case .moveTo:
            return .moveTo
        case .notSpam(let systemFolder):
            return .notSpam(systemFolder.moveToSystemFolderLocation)
        case .permanentDelete:
            return .permanentDelete
        }
    }

}

private extension MovableSystemFolderAction {

    var moveToSystemFolderLocation: MoveToSystemFolderLocation {
        .init(localId: localId, systemLabel: name.moveToSystemFolderLabel)
    }

}
