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

import DesignSystem
import Foundation
import proton_app_uniffi
import SwiftUI

class MoveToSheetModel: ObservableObject {
    @Published var state: MoveToState = .initial

    private let input: LabelAsActionSheetInput
    private let moveToActionsProvider: MoveToActionsProvider
    private let navigation: (MoveToSheetNavigation) -> Void

    init(
        input: LabelAsActionSheetInput,
        mailbox: Mailbox,
        availableMoveToActions: AvailableMoveToActions,
        navigation: @escaping (MoveToSheetNavigation) -> Void
    ) {
        self.input = input
        self.moveToActionsProvider = .init(mailbox: mailbox, availableMoveToActions: availableMoveToActions)
        self.navigation = navigation
    }

    func handle(action: MoveToSheetAction) {
        switch action {
        case .viewAppear:
            loadMoveToActions()
        case .folderTapped(let id):
            navigation(.dismiss)
        case .createFolderTapped:
            navigation(.createFolder)
        }
    }

    // MARK: - Private

    private func loadMoveToActions() {
        Task {
            let actions = await moveToActionsProvider.actions(for: input.type, ids: input.ids)
            let state = MoveToState(
                moveToSystemFolderActions: actions.compactMap(\.moveToSystemFolder),
                moveToCustomFolderActions: actions.compactMap(\.moveToCustomFolder)
            )
            Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                self?.state = state
            }))
        }
    }
}

private extension MoveAction {

    var moveToSystemFolder: MoveToSystemFolder? {
        guard case .systemFolder(let model) = self else {
            return nil
        }
        return .init(id: model.localId, label: model.name, isSelected: model.isSelected)
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
        .init(moveToSystemFolderActions: [], moveToCustomFolderActions: [])
    }
}
