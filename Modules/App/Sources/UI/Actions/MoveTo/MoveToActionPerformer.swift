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

struct MoveToActionPerformer {
    private let mailbox: Mailbox
    private let moveToActions: MoveToActions

    init(mailbox: Mailbox, moveToActions: MoveToActions) {
        self.mailbox = mailbox
        self.moveToActions = moveToActions
    }

    func moveTo(destinationID: ID, itemsIDs: [ID], itemType: MailboxItemType) async throws -> Undo? {
        let moveToAction = moveToAction(itemType: itemType)

        switch await moveToAction(mailbox, destinationID, itemsIDs) {
        case .ok(let undo):
            return undo
        case .error(.other(.serverError(let userApiServiceError)))
        where userApiServiceError.errorCode == ProtonErrorCode.doesNotExist:
            throw LocalError.folderDoesNotExist
        case .error(let error):
            throw error
        }
    }

    // MARK: - Private

    private func moveToAction(itemType: MailboxItemType) -> MoveToActionClosure {
        switch itemType {
        case .message:
            moveToActions.moveMessagesTo
        case .conversation:
            moveToActions.moveConversationsTo
        }
    }
}

extension MoveToActionPerformer {
    enum LocalError: LocalizedError {
        case folderDoesNotExist

        var errorDescription: String? {
            switch self {
            case .folderDoesNotExist:
                L10n.Folders.doesNotExist.string
            }
        }
    }
}
