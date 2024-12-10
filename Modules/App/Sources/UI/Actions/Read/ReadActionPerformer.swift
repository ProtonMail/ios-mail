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

struct ReadActionPerformer {
    private let mailbox: Mailbox
    private let readActionPerformerActions: ReadActionPerformerActions

    init(
        mailbox: Mailbox,
        readActionPerformerActions: ReadActionPerformerActions = .productionInstance
    ) {
        self.mailbox = mailbox
        self.readActionPerformerActions = readActionPerformerActions
    }

    func markAsRead(itemsWithIDs ids: [ID], itemType: MailboxItemType, completion: (() -> Void)? = nil) {
        Task {
            await markAsRead(itemsWithIDs: ids, itemType: itemType)
            completion?()
        }
    }

    func markAsUnread(itemsWithIDs ids: [ID], itemType: MailboxItemType, completion: (() -> Void)? = nil) {
        Task {
            await markAsUnread(itemsWithIDs: ids, itemType: itemType)
            completion?()
        }
    }

    // MARK: - Private

    private func markAsRead(itemsWithIDs ids: [ID], itemType: MailboxItemType) async {
        switch itemType {
        case .message:
            await execute(action: readActionPerformerActions.markMessageAsRead, on: ids)
        case .conversation:
            await execute(action: readActionPerformerActions.markConversationAsRead, on: ids)
        }
    }

    private func markAsUnread(itemsWithIDs ids: [ID], itemType: MailboxItemType) async {
        switch itemType {
        case .message:
            await execute(action: readActionPerformerActions.markMessageAsUnread, on: ids)
        case .conversation:
            await execute(action: readActionPerformerActions.markConversationAsUnread, on: ids)
        }
    }

    private func execute(action: ReadActionClosure, on ids: [ID]) async {
        switch await action(mailbox, ids) {
        case .ok:
            break
        case .error(let error):
            fatalError("\(error)")
        }
    }
}
