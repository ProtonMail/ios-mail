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
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

struct MailboxActionSheetsState: Copying {
    var message: MessageActionsSheetInput?
    var conversation: ConversationActionsSheetInput?
    var labelAs: ActionSheetInput?
    var moveTo: ActionSheetInput?
    var snooze: ID?
    var alert: AlertModel?
}

extension View {
    @MainActor
    func actionSheetsFlow(
        mailbox: @escaping () -> Mailbox,
        mailUserSession: MailUserSession,
        state: Binding<MailboxActionSheetsState>,
        messageActionTapped: @escaping (MessageAction, ID) -> Void,
        conversationActionTapped: @escaping (ConversationAction) -> Void,
        goBackNavigation: (() -> Void)? = nil
    ) -> some View {
        modifier(
            MailboxActionSheets(
                mailbox: mailbox,
                mailUserSession: mailUserSession,
                state: state,
                messageActionTapped: messageActionTapped,
                conversationActionTapped: conversationActionTapped,
                goBackNavigation: goBackNavigation
            ))
    }
}

private struct MailboxActionSheets: ViewModifier {
    @Binding var state: MailboxActionSheetsState
    private let mailbox: () -> Mailbox
    private let mailUserSession: MailUserSession
    private let goBackNavigation: (() -> Void)?
    private let messageActionTapped: (MessageAction, ID) -> Void
    private let conversationActionTapped: (ConversationAction) -> Void

    init(
        mailbox: @escaping () -> Mailbox,
        mailUserSession: MailUserSession,
        state: Binding<MailboxActionSheetsState>,
        messageActionTapped: @escaping (MessageAction, ID) -> Void,
        conversationActionTapped: @escaping (ConversationAction) -> Void,
        goBackNavigation: (() -> Void)?
    ) {
        self.mailbox = mailbox
        self.mailUserSession = mailUserSession
        self._state = state
        self.conversationActionTapped = conversationActionTapped
        self.messageActionTapped = messageActionTapped
        self.goBackNavigation = goBackNavigation
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: $state.message) { input in
                MessageActionsSheet(
                    state: .initial(
                        messageID: input.id,
                        title: input.title,
                        isEditToolbarVisible: input.origin.isEditToolbarVisible
                    ),
                    mailbox: mailbox(),
                    mailUserSession: mailUserSession,
                    actionTapped: { messageActionTapped($0, input.id) }
                )
                .alert(model: $state.alert)
            }
            .sheet(item: $state.conversation) { input in
                ConversationActionsSheet(
                    conversationID: input.id,
                    title: input.title,
                    mailbox: mailbox(),
                    mailUserSession: mailUserSession,
                    actionTapped: { conversationActionTapped($0) }
                )
                .alert(model: $state.alert)
            }
            .sheet(item: snoozeBinding) { conversationID in
                SnoozeView(
                    state: .initial(
                        screen: .main,
                        labelId: mailbox().labelId(),
                        conversationIDs: [conversationID]
                    ))
            }
            .labelAsSheet(mailbox: mailbox, mailUserSession: mailUserSession, input: $state.labelAs)
            .moveToSheet(
                mailbox: mailbox,
                mailUserSession: mailUserSession,
                input: $state.moveTo,
                navigation: { navigation in
                    state.moveTo = nil
                    switch navigation {
                    case .dismiss:
                        break
                    case .dismissAndGoBack:
                        goBackNavigation?()
                    }
                })
    }

    private var snoozeBinding: Binding<ID?> {
        .init(get: { state.snooze }, set: { id in state = state.copy(\.snooze, to: id) })
    }

}

extension MailboxActionSheetsState {

    static var allSheetsDismissed: Self {
        .init()
    }

}
