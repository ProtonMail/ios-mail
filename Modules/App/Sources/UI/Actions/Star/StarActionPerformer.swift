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

struct StarActionPerformer {
    private let mailUserSession: MailUserSession
    private let starActionPerformerActions: StarActionPerformerActions

    init(
        mailUserSession: MailUserSession,
        starActionPerformerActions: StarActionPerformerActions = .productionInstance
    ) {
        self.mailUserSession = mailUserSession
        self.starActionPerformerActions = starActionPerformerActions
    }

    func unstar(itemsWithIDs ids: [ID], itemType: MailboxItemType, completion: (() -> Void)? = nil) {
        Task {
            await unstar(itemsWithIDs: ids, itemType: itemType)
            completion?()
        }
    }

    func star(itemsWithIDs ids: [ID], itemType: MailboxItemType, completion: (() -> Void)? = nil) {
        Task {
            await star(itemsWithIDs: ids, itemType: itemType)
            completion?()
        }
    }

    // MARK: - Private

    private func star(itemsWithIDs ids: [ID], itemType: MailboxItemType) async {
        switch itemType {
        case .message:
            await execute(action: starActionPerformerActions.starMessage, on: ids)
        case .conversation:
            await execute(action: starActionPerformerActions.starConversation, on: ids)
        }
    }

    private func unstar(itemsWithIDs ids: [ID], itemType: MailboxItemType) async {
        switch itemType {
        case .message:
            await execute(action: starActionPerformerActions.unstarMessage, on: ids)
        case .conversation:
            await execute(action: starActionPerformerActions.unstarConversation, on: ids)
        }
    }

    private func execute(action: StarActionClosure, on ids: [ID]) async {
        switch await action(mailUserSession, ids) {
        case .ok:
            break
        case .error(let error):
            fatalError("\(error)")
        }
    }
}
