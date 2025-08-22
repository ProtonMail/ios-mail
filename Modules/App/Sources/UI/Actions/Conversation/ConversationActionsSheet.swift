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
    private let mailUserSession: MailUserSession
    private let actionTapped: (ConversationAction) -> Void

    @State var actions: ConversationActionSheet?
    @State var isEditToolbarPresented = false

    init(
        conversationID: ID,
        title: String,
        mailbox: Mailbox,
        mailUserSession: MailUserSession,
        actionTapped: @escaping (ConversationAction) -> Void
    ) {
        self.conversationID = conversationID
        self.title = title
        self.mailbox = mailbox
        self.mailUserSession = mailUserSession
        self.actionTapped = actionTapped
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: DS.Spacing.standard) {
                    if let actions {
                        verticalSection(actions: actions.conversationActions)
                        verticalSection(actions: actions.moveActions)
                    }

                    EditToolbarSheetSection {
                        Task { await handle(action: .editToolbarTapped) }
                    }
                }
                .padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.BackgroundInverted.norm)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onLoad { Task { await handle(action: .onLoad) } }
        .sheet(isPresented: $isEditToolbarPresented) {
            EditToolbarScreen(
                state: .initial(toolbarType: .conversation),
                customizeToolbarService: mailUserSession
            )
        }
    }

    private func verticalSection(actions: [ConversationAction]) -> some View {
        ActionSheetVerticalSection(actions: actions) { action in
            Task {
                await handle(action: .actionTapped(action))
            }
        }
    }

    private func handle(action: ConversationActionsSheetAction) async {
        switch action {
        case .onLoad:
            await loadActions()
        case .actionTapped(let action):
            actionTapped(action)
        case .editToolbarTapped:
            isEditToolbarPresented = true
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
