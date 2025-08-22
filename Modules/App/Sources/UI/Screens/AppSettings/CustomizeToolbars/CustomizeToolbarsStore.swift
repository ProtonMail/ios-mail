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
import Combine
import InboxCoreUI
import InboxCore

@MainActor
class CustomizeToolbarsStore: StateStore {
    @Published var state: CustomizeToolbarState
    private let customizeToolbarRepository: CustomizeToolbarRepository
    private let viewModeProvider: ViewModeProvider

    init(
        state: CustomizeToolbarState,
        customizeToolbarService: CustomizeToolbarServiceProtocol,
        viewModeProvider: ViewModeProvider
    ) {
        self.state = state
        self.customizeToolbarRepository = .init(customizeToolbarService: customizeToolbarService)
        self.viewModeProvider = viewModeProvider
    }

    func handle(action: CustomizeToolbarsAction) async {
        switch action {
        case .onAppear:
            await fetchActions()
        case .editToolbarTapped(let toolbarType):
            state = state.copy(\.editToolbar, to: toolbarType)
        }
    }

    private func fetchActions() async {
        do {
            let toolbarsActions = try await customizeToolbarRepository.fetchActions()
            let viewMode = try await viewModeProvider.viewMode()
            let conversationToolbar: ToolbarWithActions =
                switch viewMode {
                case .conversations:
                    .conversation(toolbarsActions.conversation)
                case .messages:
                    .message(toolbarsActions.conversation)
                }
            state = state.copy(\.toolbars, to: [.list(toolbarsActions.list), conversationToolbar])
        } catch {
            AppLogger.log(error: error, category: .customizeToolbar)
        }
    }
}
