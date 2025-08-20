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
    private let messageID: ID
    private let mailbox: Mailbox
    private let title: String
    private let actionSelected: (MessageAction) -> Void
    @Environment(\.messageAppearanceOverrideStore) var messageAppearanceOverrideStore
    @Environment(\.colorScheme) var colorScheme

    @State var actions: MessageActionSheet?

    init(messageID: ID, title: String, mailbox: Mailbox, actionSelected: @escaping (MessageAction) -> Void) {
        self.messageID = messageID
        self.title = title
        self.mailbox = mailbox
        self.actionSelected = actionSelected
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: DS.Spacing.standard) {
                    if let actions {
                        horizontalSection(actions: actions.replyActions)
                        verticalSection(actions: actions.messageActions)
                        verticalSection(actions: actions.moveActions)
                        verticalSection(actions: actions.generalActions)
                    }
                }
                .padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.BackgroundInverted.norm)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }.onLoad { Task { await handle(action: .onLoad) } }
    }

    private func horizontalSection(actions: [MessageAction]) -> some View {
        HStack(spacing: DS.Spacing.standard) {
            ForEach(actions, id: \.self) { action in
                horizontalButton(action: action)
            }
        }
    }

    private func verticalSection(actions: [MessageAction]) -> some View {
        ActionSheetSection {
            ForEachLast(collection: actions) { action, isLast in
                ActionSheetImageButton(
                    displayData: action.displayData,
                    displayBottomSeparator: !isLast,
                    action: {
                        Task {
                            await handle(action: .actionSelected(action))
                        }
                    }
                )
            }
        }
    }

    private func horizontalButton(action: MessageAction) -> some View {
        Button(action: { Task { await handle(action: .actionSelected(action)) } }) {
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

    private func loadActions() async {
        let isForcingLightMode = messageAppearanceOverrideStore!.isForcingLightMode(forMessageWithId: messageID)
        let themeOpts = ThemeOpts(colorScheme: colorScheme, isForcingLightMode: isForcingLightMode)
        do {
            actions = try await availableMessageActionSheet(
                mailbox: mailbox,
                theme: themeOpts,
                messageId: messageID
            ).get()
        } catch {
            AppLogger.log(error: error, category: .conversationDetail)
        }
    }

    func handle(action: MessageActionsSheetAction) async {
        switch action {
        case .onLoad:
            await loadActions()
        case .actionSelected(let action):
            actionSelected(action)
        }
    }
}
