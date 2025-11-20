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

import InboxCore
import InboxCoreUI
import SwiftUI
import proton_app_uniffi

@MainActor
class MessageActionsMenuStore: StateStore {
    @Published var state: MessageActionsMenuState

    private let mailbox: Mailbox
    private let service: AllAvailableMessageActionsForActionSheetService
    private let actionTapped: (MessageAction) -> Void
    private let messageAppearanceOverrideStore: MessageAppearanceOverrideStore

    init(
        state: MessageActionsMenuState,
        mailbox: Mailbox,
        messageAppearanceOverrideStore: MessageAppearanceOverrideStore,
        service: @escaping AllAvailableMessageActionsForActionSheetService,
        actionTapped: @escaping (MessageAction) -> Void,
    ) {
        self.state = state
        self.mailbox = mailbox
        self.messageAppearanceOverrideStore = messageAppearanceOverrideStore
        self.service = service
        self.actionTapped = actionTapped
    }

    func handle(action: MessageActionsMenuAction) async {
        switch action {
        case .onLoad:
            await loadActions()
        case .actionTapped(let action):
            actionTapped(action)
        case .colorSchemeChanged(let colorScheme):
            state = state.copy(\.colorScheme, to: colorScheme)
        }
    }

    private func loadActions() async {
        let isForcingLightMode = messageAppearanceOverrideStore.isForcingLightMode(forMessageWithId: state.messageID)
        let themeOpts = ThemeOpts(colorScheme: state.colorScheme, isForcingLightMode: isForcingLightMode)
        do {
            let actions = try await service(mailbox, themeOpts, state.messageID).get()
            state = state.copy(\.actions, to: actions)
        } catch {
            AppLogger.log(error: error, category: .conversationDetail)
        }
    }
}
