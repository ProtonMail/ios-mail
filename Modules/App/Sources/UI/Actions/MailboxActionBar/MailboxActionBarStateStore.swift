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

final class MailboxActionBarStateStore: ObservableObject {
    @Published var state: MailboxActionBarState
    private let actionsProvider: MailboxActionBarActionsProvider
    private let starActionPerformer: StarActionPerformer

    init(
        state: MailboxActionBarState,
        availableActions: AvailableMailboxActionBarActions,
        starActionPerformerActions: StarActionPerformerActions,
        mailUserSession: MailUserSession
    ) {
        self.state = state
        self.actionsProvider = .init(availableActions: availableActions)
        self.starActionPerformer = .init(
            mailUserSession: mailUserSession,
            starActionPerformerActions: starActionPerformerActions
        )
    }

    func handle(action: MailboxActionBarAction) {
        switch action {
        case .mailboxItemsSelectionUpdated(let ids, let mailbox, let itemType):
            fetchAvailableBottomBarActions(for: ids, mailbox: mailbox, itemType: itemType)
        case .actionSelected(let action, let ids, let mailbox, let itemType):
            handle(action: action, ids: ids, mailbox: mailbox, itemType: itemType)
        case .dismissLabelAsSheet:
            state = state.copy(\.labelAsSheetPresented, to: nil)
        case .dismissMoveToSheet:
            state = state.copy(\.moveToSheetPresented, to: nil)
        case .moreSheetAction(let action, let ids, let mailbox, let itemType):
            state = state.copy(\.moreActionSheetPresented, to: nil)
            handle(action: action, ids: ids, mailbox: mailbox, itemType: itemType)
        }
    }

    // MARK: - Private

    private func handle(action: BottomBarAction, ids: [ID], mailbox: Mailbox, itemType: MailboxItemType) {
        switch action {
        case .more:
            let moreActionSheetState = MailboxActionBarMoreSheetState(
                selectedItemsIDs: ids,
                bottomBarActions: state.bottomBarActions.moreActionFiltered,
                moreSheetOnlyActions: state.moreSheetOnlyActions
            )
            state = state.copy(\.moreActionSheetPresented, to: moreActionSheetState)
        case .labelAs:
            state = state.copy(\.labelAsSheetPresented, to: .init(ids: ids, type: itemType))
        case .moveTo:
            state = state.copy(\.moveToSheetPresented, to: .init(ids: ids, type: itemType))
        case .star:
            starActionPerformer.star(itemsWithIDs: ids, itemType: itemType)
        case .unstar:
            starActionPerformer.unstar(itemsWithIDs: ids, itemType: itemType)
        default:
            break // FIXME: - Handle rest of the actions here
        }
    }

    private func fetchAvailableBottomBarActions(for ids: [ID], mailbox: Mailbox, itemType: MailboxItemType) {
        guard !ids.isEmpty else { return }
        Task {
            let actions = await actionsProvider.actions(for: mailbox, ids: ids, itemType: itemType)
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
