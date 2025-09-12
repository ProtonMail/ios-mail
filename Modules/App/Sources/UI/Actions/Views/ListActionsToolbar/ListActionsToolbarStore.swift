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

@MainActor
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

    func handle(action: ListActionsToolbarAction) async {
        switch action {
        case .listItemsSelectionUpdated(let ids):
            await fetchAvailableBottomBarActions(for: ids)
        case .actionSelected(let action, let ids):
            await handle(action: action, ids: ids)
        case .dismissLabelAsSheet:
            state = state.copy(\.labelAsSheetPresented, to: nil)
        case .dismissMoveToSheet:
            state = state.copy(\.moveToSheetPresented, to: nil)
        case .moreSheetAction(let action, let ids):
            await handle(action: action, ids: ids)
        case .alertActionTapped(let action, let ids):
            await handle(action: action, ids: ids, itemType: itemTypeForActionBar)
        case .editToolbarTapped:
            state = state.copy(\.isEditToolbarSheetPresented, to: true)
        }
    }

    // MARK: - Private

    private func handle(action: ListActions, ids: [ID]) async {
        switch action {
        case .labelAs:
            state =
                state
                .copy(\.labelAsSheetPresented, to: .init(sheetType: .labelAs, ids: ids, mailboxItem: itemTypeForActionBar.mailboxItem))
        case .moveTo:
            state =
                state
                .copy(\.moveToSheetPresented, to: .init(sheetType: .moveTo, ids: ids, mailboxItem: itemTypeForActionBar.mailboxItem))
        case .star:
            await starActionPerformer.star(itemsWithIDs: ids, itemType: itemTypeForActionBar)
        case .unstar:
            await starActionPerformer.unstar(itemsWithIDs: ids, itemType: itemTypeForActionBar)
        case .markRead:
            await readActionPerformer.markAsRead(itemsWithIDs: ids, itemType: itemTypeForActionBar)
        case .markUnread:
            await readActionPerformer.markAsUnread(itemsWithIDs: ids, itemType: itemTypeForActionBar)
        case .permanentDelete:
            let alert: AlertModel = .deleteConfirmation(
                itemsCount: ids.count,
                action: { [weak self] action in self?.handle(action: .alertActionTapped(action, ids: ids)) }
            )
            state = state.copy(\.deleteConfirmationAlert, to: alert)
        case .moveToSystemFolder(let model), .notSpam(let model):
            await performMoveToAction(destination: model, ids: ids)
        case .snooze:
            state = state.copy(\.isSnoozeSheetPresented, to: true)
        case .more:
            break
        }
    }

    private func performMoveToAction(destination: MovableSystemFolderAction, ids: [ID]) async {
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

            handleMoveActionSuccess(to: destination, toastID: toastID, undoAction: undoAction)
        } catch {
            handleMoveActionFailure(error: error)
        }
    }

    private func handle(action: DeleteConfirmationAlertAction, ids: [ID], itemType: MailboxItemType) async {
        state =
            state
            .copy(\.deleteConfirmationAlert, to: nil)
        switch action {
        case .delete:
            await deleteActionsPerformer.delete(itemsWithIDs: ids, itemType: itemType)
            itemDeleted()
        case .cancel:
            break
        }
    }

    private func fetchAvailableBottomBarActions(for ids: [ID]) async {
        guard !ids.isEmpty else { return }

        let actions = await actionsProvider.actions(forItemsWith: ids)
        updateActions(actions: actions)
    }

    private func updateActions(actions: AllListActions) {
        state =
            state
            .copy(\.bottomBarActions, to: actions.visibleListActions)
            .copy(\.moreSheetOnlyActions, to: actions.hiddenListActions)
    }

    private func itemDeleted() {
        toastStateStore.present(toast: .deleted())
    }

    private func handleMoveActionSuccess(
        to destination: MovableSystemFolderAction,
        toastID: UUID,
        undoAction: (() async -> Void)?
    ) {
        let destinationName = destination.name.displayData.title.string
        let toast: Toast = .moveTo(id: toastID, destinationName: destinationName, undoAction: undoAction)
        toastStateStore.present(toast: toast)
    }

    private func handleMoveActionFailure(error: Error) {
        toastStateStore.present(toast: .error(message: error.localizedDescription))
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
