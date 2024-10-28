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
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

class MoveToSheetModel: ObservableObject {
    @Published var state: MoveToState = .initial

    private let input: ActionSheetInput
    private let moveToActionsProvider: MoveToActionsProvider
    private let dismiss: () -> Void

    init(
        input: ActionSheetInput,
        mailbox: Mailbox,
        availableMoveToActions: AvailableMoveToActions,
        dismiss: @escaping () -> Void
    ) {
        self.input = input
        self.moveToActionsProvider = .init(mailbox: mailbox, availableMoveToActions: availableMoveToActions)
        self.dismiss = dismiss
    }

    func handle(action: MoveToSheetAction) {
        switch action {
        case .viewAppear:
            loadMoveToActions()
        case .folderTapped:
            dismiss()
        case .createFolderTapped:
            state = state.copy(\.createFolderLabelPresented, to: true)
        }
    }

    // MARK: - Private

    private func loadMoveToActions() {
        Task {
            let actions = await moveToActionsProvider.actions(for: input.type, ids: input.ids)
            Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                self?.update(moveToActions: actions)
            }))
        }
    }

    private func update(moveToActions: [MoveAction]) {
        state = state
            .copy(\.moveToSystemFolderActions, to: moveToActions.compactMap(\.moveToSystemFolder))
            .copy(\.moveToCustomFolderActions, to: moveToActions.compactMap(\.moveToCustomFolder))
    }
}

private extension MoveAction {

    var moveToSystemFolder: MoveToSystemFolder? {
        guard case .systemFolder(let model) = self else {
            return nil
        }
        return .init(id: model.localId, label: model.name.moveToSystemFolderLabel, isSelected: model.isSelected)
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
            isSelected: isSelected,
            children: children.map(\.moveToCustomFolder)
        )
    }

}

private extension MoveToState {
    static var initial: Self {
        .init(moveToSystemFolderActions: [], moveToCustomFolderActions: [], createFolderLabelPresented: false)
    }
}
