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
import InboxDesignSystem
import InboxCore
import InboxCoreUI
import SwiftUI

struct ConversationActionsSheet: View {
    private let conversationID: ID
    private let title: String
    private let mailbox: Mailbox
    private let actionSelected: (ConversationAction) -> Void

    @State var actions: ConversationActionSheet?

    init(conversationID: ID, title: String, mailbox: Mailbox, actionSelected: @escaping (ConversationAction) -> Void) {
        self.conversationID = conversationID
        self.title = title
        self.mailbox = mailbox
        self.actionSelected = actionSelected
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: DS.Spacing.standard) {
                    if let actions {
                        verticalSection(actions: actions.conversationActions)
                        verticalSection(actions: actions.moveActions)
                    }
                }
                .padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.BackgroundInverted.norm)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }.onLoad { Task { await handle(action: .onLoad) } }
    }

    private func verticalSection(actions: [ConversationAction]) -> some View { // FIXME: - Get rid of duplication
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

    private func handle(action: ConversationActionsSheetAction) async {
        switch action {
        case .onLoad:
            await loadActions()
        case .actionSelected(let action):
            actionSelected(action)
        }
    }

    @MainActor
    private func loadActions() async {
        do {
            actions = try await allAvailableConversationActionsForActionSheet(
                mailbox: mailbox,
                conversationId: conversationID
            ).get()
        } catch {
            AppLogger.log(error: error, category: .conversationDetail)
        }
    }
}
