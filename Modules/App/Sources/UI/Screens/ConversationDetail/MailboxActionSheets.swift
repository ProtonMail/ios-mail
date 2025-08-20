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
import proton_app_uniffi
import SwiftUI

struct MailboxActionSheetsState: Copying {
    var message: MessageActionsSheetInput?
    var conversation: ConversationActionsSheetInput?
    var labelAs: ActionSheetInput?
    var moveTo: ActionSheetInput?
    var snooze: ID?
}

extension View {
    @MainActor
    func actionSheetsFlow(
        mailbox: @escaping () -> Mailbox,
        mailUserSession: MailUserSession,
        state: Binding<MailboxActionSheetsState>,
        messageActionSelected: @escaping (MessageAction, ID) -> Void,
        conversationActionSelected: @escaping (ConversationAction) -> Void,
        goBackNavigation: (() -> Void)? = nil
    ) -> some View {
        modifier(
            MailboxActionSheets(
                mailbox: mailbox,
                mailUserSession: mailUserSession,
                state: state,
                messageActionSelected: messageActionSelected,
                conversationActionSelected: conversationActionSelected,
                goBackNavigation: goBackNavigation
            ))
    }
}

private struct MailboxActionSheets: ViewModifier {
    @Binding var state: MailboxActionSheetsState
    private let mailbox: () -> Mailbox
    private let mailUserSession: MailUserSession
    private let goBackNavigation: (() -> Void)?
    private let messageActionSelected: (MessageAction, ID) -> Void
    private let conversationActionSelected: (ConversationAction) -> Void

    init(
        mailbox: @escaping () -> Mailbox,
        mailUserSession: MailUserSession,
        state: Binding<MailboxActionSheetsState>,
        messageActionSelected: @escaping (MessageAction, ID) -> Void,
        conversationActionSelected: @escaping (ConversationAction) -> Void,
        goBackNavigation: (() -> Void)?
    ) {
        self.mailbox = mailbox
        self.mailUserSession = mailUserSession
        self._state = state
        self.conversationActionSelected = conversationActionSelected
        self.messageActionSelected = messageActionSelected
        self.goBackNavigation = goBackNavigation
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: $state.message) { input in
                MessageActionsSheet(
                    messageID: input.id,
                    title: input.title,
                    mailbox: mailbox(),
                    actionSelected: { messageActionSelected($0, input.id) }
                )
            }
            .sheet(item: $state.conversation) { input in
                ConversationActionsSheet(
                    conversationID: input.id,
                    title: input.title,
                    mailbox: mailbox(),
                    actionSelected: { conversationActionSelected($0) }
                )
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

//    @MainActor
//    private func mailboxItemActionPicker(input: MailboxItemActionSheetInput) -> some View {
//        let navigation: (MailboxItemActionSheetNavigation) -> Void = { navigation in
//            switch navigation {
//            case .labelAs:
//                state =
//                    state
//                    .copy(\.labelAs, to: .init(sheetType: .labelAs, ids: [input.id], type: input.type))
//                    .copy(\.message, to: nil)
//            case .moveTo:
//                state =
//                    state
//                    .copy(\.moveTo, to: .init(sheetType: .moveTo, ids: [input.id], type: input.type))
//                    .copy(\.message, to: nil)
//            case .dismiss:
//                state = state.copy(\.mailbox, to: nil)
//            case .dismissAndGoBack:
//                state = state.copy(\.mailbox, to: nil)
//                goBackNavigation?()
//            case .snooze:
//                state =
//                    state
//                    .copy(\.mailbox, to: nil)
//                    .copy(\.snooze, to: input.id)
//            }
//        }
//        return MailboxItemActionSheet(
//            input: input,
//            mailbox: mailbox(),
//            actionsProvider: .productionInstance,
//            starActionPerformerActions: .productionInstance,
//            readActionPerformerActions: .productionInstance,
//            deleteActions: .productionInstance,
//            moveToActions: .productionInstance,
//            generalActions: .productionInstance,
//            replyActions: replyActions,
//            mailUserSession: AppContext.shared.userSession,
//            navigation: navigation
//        ).pickerViewStyle([.large])
//    }
//
//    private var mailboxBinding: Binding<MailboxItemActionSheetInput?> {
//        .init(get: { state.mailbox }, set: { mailbox in state = state.copy(\.mailbox, to: mailbox) })
//    }

    private var snoozeBinding: Binding<ID?> {
        .init(get: { state.snooze }, set: { id in state = state.copy(\.snooze, to: id) })
    }

}
