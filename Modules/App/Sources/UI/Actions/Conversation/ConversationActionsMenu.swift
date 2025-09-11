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

struct ConversationActionsMenu<OpenMenuButtonContent: View>: View {
    private let conversationID: ID
    private let mailbox: Mailbox
    private let mailUserSession: MailUserSession
    private let actionTapped: (ConversationAction) -> Void
    private let editToolbarTapped: () -> Void
    private let label: () -> OpenMenuButtonContent

    @State var actions: ConversationActionSheet?
    @State var isEditToolbarPresented = false

    init(
        conversationID: ID,
        mailbox: Mailbox,
        mailUserSession: MailUserSession,
        actionTapped: @escaping (ConversationAction) -> Void,
        editToolbarTapped: @escaping () -> Void,
        label: @escaping () -> OpenMenuButtonContent
    ) {
        self.conversationID = conversationID
        self.mailbox = mailbox
        self.mailUserSession = mailUserSession
        self.actionTapped = actionTapped
        self.editToolbarTapped = editToolbarTapped
        self.label = label
    }

    var body: some View {
        Menu {
            Group {
                if let actions {
                    Section {
                        menuButton(
                            displayData: InternalAction.editToolbar.displayData,
                            action: editToolbarTapped
                        )
                    }
                    verticalSection(actions: actions.moveActions)
                    verticalSection(actions: actions.conversationActions)

                } else {
                    Text("")  // FIXME: - Add some kind of loading indication
                }
            }
            .onLoad { Task { await handle(action: .onLoad) } }
        } label: {
            label()
        }
    }

    private func verticalSection(actions: [ConversationAction]) -> some View {
        Section {
            ForEach(actions, id: \.self) { action in
                menuButton(displayData: action.displayData) {
                    Task {
                        await handle(action: .actionTapped(action))
                    }
                }
            }
        }
    }

    private func menuButton(displayData: ActionDisplayData, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Label {
                Text(displayData.title)
                    .font(.body)
                    .foregroundStyle(DS.Color.Text.norm)
            } icon: {
                displayData.image
                    .square(size: 24)
                    .foregroundStyle(DS.Color.Icon.norm)
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
