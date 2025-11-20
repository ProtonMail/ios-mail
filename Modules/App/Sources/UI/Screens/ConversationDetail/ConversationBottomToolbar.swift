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

import InboxDesignSystem
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

extension View {

    func conversationBottomToolbar(
        actions: ConversationToolbarActions?,
        mailbox: @escaping () -> Mailbox,
        messageAppearanceOverrideStore: MessageAppearanceOverrideStore,
        editToolbarTapped: @escaping (ToolbarType) -> Void,
        messageActionSelected: @escaping (MessageAction) -> Void,
        conversationActionSelected: @escaping (ConversationAction) -> Void
    ) -> some View {
        modifier(
            ConversationToolbarModifier(
                actions: actions,
                mailbox: mailbox,
                messageAppearanceOverrideStore: messageAppearanceOverrideStore,
                editToolbarTapped: editToolbarTapped,
                messageActionSelected: messageActionSelected,
                conversationActionSelected: conversationActionSelected
            )
        )
    }

}

struct ConversationToolbarModifier: ViewModifier {
    @EnvironmentObject private var toastStateStore: ToastStateStore

    private let actions: ConversationToolbarActions?
    private let mailbox: () -> Mailbox
    private let messageAppearanceOverrideStore: MessageAppearanceOverrideStore
    private let editToolbarTapped: (ToolbarType) -> Void
    private let messageActionSelected: (MessageAction) -> Void
    private let conversationActionSelected: (ConversationAction) -> Void

    init(
        actions: ConversationToolbarActions?,
        mailbox: @escaping () -> Mailbox,
        messageAppearanceOverrideStore: MessageAppearanceOverrideStore,
        editToolbarTapped: @escaping (ToolbarType) -> Void,
        messageActionSelected: @escaping (MessageAction) -> Void,
        conversationActionSelected: @escaping (ConversationAction) -> Void
    ) {
        self.actions = actions
        self.mailbox = mailbox
        self.messageAppearanceOverrideStore = messageAppearanceOverrideStore
        self.editToolbarTapped = editToolbarTapped
        self.messageActionSelected = messageActionSelected
        self.conversationActionSelected = conversationActionSelected
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    if let actions {
                        switch actions {
                        case .message(let actions, let messageID):
                            messageToolbarContent(
                                messageID: messageID,
                                actions: actions.visibleMessageActions,
                            )
                            .id(actions)
                        case .conversation(let actions, let conversationID):
                            conversationToolbarContent(
                                conversationID: conversationID,
                                actions: actions.visibleListActions
                            )
                            .id(actions)
                        }
                    }
                }
            }
    }

    private func messageToolbarContent(messageID: ID, actions: [MessageAction]) -> some View {
        toolbarContent(actions: actions, selected: messageActionSelected) {
            MessageActionsMenu(
                state: .initial(messageID: messageID, showEditToolbar: true),
                mailbox: mailbox(),
                messageAppearanceOverrideStore: messageAppearanceOverrideStore,
                actionTapped: messageActionSelected,
                editToolbarTapped: { editToolbarTapped(.message) }
            ) {
                InternalAction.more.displayData.image
                    .foregroundStyle(DS.Color.Icon.weak)
            }
        }
    }

    private func conversationToolbarContent(conversationID: ID, actions: [ConversationAction]) -> some View {
        toolbarContent(actions: actions, selected: conversationActionSelected) {
            ConversationActionsMenu(
                conversationID: conversationID,
                mailbox: mailbox(),
                actionTapped: conversationActionSelected,
                editToolbarTapped: { editToolbarTapped(.conversation) }
            ) {
                InternalAction.more.displayData.image
                    .foregroundStyle(DS.Color.Icon.weak)
            }
        }
    }

    private func toolbarContent<MoreActionsMenu: View, Action: DisplayableAction>(
        actions: [Action],
        selected: @escaping (Action) -> Void,
        moreActionsMenu: @escaping () -> MoreActionsMenu
    ) -> some View {
        HStack(alignment: .center) {
            ForEachEnumerated(actions, id: \.offset) { action, index in
                if index == 0 {
                    Spacer()
                }
                if action.isMoreAction {
                    moreActionsMenu()
                } else {
                    Button(action: { selected(action) }) {
                        action.displayData.image
                            .foregroundStyle(DS.Color.Icon.weak)
                    }
                }
                Spacer()
            }
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { toolbarHeight in
            let bottomSafeAreaToRecreate = DS.Spacing.large
            toastStateStore.state.bottomBar.height = toolbarHeight + bottomSafeAreaToRecreate
        }
        .onAppear {
            toastStateStore.state.bottomBar.isVisible = true
        }
        .onDisappear {
            toastStateStore.state.bottomBar.isVisible = false
        }
    }

}
