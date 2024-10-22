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

import SwiftUI
import proton_app_uniffi

class MailboxActionBarStateStore: ObservableObject {
    @Published var state: MailboxActionBarState
    private let actionsProvider: MailboxActionBarActionsProvider

    init(
        state: MailboxActionBarState,
        availableActions: AvailableMailboxActionBarActions
    ) {
        self.state = state
        self.actionsProvider = .init(availableActions: availableActions)
    }

    func handle(action: MailboxActionBarAction) {
        switch action {
        case .mailboxItemsSelectionUpdated(let ids, let mailbox):
            fetchAvailableBottomBarActions(for: ids, mailbox: mailbox)
        case .actionSelected(let action, let ids, let mailbox):
            handle(action: action, ids: ids, mailbox: mailbox)
        case .dismissLabelAsSheet:
            state = state.copy(\.labelAsSheetPresented, to: nil)
        case .dismissMoveToSheet:
            state = state.copy(\.moveToSheetPresented, to: nil)
        case .moreSheetAction(let action, let ids, let mailbox):
            state = state.copy(\.moreActionSheetPresented, to: nil)
            handle(action: action, ids: ids, mailbox: mailbox)
        }
    }

    // MARK: - Private

    private func handle(action: BottomBarAction, ids: Set<ID>, mailbox: Mailbox) {
        switch action {
        case .more:
            let moreActionSheetState = MailboxActionBarMoreSheetState(
                selectedItemsIDs: ids,
                visibleActions: state.visibleActions.filter { $0 != .more }, // FIXME: - Move to extension
                hiddenActions: state.moreActions
            )
            state = state.copy(\.moreActionSheetPresented, to: moreActionSheetState)
        case .labelAs:
            state = state.copy(\.labelAsSheetPresented, to: .init(ids: Array(ids), type: mailbox.viewMode().itemType))
        case .moveTo:
            state = state.copy(\.moveToSheetPresented, to: .init(ids: Array(ids), type: mailbox.viewMode().itemType))
        default:
            break // FIXME: - Handle rest of the actions
        }
    }

    private func fetchAvailableBottomBarActions(for ids: Set<ID>, mailbox: Mailbox) {
        guard !ids.isEmpty else { return }
        Task {
            let actions = await actionsProvider.actions(for: mailbox, ids: Array(ids))
            Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                self?.updateActions(actions: actions)
            }))
        }
    }

    private func updateActions(actions: AllBottomBarMessageActions) {
        state = state
            .copy(\.visibleActions, to: actions.visibleBottomBarActions.compactMap(\.action))
            .copy(\.moreActions, to: actions.hiddenBottomBarActions.compactMap(\.action))
    }
}
