// Copyright (c) 2025 Proton Technologies AG
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
import ProtonUIFoundations
import proton_app_uniffi

@MainActor
struct SwipeActionsHandler {
    private let userSession: MailUserSession
    private let readActionPerformer: ReadActionPerformer
    private let starActionPerformer: StarActionPerformer
    private let moveToActionPerformer: MoveToActionPerformer

    init(userSession: MailUserSession, mailbox: Mailbox) {
        self.userSession = userSession
        self.readActionPerformer = .init(mailbox: mailbox, readActionPerformerActions: .productionInstance)
        self.starActionPerformer = .init(mailUserSession: userSession, starActionPerformerActions: .productionInstance)
        self.moveToActionPerformer = .init(mailbox: mailbox, moveToActions: .productionInstance)
    }

    func handle(_ context: SwipeActionContext, toastStateStore: ToastStateStore, viewMode: ViewMode) -> ActionSheetInput? {
        let ids: [ID] = [context.itemID]

        switch context.action {
        case .labelAs:
            return .init(sheetType: .labelAs, ids: ids, mailboxItem: viewMode.itemType.mailboxItem)
        case .moveTo(.moveToUnknownLabel):
            return .init(sheetType: .moveTo, ids: ids, mailboxItem: viewMode.itemType.mailboxItem)
        case .toggleRead:
            if context.isItemRead {
                readActionPerformer.markAsUnread(itemsWithIDs: ids, itemType: viewMode.itemType)
            } else {
                readActionPerformer.markAsRead(itemsWithIDs: ids, itemType: viewMode.itemType)
            }
        case .toggleStar:
            if context.isItemStarred {
                starActionPerformer.unstar(itemsWithIDs: ids, itemType: viewMode.itemType)
            } else {
                starActionPerformer.star(itemsWithIDs: ids, itemType: viewMode.itemType)
            }
        case .moveTo(.moveToSystemLabel(let label, let labelID)):
            move(itemIDs: ids, to: labelID, viewMode: viewMode, label: label, toastStateStore: toastStateStore)
        case .noAction:
            break
        }
        return nil
    }

    private func move(
        itemIDs: [ID],
        to destinationID: ID,
        viewMode: ViewMode,
        label: SystemLabel,
        toastStateStore: ToastStateStore
    ) {
        Task {
            do {
                let undo = try await moveToActionPerformer.moveTo(
                    destinationID: destinationID,
                    itemsIDs: itemIDs,
                    itemType: viewMode.itemType
                )
                let toastID = UUID()
                let undoAction = undo.undoAction(userSession: userSession) {
                    toastStateStore.dismiss(withID: toastID)
                }
                let toast: Toast = .moveTo(
                    id: toastID,
                    destinationName: label.humanReadable.string,
                    undoAction: undoAction
                )
                toastStateStore.present(toast: toast)
            } catch {
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        }
    }
}
