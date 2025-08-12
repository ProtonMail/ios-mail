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
import InboxCoreUI
import InboxCore

@MainActor
class CustomizeToolbarsStore: StateStore {
    @Published var state: CustomizeToolbarState
    private let toolbarService: ToolbarServiceProtocol

    init(state: CustomizeToolbarState, toolbarService: ToolbarServiceProtocol) {
        self.state = state
        self.toolbarService = toolbarService
    }

    func handle(action: CustomizeToolbarsAction) async {
        switch action {
        case .onLoad:
            await fetchActions()
        case .editListToolbar:
            break
        case .editConversationToolbar:
            break
        }
    }

    private func fetchActions() async {
        do {
            let actions = try await toolbarService.customizeToolbarActions()
            state = .init(
                list: actions.list.selected.map { actionType in .action(actionType) } + [.editActions],
                conversation: actions.conversation.selected.map { actionType in .action(actionType) } + [.editActions]
            )
        } catch {
            AppLogger.log(error: error, category: .customizeToolbar)
        }
    }
}
