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

struct MessageActionsSheet: View {
    private let state: MessageActionsSheetState
    private let mailbox: Mailbox
    private let mailUserSession: MailUserSession
    private let service: AllAvailableMessageActionsForActionSheetService
    private let actionTapped: (MessageAction) -> Void

    @Environment(\.messageAppearanceOverrideStore) var messageAppearanceOverrideStore
    @Environment(\.colorScheme) var colorScheme

    init(
        state: MessageActionsSheetState,
        mailbox: Mailbox,
        mailUserSession: MailUserSession,
        service: @escaping AllAvailableMessageActionsForActionSheetService = allAvailableMessageActionsForActionSheet,
        actionTapped: @escaping (MessageAction) -> Void,
    ) {
        self.state = state
        self.mailbox = mailbox
        self.mailUserSession = mailUserSession
        self.service = service
        self.actionTapped = actionTapped
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
            ClosableScreen {
                ScrollView {
                    VStack(spacing: DS.Spacing.standard) {
                        horizontalSection(actions: store.state.actions.replyActions, store: store)
                        verticalSection(actions: store.state.actions.messageActions, store: store)
                        verticalSection(actions: store.state.actions.moveActions, store: store)
                        verticalSection(actions: store.state.actions.generalActions, store: store)

                        if state.isEditToolbarVisible {
                            EditToolbarSheetSection {
                                store.handle(action: .editToolbarTapped)
                            }
                        }
                    }
                    .padding(.all, DS.Spacing.large)
                }
                .background(DS.Color.BackgroundInverted.norm)
                .navigationTitle(store.state.title)
                .navigationBarTitleDisplayMode(.inline)
            }
            .onLoad {
                store.handle(action: .colorSchemeChanged(colorScheme))
                store.handle(action: .onLoad)
            }
            .onChange(of: colorScheme) { _, newValue in
                store.handle(action: .colorSchemeChanged(newValue))
            }
            .sheet(isPresented: store.binding(\.isEditToolbarPresented)) {
                EditToolbarScreen(state: .initial(toolbarType: .message), customizeToolbarService: mailUserSession)
            }
        }
    }

    private func horizontalSection(actions: [MessageAction], store: MessageActionsSheetStore) -> some View {
        HStack(spacing: DS.Spacing.standard) {
            ForEach(actions, id: \.self) { action in
                horizontalButton(action: action, store: store)
            }
        }
    }

    private func verticalSection(actions: [MessageAction], store: MessageActionsSheetStore) -> some View {
        ActionSheetVerticalSection(actions: actions) { action in
            store.handle(action: .actionTapped(action))
        }
    }

    private func horizontalButton(action: MessageAction, store: MessageActionsSheetStore) -> some View {
        Button(action: { store.handle(action: .actionTapped(action)) }) {
            VStack(spacing: DS.Spacing.standard) {
                action.displayData.image
                    .square(size: 24)
                    .foregroundStyle(DS.Color.Icon.norm)
                Text(action.displayData.title)
                    .font(.body)
                    .foregroundStyle(DS.Color.Text.norm)
            }
            .frame(height: 84)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(RegularButtonStyle())
        .background(DS.Color.BackgroundInverted.secondary)
        .clipShape(.rect(cornerRadius: DS.Radius.extraLarge))
    }
}
