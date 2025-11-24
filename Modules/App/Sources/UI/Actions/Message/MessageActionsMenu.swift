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

struct MessageActionsMenu<OpenMenuButtonContent: View>: View {
    private let state: MessageActionsMenuState
    private let mailbox: Mailbox
    private let messageAppearanceOverrideStore: MessageAppearanceOverrideStore
    private let service: AllAvailableMessageActionsForActionSheetService
    private let actionTapped: (MessageAction) async -> Void
    private let editToolbarTapped: () -> Void
    private let label: () -> OpenMenuButtonContent

    @Environment(\.colorScheme) var colorScheme

    init(
        state: MessageActionsMenuState,
        mailbox: Mailbox,
        messageAppearanceOverrideStore: MessageAppearanceOverrideStore,
        service: @escaping AllAvailableMessageActionsForActionSheetService = allAvailableMessageActionsForActionSheet,
        actionTapped: @escaping (MessageAction) async -> Void,
        editToolbarTapped: @escaping () -> Void,
        label: @escaping () -> OpenMenuButtonContent
    ) {
        self.state = state
        self.mailbox = mailbox
        self.messageAppearanceOverrideStore = messageAppearanceOverrideStore
        self.service = service
        self.actionTapped = actionTapped
        self.editToolbarTapped = editToolbarTapped
        self.label = label
    }

    var body: some View {
        StoreView(
            store: MessageActionsMenuStore(
                state: state,
                mailbox: mailbox,
                messageAppearanceOverrideStore: messageAppearanceOverrideStore,
                service: service,
                actionTapped: actionTapped
            )
        ) { state, store in
            Menu {
                Group {
                    if store.state.actions.isEmpty {
                        // Workaround to ensure the menu is displayed after dynamic actions are loaded.
                        // Without this, the menu will not be presented.
                        Text(String.empty.notLocalized)
                    } else {
                        horizontalSection(actions: store.state.actions.replyActions, store: store)
                        verticalSection(actions: store.state.actions.messageActions, store: store)
                        verticalSection(actions: store.state.actions.moveActions, store: store)
                        Menu {
                            verticalSection(actions: store.state.actions.generalActions, store: store)
                            if state.showEditToolbar {
                                Section {
                                    ActionMenuButton(
                                        displayData: InternalAction.editToolbar.displayData,
                                        action: editToolbarTapped
                                    )
                                }
                            }
                        } label: {
                            Text(L10n.Action.moreOptions)
                        }
                    }
                }
                .onLoad {
                    store.handle(action: .colorSchemeChanged(colorScheme))
                    store.handle(action: .onLoad)
                }
                .onChange(of: colorScheme) { _, newValue in
                    store.handle(action: .colorSchemeChanged(newValue))
                }
            } label: {
                label()
            }
        }
    }

    @ViewBuilder
    private func horizontalSection(actions: [MessageAction], store: MessageActionsMenuStore) -> some View {
        ControlGroup {
            ForEach(actions, id: \.self) { action in
                ActionMenuButton(displayData: action.displayData) {
                    store.handle(action: .actionTapped(action))
                }
            }
        }
    }

    @ViewBuilder
    private func verticalSection(actions: [MessageAction], store: MessageActionsMenuStore) -> some View {
        Section {
            ForEach(actions, id: \.self) { action in
                ActionMenuButton(displayData: action.displayData) {
                    store.handle(action: .actionTapped(action))
                }
            }
        }
    }
}

extension MessageActionSheet {

    var isEmpty: Bool {
        replyActions.isEmpty && generalActions.isEmpty && messageActions.isEmpty && moveActions.isEmpty
    }

}
