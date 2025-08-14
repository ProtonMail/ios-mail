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

@MainActor
class EditToolbarStore: StateStore {
    @Published var state: EditToolbarState
    private let toolbarService: ToolbarServiceProtocol

    init(state: EditToolbarState, toolbarService: ToolbarServiceProtocol) {
        self.state = state
        self.toolbarService = toolbarService
    }

    func handle(action: EditToolbarAction) async {
        switch action {
        case .actionsReordered(let fromOffsets, let toOffset):
            var selectedActionsNewOrder = state.toolbarActions.selected
            selectedActionsNewOrder.move(fromOffsets: fromOffsets, toOffset: toOffset)

            state =
                state
                .copy(\.toolbarActions.selected, to: selectedActionsNewOrder)
        case .removeFromSelectedTapped(let actionToRemove):
            let selectedList = state.toolbarActions.selected.removing(actionToRemove)
            let unselectedList = state.toolbarActions.unselected.inserting(actionToRemove, at: 0)

            state =
                state
                .copy(\.toolbarActions, to: .init(selected: selectedList, unselected: unselectedList))
        case .addToSelectedTapped(let actionToAdd):
            let unselectedList = state.toolbarActions.unselected.removing(actionToAdd)
            let selectedList = state.toolbarActions.selected.inserting(actionToAdd, at: 0)

            state =
                state
                .copy(\.toolbarActions, to: .init(selected: selectedList, unselected: unselectedList))
        case .onLoad:
            do {
                let actions = try await toolbarService.customizeToolbarActions()[keyPath: state.screenType.actionsKeyPath]
                state = state.copy(\.toolbarActions, to: actions)
            } catch {
                AppLogger.log(error: error, category: .customizeToolbar)
            }
        case .resetToOriginalTapped, .saveTapped, .cancelTapped:
            break
        }
    }
}

private extension RangeReplaceableCollection where Element: Equatable {

    func removing(_ item: Element) -> Self {
        var copy = self
        if let index = copy.firstIndex(of: item) {
            copy.remove(at: index)
        }
        return copy
    }

    func inserting(_ item: Element, at index: Index) -> Self {
        var copy = self
        copy.insert(item, at: index)
        return copy
    }

}

extension EditToolbarState.ScreenType {

    var actionsKeyPath: KeyPath<CustomizeToolbarActions, ToolbarActions> {
        switch self {
        case .list:
            \.list
        case .message:
            fatalError("To implement")
        case .conversation:
            \.conversation
        }
    }

}
