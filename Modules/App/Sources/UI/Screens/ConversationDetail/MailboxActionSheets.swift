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
import SwiftUI
import proton_app_uniffi

struct MailboxActionSheetsState: Copying {
    var labelAs: ActionSheetInput?
    var moveTo: ActionSheetInput?
    var snooze: ID?
    var editToolbar: ToolbarType?
}

extension View {
    func actionSheetsFlow(
        mailbox: @escaping () -> Mailbox,
        mailUserSession: MailUserSession,
        state: Binding<MailboxActionSheetsState>,
        goBackNavigation: (() -> Void)? = nil
    ) -> some View {
        modifier(
            MailboxActionSheets(
                mailbox: mailbox,
                mailUserSession: mailUserSession,
                state: state,
                goBackNavigation: goBackNavigation
            ))
    }
}

private struct MailboxActionSheets: ViewModifier {
    @Binding var state: MailboxActionSheetsState
    private let mailbox: () -> Mailbox
    private let mailUserSession: MailUserSession
    private let goBackNavigation: (() -> Void)?

    init(
        mailbox: @escaping () -> Mailbox,
        mailUserSession: MailUserSession,
        state: Binding<MailboxActionSheetsState>,
        goBackNavigation: (() -> Void)?
    ) {
        self.mailbox = mailbox
        self.mailUserSession = mailUserSession
        self._state = state
        self.goBackNavigation = goBackNavigation
    }

    func body(content: Content) -> some View {
        content
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
