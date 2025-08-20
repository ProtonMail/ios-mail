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
import InboxCore
import InboxCoreUI
import InboxDesignSystem
import SwiftUI

extension View {

    func conversationBottomToolbar(
        actions: ConversationToolbarActions?,
        messageActionSelected: @escaping (MessageAction) -> Void,
        conversationActionSelected: @escaping (ConversationAction) -> Void
    ) -> some View {
        modifier(
            ConversationToolbarModifier(
                actions: actions,
                messageActionSelected: messageActionSelected,
                conversationActionSelected: conversationActionSelected
            ))
    }

}

struct ConversationToolbarModifier: ViewModifier {
    private let actions: ConversationToolbarActions?
    private let messageActionSelected: (MessageAction) -> Void
    private let conversationActionSelected: (ConversationAction) -> Void

    init(
        actions: ConversationToolbarActions?,
        messageActionSelected: @escaping (MessageAction) -> Void,
        conversationActionSelected: @escaping (ConversationAction) -> Void
    ) {
        self.actions = actions
        self.messageActionSelected = messageActionSelected
        self.conversationActionSelected = conversationActionSelected
    }

    func body(content: Content) -> some View {
        if let actions {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        switch actions {
                        case .message(let actions):
                            toolbarContent(actions: actions.visibleMessageActions, selected: messageActionSelected)
                        case .conversation(let actions):
                            toolbarContent(actions: actions.visibleListActions, selected: conversationActionSelected)
                        }
                    }
                }
        } else {
            content
        }
    }

    @ViewBuilder
    private func toolbarContent<Action: DisplayableAction>(
        actions: [Action],
        selected: @escaping (Action) -> Void
    ) -> some View {
        HStack(alignment: .center) {
            ForEachEnumerated(actions, id: \.offset) { action, index in
                if index == 0 {
                    Spacer()
                }
                Button(action: { selected(action) }) {
                    action.displayData.image
                        .foregroundStyle(DS.Color.Icon.weak)
                }
                Spacer()
            }
        }
    }

}
