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

import Combine
import InboxCore
import InboxCoreUI

class EditToolbarStore: StateStore {
    @Published var state: EditToolbarState
    private let customizeToolbarRepository: CustomizeToolbarRepository
    private let refreshToolbarNotifier: RefreshToolbarNotifier
    private let dismiss: () -> Void

    init(
        state: EditToolbarState,
        customizeToolbarService: CustomizeToolbarServiceProtocol,
        refreshToolbarNotifier: RefreshToolbarNotifier,
        dismiss: @escaping () -> Void
    ) {
        self.state = state
        self.customizeToolbarRepository = .init(customizeToolbarService: customizeToolbarService)
        self.refreshToolbarNotifier = refreshToolbarNotifier
        self.dismiss = dismiss
    }

    func handle(action: EditToolbarAction) async {
        switch action {
        case .actionsReordered(let fromOffsets, let toOffset):
            var selectedActionsNewOrder = state.toolbarActions.current.selected
            selectedActionsNewOrder.move(fromOffsets: fromOffsets, toOffset: toOffset)

            state =
                state
                .copy(\.toolbarActions.current.selected, to: selectedActionsNewOrder)
        case .removeFromSelectedTapped(let actionToRemove):
            let selectedList = state.toolbarActions.current.selected.removing(actionToRemove)
            let unselectedList = state.toolbarActions.current.unselected.inserting(actionToRemove, at: 0)

            state =
                state
                .copy(
                    \.toolbarActions.current,
                    to: .init(selected: selectedList, unselected: unselectedList)
                )
        case .addToSelectedTapped(let actionToAdd):
            let unselectedList = state.toolbarActions.current.unselected.removing(actionToAdd)
            let selectedList = state.toolbarActions.current.selected.inserting(actionToAdd, at: 0)

            state =
                state
                .copy(
                    \.toolbarActions.current,
                    to: .init(selected: selectedList, unselected: unselectedList))
        case .onLoad:
            do {
                let actions =
                    try await customizeToolbarRepository.fetchActions()[
                        keyPath: state.toolbarType.actionsKeyPath
                    ]
                state = state.copy(\.toolbarActions, to: actions)
            } catch {
                AppLogger.log(error: error, category: .customizeToolbar)
            }
        case .saveTapped:
            do {
                try await customizeToolbarRepository.save(
                    actions: state.toolbarActions.current.selected,
                    for: state.toolbarType
                )
                refreshToolbarNotifier.refresh(toolbar: state.toolbarType)
            } catch {
                AppLogger.log(error: error, category: .customizeToolbar)
            }
            dismiss()
        case .resetToOriginalTapped:
            state = state.copy(\.toolbarActions.current, to: state.toolbarActions.defaultActions)
        case .cancelTapped:
            dismiss()
        }
    }
}

private extension ToolbarType {
    var actionsKeyPath: KeyPath<ToolbarsActions, AllCustomizeToolbarActions> {
        switch self {
        case .list:
            \.list
        case .message:
            \.message
        case .conversation:
            \.conversation
        }
    }
}
