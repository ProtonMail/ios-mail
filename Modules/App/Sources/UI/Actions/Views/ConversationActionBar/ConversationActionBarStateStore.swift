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
import proton_app_uniffi
import SwiftUI

class ConversationActionBarStateStore: ObservableObject {
    @Published var state: [BottomBarAction] = []

    private let conversationID: ID
    private let bottomBarConversationActionsProvider: ConversationBottomBarActionsProvider
    private let mailbox: Mailbox
    private let handleAction: (BottomBarAction) -> Void

    init(
        conversationID: ID,
        bottomBarConversationActionsProvider: @escaping ConversationBottomBarActionsProvider,
        mailbox: Mailbox,
        handleAction: @escaping (BottomBarAction) -> Void
    ) {
        self.conversationID = conversationID
        self.bottomBarConversationActionsProvider = bottomBarConversationActionsProvider
        self.mailbox = mailbox
        self.handleAction = handleAction
    }

    func handle(action: ConversationActionBarAction) {
        switch action {
        case .onLoad:
            fetchActions()
        case .actionSelected(let action):
            handleAction(action)
        }
    }

    // MARK: - Private

    private func fetchActions() {
        Task {
            let actions = try! await bottomBarConversationActionsProvider(mailbox, [conversationID])
                .get()
                .visibleBottomBarActions
                .compactMap(\.action)
            Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                self?.state = actions
            }))
        }
    }
}
