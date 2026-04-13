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
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

final class ListActionsToolbarStore: StateStore {
    @Published var state: ListActionsToolbarState

    private var mailboxActionPerformers: MailboxActionPerformers
    private let starActionPerformer: StarActionPerformer
    private let toastStateStore: ToastStateStore
    private let mailUserSession: MailUserSession
    private let availableActions: AvailableListToolbarActions
    private let readActionPerformerActions: ReadActionPerformerActions
    private let deleteActions: DeleteActions
    private let moveToActions: MoveToActions

    init(
        state: ListActionsToolbarState,
        availableActions: AvailableListToolbarActions,
        starActionPerformerActions: StarActionPerformerActions,
        readActionPerformerActions: ReadActionPerformerActions,
        deleteActions: DeleteActions,
        moveToActions: MoveToActions,
        mailUserSession: MailUserSession,
        mailbox: Mailbox,
        toastStateStore: ToastStateStore
    ) {
        self.state = state
        self.availableActions = availableActions
        self.readActionPerformerActions = readActionPerformerActions
        self.deleteActions = deleteActions
        self.moveToActions = moveToActions
        self.mailboxActionPerformers = MailboxActionPerformers(
            mailbox: mailbox,
            availableActions: availableActions,
            readActionPerformerActions: readActionPerformerActions,
            deleteActions: deleteActions,
            moveToActions: moveToActions
        )
        self.starActionPerformer = .init(
            mailUserSession: mailUserSession,
            starActionPerformerActions: starActionPerformerActions
        )
        self.mailUserSession = mailUserSession
        self.toastStateStore = toastStateStore
    }

    func handle(action: ListActionsToolbarAction) async {
        switch action {
        case .listItemsSelectionUpdated(let ids):
            state = state.copy(\.selectedIds, to: ids)
            await fetchAvailableBottomBarActions(for: ids)
        case .mailboxChanged(let newMailbox):
            configureActionPerformers(with: newMailbox)
            await fetchAvailableBottomBarActions(for: state.selectedIds)
        case .actionSelected(let action, let ids):
            await handle(action: action, ids: ids)
        case .dismissLabelAsSheet:
            state = state.copy(\.labelAsSheetPresented, to: nil)
        case .dismissMoveToSheet:
            state = state.copy(\.moveToSheetPresented, to: nil)
        case .alertActionTapped(let action, let ids):
            await handle(action: action, ids: ids)
        case .editToolbarTapped:
            state = state.copy(\.isEditToolbarSheetPresented, to: true)
        }
    }

    // MARK: - Private

    private func configureActionPerformers(with mailbox: Mailbox) {
        mailboxActionPerformers = MailboxActionPerformers(
            mailbox: mailbox,
            availableActions: availableActions,
            readActionPerformerActions: readActionPerformerActions,
            deleteActions: deleteActions,
            moveToActions: moveToActions
        )
    }

    private func handle(action: ListActions, ids: [ID]) async {
        switch action {
        case .labelAs:
            state =
                state
                .copy(\.labelAsSheetPresented, to: .init(sheetType: .labelAs, ids: ids, mailboxItem: state.itemType.mailboxItem))
        case .moveTo:
            state =
                state
                .copy(\.moveToSheetPresented, to: .init(sheetType: .moveTo, ids: ids, mailboxItem: state.itemType.mailboxItem))
        case .star:
            await starActionPerformer.star(itemsWithIDs: ids, itemType: state.itemType)
            await fetchAvailableBottomBarActions(for: ids)
        case .unstar:
            await starActionPerformer.unstar(itemsWithIDs: ids, itemType: state.itemType)
            await fetchAvailableBottomBarActions(for: ids)
        case .markRead:
            await mailboxActionPerformers.readActionPerformer.markAsRead(itemsWithIDs: ids, itemType: state.itemType)
            await fetchAvailableBottomBarActions(for: ids)
        case .markUnread:
            await mailboxActionPerformers.readActionPerformer.markAsUnread(itemsWithIDs: ids, itemType: state.itemType)
            await fetchAvailableBottomBarActions(for: ids)
        case .permanentDelete:
            let alert: AlertModel = .deleteConfirmation(
                itemsCount: ids.count,
                action: { [weak self] action in
                    self?.handle(action: .alertActionTapped(action, ids: ids))
                }
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
            let undo = try await mailboxActionPerformers.moveToActionPerformer.moveTo(
                destinationID: destination.localId,
                itemsIDs: ids,
                itemType: state.itemType
            )
            let toastID = UUID()
            let undoAction = undo.undoAction(userSession: mailUserSession) { [weak self] in
                self?.toastStateStore.dismiss(withID: toastID)
            }

            handleMoveActionSuccess(to: destination, toastID: toastID, undoAction: undoAction)
        } catch {
            handleMoveActionFailure(error: error)
        }
    }

    private func handle(action: DeleteConfirmationAlertAction, ids: [ID]) async {
        state = state.copy(\.deleteConfirmationAlert, to: nil)
        switch action {
        case .delete:
            await mailboxActionPerformers.deleteActionsPerformer.delete(itemsWithIDs: ids, itemType: state.itemType)
            itemDeleted()
        case .cancel:
            break
        }
    }

    private func fetchAvailableBottomBarActions(for ids: [ID]) async {
        if ids.isEmpty {
            updateActions(actions: .init(hiddenListActions: [], visibleListActions: []))
        } else {
            let actions = await mailboxActionPerformers.actionsProvider.actions(forItemsWith: ids, itemType: state.itemType)
            updateActions(actions: actions)
        }
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
}

private struct MailboxActionPerformers {
    let actionsProvider: ListActionsToolbarActionsProvider
    let readActionPerformer: ReadActionPerformer
    let deleteActionsPerformer: DeleteActionPerformer
    let moveToActionPerformer: MoveToActionPerformer

    init(
        mailbox: Mailbox,
        availableActions: AvailableListToolbarActions,
        readActionPerformerActions: ReadActionPerformerActions,
        deleteActions: DeleteActions,
        moveToActions: MoveToActions
    ) {
        actionsProvider = .init(availableActions: availableActions, mailbox: mailbox)
        readActionPerformer = .init(mailbox: mailbox, readActionPerformerActions: readActionPerformerActions)
        deleteActionsPerformer = .init(mailbox: mailbox, deleteActions: deleteActions)
        moveToActionPerformer = .init(mailbox: mailbox, moveToActions: moveToActions)
    }
}
