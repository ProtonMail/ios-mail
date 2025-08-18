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
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

final class ListActionsToolbarStore: StateStore {
    @Published var state: ListActionsToolbarState

    private let actionsProvider: ListActionsToolbarActionsProvider
    private let starActionPerformer: StarActionPerformer
    private let readActionPerformer: ReadActionPerformer
    private let deleteActionsPerformer: DeleteActionPerformer
    private let moveToActionPerformer: MoveToActionPerformer
    private let itemTypeForActionBar: MailboxItemType
    private let toastStateStore: ToastStateStore
    private let mailUserSession: MailUserSession

    init(
        state: ListActionsToolbarState,
        availableActions: AvailableListToolbarActions,
        starActionPerformerActions: StarActionPerformerActions,
        readActionPerformerActions: ReadActionPerformerActions,
        deleteActions: DeleteActions,
        moveToActions: MoveToActions,
        itemTypeForActionBar: MailboxItemType,
        mailUserSession: MailUserSession,
        mailbox: Mailbox,
        toastStateStore: ToastStateStore
    ) {
        self.state = state
        self.itemTypeForActionBar = itemTypeForActionBar
        self.actionsProvider = .init(
            availableActions: availableActions,
            itemTypeForActionBar: itemTypeForActionBar,
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
        self.moveToActionPerformer = .init(mailbox: mailbox, moveToActions: moveToActions)
        self.mailUserSession = mailUserSession
        self.toastStateStore = toastStateStore
    }

    func handle(action: ListActionsToolbarAction) {
        switch action {
        case .listItemsSelectionUpdated(let ids):
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
            handle(action: action, ids: ids, itemType: itemTypeForActionBar)
        }
    }

    // MARK: - Private

    private func handle(action: ListActions, ids: [ID]) {
        switch action {
        case .more:
            let moreActionSheetState = ListActionsToolbarMoreSheetState(
                selectedItemsIDs: ids,
                bottomBarActions: state.bottomBarActions.moreActionFiltered,
                moreSheetOnlyActions: state.moreSheetOnlyActions
            )
            state =
                state
                .copy(\.moreActionSheetPresented, to: moreActionSheetState)
        case .labelAs:
            dismissMoreActionSheet()
            state =
                state
                .copy(\.labelAsSheetPresented, to: .init(sheetType: .labelAs, ids: ids, type: itemTypeForActionBar.actionSheetItemType))
        case .moveTo:
            dismissMoreActionSheet()
            state =
                state
                .copy(\.moveToSheetPresented, to: .init(sheetType: .moveTo, ids: ids, type: itemTypeForActionBar.actionSheetItemType))
        case .star:
            dismissMoreActionSheet()
            starActionPerformer.star(itemsWithIDs: ids, itemType: itemTypeForActionBar)
        case .unstar:
            dismissMoreActionSheet()
            starActionPerformer.unstar(itemsWithIDs: ids, itemType: itemTypeForActionBar)
        case .markRead:
            dismissMoreActionSheet()
            readActionPerformer.markAsRead(itemsWithIDs: ids, itemType: itemTypeForActionBar)
        case .markUnread:
            dismissMoreActionSheet()
            readActionPerformer.markAsUnread(itemsWithIDs: ids, itemType: itemTypeForActionBar)
        case .permanentDelete:
            let keyPath: WritableKeyPath<ListActionsToolbarState, AlertModel?> =
                state.moreActionSheetPresented != nil ? \.moreDeleteConfirmationAlert : \.deleteConfirmationAlert
            let alert: AlertModel = .deleteConfirmation(
                itemsCount: ids.count,
                action: { [weak self] action in self?.handle(action: .alertActionTapped(action, ids: ids)) }
            )
            state = state.copy(keyPath, to: alert)
        case .moveToSystemFolder(let model), .notSpam(let model):
            performMoveToAction(destination: model, ids: ids)
        case .snooze:
            dismissMoreActionSheet()
            state = state.copy(\.isSnoozeSheetPresented, to: true)
        }
    }

    private func performMoveToAction(destination: MovableSystemFolderAction, ids: [ID]) {
        Task { [weak self, mailUserSession] in
            guard let self else { return }
            do {
                let undo = try await moveToActionPerformer.moveTo(
                    destinationID: destination.localId,
                    itemsIDs: ids,
                    itemType: itemTypeForActionBar
                )
                let toastID = UUID()
                let undoAction = undo.undoAction(userSession: mailUserSession) {
                    self.dismissToast(withID: toastID)
                }

                Dispatcher.dispatchOnMain(
                    .init {
                        self.handleMoveActionSuccess(to: destination, toastID: toastID, undoAction: undoAction)
                    })
            } catch {
                Dispatcher.dispatchOnMain(
                    .init {
                        self.handleMoveActionFailure(error: error)
                    })
            }
        }
    }

    private func handle(action: DeleteConfirmationAlertAction, ids: [ID], itemType: MailboxItemType) {
        state =
            state
            .copy(\.deleteConfirmationAlert, to: nil)
            .copy(\.moreDeleteConfirmationAlert, to: nil)
        switch action {
        case .delete:
            Task {
                await deleteActionsPerformer.delete(itemsWithIDs: ids, itemType: itemType)
                Dispatcher.dispatchOnMain(
                    .init(block: { [weak self] in
                        self?.itemDeleted()
                    }))
            }
        case .cancel:
            break
        }
    }

    private func fetchAvailableBottomBarActions(for ids: [ID]) {
        guard !ids.isEmpty else { return }
        Task {
            let actions = await actionsProvider.actions(forItemsWith: ids)
            Dispatcher.dispatchOnMain(
                .init(block: { [weak self] in
                    self?.updateActions(actions: actions)
                }))
        }
    }

    private func updateActions(actions: AllListActions) {
        state =
            state
            .copy(\.bottomBarActions, to: actions.visibleListActions)
            .copy(\.moreSheetOnlyActions, to: actions.hiddenListActions)
    }

    private func dismissMoreActionSheet() {
        state = state.copy(\.moreActionSheetPresented, to: nil)
    }

    private func itemDeleted() {
        toastStateStore.present(toast: .deleted())
        dismissMoreActionSheet()
    }

    private func handleMoveActionSuccess(
        to destination: MovableSystemFolderAction,
        toastID: UUID,
        undoAction: (() -> Void)?
    ) {
        let destinationName = destination.name.humanReadable.string
        let toast: Toast = .moveTo(id: toastID, destinationName: destinationName, undoAction: undoAction)
        toastStateStore.present(toast: toast)
        dismissMoreActionSheet()
    }

    private func handleMoveActionFailure(error: Error) {
        toastStateStore.present(toast: .error(message: error.localizedDescription))
        dismissMoreActionSheet()
    }

    private func dismissToast(withID toastID: UUID) {
        Dispatcher.dispatchOnMain(
            .init(block: { [weak self] in
                self?.toastStateStore.dismiss(withID: toastID)
            }))
    }
}

private extension Array where Element == ListActions {

    var moreActionFiltered: Self {
        filter { $0 != .more }
    }

}
