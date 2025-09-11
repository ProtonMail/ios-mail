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

struct MessageActionsMenu<OpenMenuButtonContent: View>: View {
    private let state: MessageActionsSheetState
    private let mailbox: Mailbox
    private let mailUserSession: MailUserSession
    private let service: AllAvailableMessageActionsForActionSheetService
    private let actionTapped: (MessageAction) -> Void
    private let editToolbarTapped: () -> Void
    private let label: () -> OpenMenuButtonContent

    @Environment(\.messageAppearanceOverrideStore) var messageAppearanceOverrideStore
    @Environment(\.colorScheme) var colorScheme

    init(
        state: MessageActionsSheetState,
        mailbox: Mailbox,
        mailUserSession: MailUserSession,
        service: @escaping AllAvailableMessageActionsForActionSheetService = allAvailableMessageActionsForActionSheet,
        actionTapped: @escaping (MessageAction) -> Void,
        editToolbarTapped: @escaping () -> Void,
        label: @escaping () -> OpenMenuButtonContent
    ) {
        self.state = state
        self.mailbox = mailbox
        self.mailUserSession = mailUserSession
        self.service = service
        self.actionTapped = actionTapped
        self.editToolbarTapped = editToolbarTapped
        self.label = label
    }

    var body: some View {
        StoreView(
            store: MessageActionsSheetStore(
                state: state,
                mailbox: mailbox,
                messageAppearanceOverrideStore: messageAppearanceOverrideStore!,
                service: service,
                actionTapped: actionTapped
            )
        ) { state, store in
            Menu {
                Group {
                    if store.state.actions.replyActions.isEmpty {
                        Text("")
                    } else {
                        horizontalSection(actions: store.state.actions.replyActions, store: store)
                        verticalSection(actions: store.state.actions.messageActions, store: store)
                        verticalSection(actions: store.state.actions.moveActions, store: store)
                        Menu {
                            verticalSection(actions: store.state.actions.generalActions, store: store)
                            if state.showEditToolbar {
                                Section {
                                    Button {
                                        editToolbarTapped()
                                    } label: {
                                        Label {
                                            Text(L10n.Action.editToolbar)
                                                .font(.body)
                                                .foregroundStyle(DS.Color.Text.norm)
                                        } icon: {
                                            DS.Icon.icMagicWand.image
                                                .square(size: 24)
                                                .foregroundStyle(DS.Color.Icon.norm)
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text("More options")
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
    private func horizontalSection(actions: [MessageAction], store: MessageActionsSheetStore) -> some View {
        ControlGroup {
            ForEach(actions, id: \.self) { action in
                menuButton(action: action, store: store)
            }
        }
    }

    @ViewBuilder
    private func verticalSection(actions: [MessageAction], store: MessageActionsSheetStore) -> some View {
        Section {
            ForEach(actions, id: \.self) { action in
                menuButton(action: action, store: store)
            }
        }
    }

    private func menuButton(action: MessageAction, store: MessageActionsSheetStore) -> some View {
        Button {
            store.handle(action: .actionTapped(action))
        } label: {
            Label {
                Text(action.displayData.title)
                    .font(.body)
                    .foregroundStyle(DS.Color.Text.norm)
            } icon: {
                action.displayData.image
                    .square(size: 24)
                    .foregroundStyle(DS.Color.Icon.norm)
            }
        }
    }
}
