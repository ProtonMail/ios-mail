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

import InboxCore
import proton_app_uniffi
import SwiftUI

final class MailboxActionBarStateStore: StateStore {
    @Published var state: MailboxActionBarState
    private let actionsProvider: MailboxActionBarActionsProvider
    private let starActionPerformer: StarActionPerformer
    private let readActionPerformer: ReadActionPerformer
    private let deleteActionsPerformer: DeleteActionPerformer
    private let mailbox: Mailbox

    init(
        state: MailboxActionBarState,
        availableActions: AvailableMailboxActionBarActions,
        starActionPerformerActions: StarActionPerformerActions,
        readActionPerformerActions: ReadActionPerformerActions,
        deleteActions: DeleteActions,
        mailUserSession: MailUserSession,
        mailbox: Mailbox
    ) {
        self.state = state
        self.actionsProvider = .init(
            availableActions: availableActions,
            mailbox: mailbox
        )
        self.starActionPerformer = .init(
            mailUserSession: mailUserSession,
            starActionPerformerActions: starActionPerformerActions
        )
        self.readActionPerformer = .init(
            mailbox: mailbox,
            readActionPerformerActions: readActionPerformerActions
        )
        self.deleteActionsPerformer = .init(mailbox: mailbox, deleteActions: deleteActions)
        self.mailbox = mailbox
    }

    func handle(action: MailboxActionBarAction) {
        switch action {
        case .mailboxItemsSelectionUpdated(let ids):
            fetchAvailableBottomBarActions(for: ids)
        case .actionSelected(let action, let ids):
            handle(action: action, ids: ids)
        case .dismissLabelAsSheet:
            state = state.copy(\.labelAsSheetPresented, to: nil)
        case .dismissMoveToSheet:
            state = state.copy(\.moveToSheetPresented, to: nil)
        case .moreSheetAction(let action, let ids):
            handle(action: action, ids: ids)
        case .alertActionTapped(let action, let ids):
            state = state
                .copy(\.moreActionSheetPresented, to: nil)
                .copy(\.deleteConfirmationAlert, to: nil)
            if case .delete = action {
                deleteActionsPerformer.delete(itemsWithIDs: ids, itemType: mailbox.itemType)
            }
        }
    }

    // MARK: - Private

    private func handle(action: BottomBarAction, ids: [ID]) {
        switch action {
        case .more:
            let moreActionSheetState = MailboxActionBarMoreSheetState(
                selectedItemsIDs: ids,
                bottomBarActions: state.bottomBarActions.moreActionFiltered,
                moreSheetOnlyActions: state.moreSheetOnlyActions
            )
            state = state
                .copy(\.moreActionSheetPresented, to: nil)
                .copy(\.moreActionSheetPresented, to: moreActionSheetState)
        case .labelAs:
            state = state
                .copy(\.moreActionSheetPresented, to: nil)
                .copy(\.labelAsSheetPresented, to: .init(ids: ids, type: mailbox.itemType))
        case .moveTo:
            state = state
                .copy(\.moreActionSheetPresented, to: nil)
                .copy(\.moveToSheetPresented, to: .init(ids: ids, type: mailbox.itemType))
        case .star:
            state = state.copy(\.moreActionSheetPresented, to: nil)
            starActionPerformer.star(itemsWithIDs: ids, itemType: mailbox.itemType)
        case .unstar:
            state = state.copy(\.moreActionSheetPresented, to: nil)
            starActionPerformer.unstar(itemsWithIDs: ids, itemType: mailbox.itemType)
        case .markRead:
            state = state.copy(\.moreActionSheetPresented, to: nil)
            readActionPerformer.markAsRead(itemsWithIDs: ids, itemType: mailbox.itemType)
        case .markUnread:
            state = state.copy(\.moreActionSheetPresented, to: nil)
            readActionPerformer.markAsUnread(itemsWithIDs: ids, itemType: mailbox.itemType)
        case .permanentDelete:
            state = state.copy(\.deleteConfirmationAlert, to: .deleteConfirmation())
        default:
            break // FIXME: - Handle rest of the actions here
        }
    }

    private func fetchAvailableBottomBarActions(for ids: [ID]) {
        guard !ids.isEmpty else { return }
        Task {
            let actions = await actionsProvider.actions(forItemsWith: ids)
            Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                self?.updateActions(actions: actions)
            }))
        }
    }

    private func updateActions(actions: AllBottomBarMessageActions) {
        state = state
            .copy(\.bottomBarActions, to: actions.visibleBottomBarActions.compactMap(\.action))
            .copy(\.moreSheetOnlyActions, to: actions.hiddenBottomBarActions.compactMap(\.action))
    }
}

private extension Array where Element == BottomBarAction {

    var moreActionFiltered: Self {
        filter { $0 != .more }
    }

}
