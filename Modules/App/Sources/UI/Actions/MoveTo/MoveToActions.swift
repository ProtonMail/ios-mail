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

enum MoveActionResult {
    case ok(Undo?)
    case error(ActionError)
}

typealias MoveToActionClosure = (
    _ mailbox: Mailbox,
    _ destinationID: ID,
    _ itemsIDs: [ID]
) async -> MoveActionResult

struct MoveToActions {
    let moveMessagesTo: MoveToActionClosure
    let moveConversationsTo: MoveToActionClosure
}

extension MoveToActions {
    static var productionInstance: Self {
        .init(
            moveMessagesTo: { mailbox, destinationID, itemsIDs in
                await moveMessages(mailbox: mailbox, destinationId: destinationID, messageIds: itemsIDs).actionResult
            },
            moveConversationsTo: { mailbox, destinationID, itemsIDs in
                await moveConversations(mailbox: mailbox, labelId: destinationID, ids: itemsIDs).actionResult
            }
        )
    }

    static var dummy: Self {
        .init(
            moveMessagesTo: { _, _, _ in .ok(nil) },
            moveConversationsTo: { _, _, _ in .ok(nil) }
        )
    }
}

private extension MoveMessagesResult {
    var actionResult: MoveActionResult {
        switch self {
        case .ok(let undo):
            .ok(undo)
        case .error(let actionError):
            .error(actionError)
        }
    }
}

private extension MoveConversationsResult {
    var actionResult: MoveActionResult {
        switch self {
        case .ok(let undo):
            .ok(undo)
        case .error(let actionError):
            .error(actionError)
        }
    }
}
