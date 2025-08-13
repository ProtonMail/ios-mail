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
import InboxCore
import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

class MoveToSheetStateStore: StateStore {
    @Published var state: MoveToState = .initial

    private let input: ActionSheetInput
    private let moveToActionsProvider: MoveToActionsProvider
    private let toastStateStore: ToastStateStore
    private let moveToActionPerformer: MoveToActionPerformer
    private let navigation: (MoveToSheetNavigation) -> Void
    private let mailUserSession: MailUserSession

    init(
        input: ActionSheetInput,
        mailbox: Mailbox,
        availableMoveToActions: AvailableMoveToActions,
        toastStateStore: ToastStateStore,
        moveToActions: MoveToActions,
        navigation: @escaping (MoveToSheetNavigation) -> Void,
        mailUserSession: MailUserSession
    ) {
        self.input = input
        self.moveToActionsProvider = .init(mailbox: mailbox, availableMoveToActions: availableMoveToActions)
        self.toastStateStore = toastStateStore
        self.moveToActionPerformer = .init(mailbox: mailbox, moveToActions: moveToActions)
        self.navigation = navigation
        self.mailUserSession = mailUserSession
    }

    func handle(action: MoveToSheetAction) {
        switch action {
        case .viewAppear:
            loadMoveToActions()
        case .customFolderTapped(let customFolder):
            moveTo(destinationID: customFolder.id, destinationName: customFolder.name)
        case .systemFolderTapped(let systemFolder):
            moveTo(destinationID: systemFolder.id, destinationName: systemFolder.label.humanReadable.string)
        case .createFolderTapped:
            state = state.copy(\.createFolderLabelPresented, to: true)
        }
    }

    // MARK: - Private

    private func moveTo(destinationID: ID, destinationName: String) {
        Task { [weak self, mailUserSession] in
            guard let self else { return }

            do {
                let undo = try await moveToActionPerformer.moveTo(
                    destinationID: destinationID,
                    itemsIDs: input.ids,
                    itemType: input.type.inboxItemType
                )
                let toastID = UUID()
                let undoAction = undo.undoAction(userSession: mailUserSession) {
                    self.toastStateStore.dismiss(withID: toastID)
                }
                let toast: Toast = .moveTo(id: toastID, destinationName: destinationName, undoAction: undoAction)
                dismissSheet(presentingToast: toast)
            } catch {
                dismissSheet(presentingToast: .error(message: error.localizedDescription))
            }
        }
    }

    private func dismissSheet(presentingToast toast: Toast) {
        Dispatcher.dispatchOnMain(
            .init { [weak self, input] in
                self?.toastStateStore.present(toast: toast)
                self?.navigation(input.type.navigation)
            })
    }

    private func loadMoveToActions() {
        Task {
            let actions = await moveToActionsProvider.actions(for: input.type.inboxItemType, ids: input.ids)
            Dispatcher.dispatchOnMain(
                .init(block: { [weak self] in
                    self?.update(moveToActions: actions)
                }))
        }
    }

    private func update(moveToActions: [MoveAction]) {
        state =
            state
            .copy(\.moveToSystemFolderActions, to: moveToActions.compactMap(\.moveToSystemFolder))
            .copy(\.moveToCustomFolderActions, to: moveToActions.compactMap(\.moveToCustomFolder))
    }
}

private extension ActionSheetItemType {

    var navigation: MoveToSheetNavigation {
        switch self {
        case .conversation:
            .dismissAndGoBack
        case .message(let isStandaloneMessage):
            isStandaloneMessage ? .dismissAndGoBack : .dismiss
        }
    }

}

private extension MoveAction {

    var moveToSystemFolder: MoveToSystemFolder? {
        guard case .systemFolder(let model) = self else {
            return nil
        }
        return .init(id: model.localId, label: model.name)
    }

    var moveToCustomFolder: MoveToCustomFolder? {
        guard case .customFolder(let model) = self else {
            return nil
        }
        return model.moveToCustomFolder
    }

}

private extension CustomFolderAction {

    var moveToCustomFolder: MoveToCustomFolder {
        .init(
            id: localId,
            name: name,
            color: color.map { hexColor in Color(hex: hexColor.value) } ?? DS.Color.Icon.norm,
            children: children.map(\.moveToCustomFolder)
        )
    }

}

private extension MoveToState {
    static var initial: Self {
        .init(moveToSystemFolderActions: [], moveToCustomFolderActions: [], createFolderLabelPresented: false)
    }
}
