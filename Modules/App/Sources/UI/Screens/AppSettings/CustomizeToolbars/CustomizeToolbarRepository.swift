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

import proton_app_uniffi

struct CustomizeToolbarRepository: Sendable {
    private let customizeToolbarService: CustomizeToolbarServiceProtocol

    init(customizeToolbarService: CustomizeToolbarServiceProtocol) {
        self.customizeToolbarService = customizeToolbarService
    }

    func fetchActions() async throws -> ToolbarsActions {
        .init(
            list: try await actions(for: .list),
            message: try await actions(for: .message),
            conversation: try await actions(for: .conversation)
        )
    }

    func save(actions: [MobileAction], for toolbar: ToolbarType) async throws {
        try await customizeToolbarService.saveActions(for: toolbar)(actions)
    }

    private func actions(for toolbarType: ToolbarType) async throws -> CustomizeToolbarActions {
        let allActions = customizeToolbarService.allActions(for: toolbarType)
        let selectedActions = try await customizeToolbarService.selectedActions(for: toolbarType)
        return .init(
            selected: selectedActions,
            unselected: allActions.filter { action in !selectedActions.contains(action) }
        )
    }
}

private extension CustomizeToolbarServiceProtocol {

    func allActions(for toolbar: ToolbarType) -> [MobileAction] {
        switch toolbar {
        case .list:
            getAllListActions()
        case .message:
            getAllMessageActions()
        case .conversation:
            getAllConversationActions()
        }
    }

    func selectedActions(for toolbar: ToolbarType) async throws(ActionError) -> [MobileAction] {
        switch toolbar {
        case .list:
            try await getListToolbarActions()
        case .message:
            try await getMessageToolbarActions()
        case .conversation:
            try await getConversationToolbarActions()
        }
    }

    func saveActions(for toolbar: ToolbarType) -> ([MobileAction]) async throws -> Void {
        switch toolbar {
        case .list:
            updateListToolbarActions
        case .message:
            updateMessageToolbarActions
        case .conversation:
            updateConversationToolbarActions
        }
    }

}
