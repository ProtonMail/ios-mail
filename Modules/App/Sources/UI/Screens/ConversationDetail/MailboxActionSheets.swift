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
    var mailbox: MailboxItemActionSheetInput?
    var labelAs: ActionSheetInput?
    var moveTo: ActionSheetInput?
}

extension View {
    @MainActor
    func actionSheetsFlow(
        mailbox: @escaping () -> Mailbox,
        state: Binding<MailboxActionSheetsState>,
        replyActions: @escaping ReplyActionsHandler,
        goBackNavigation: (() -> Void)? = nil
    ) -> some View {
        modifier(MailboxActionSheets(mailbox: mailbox, state: state, replyActions: replyActions, goBackNavigation: goBackNavigation))
    }
}

private struct MailboxActionSheets: ViewModifier {
    @Binding var state: MailboxActionSheetsState
    private let mailbox: () -> Mailbox
    private let replyActions: ReplyActionsHandler
    private let goBackNavigation: (() -> Void)?

    init(
        mailbox: @escaping () -> Mailbox,
        state: Binding<MailboxActionSheetsState>,
        replyActions: @escaping ReplyActionsHandler,
        goBackNavigation: (() -> Void)?
    ) {
        self.mailbox = mailbox
        self._state = state
        self.replyActions = replyActions
        self.goBackNavigation = goBackNavigation
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: mailboxBinding, content: mailboxItemActionPicker)
            .labelAsSheet(mailbox: mailbox, input: $state.labelAs)
            .moveToSheet(mailbox: mailbox, input: $state.moveTo)
    }

    @MainActor
    private func mailboxItemActionPicker(input: MailboxItemActionSheetInput) -> some View {
        let navigation: (MailboxItemActionSheetNavigation) -> Void = { navigation in
            switch navigation {
            case .labelAs:
                state = state
                    .copy(\.labelAs, to: .init(sheetType: .labelAs, ids: [input.id], type: input.type))
                    .copy(\.mailbox, to: nil)
            case .moveTo:
                state = state
                    .copy(\.moveTo, to: .init(sheetType: .moveTo, ids: [input.id], type: input.type))
                    .copy(\.mailbox, to: nil)
            case .dismiss:
                state = state.copy(\.mailbox, to: nil)
            case .dismissAndGoBack:
                state = state.copy(\.mailbox, to: nil)
                goBackNavigation?()
            }
        }
        return MailboxItemActionSheet(
            input: input,
            mailbox: mailbox(),
            actionsProvider: .productionInstance,
            starActionPerformerActions: .productionInstance,
            readActionPerformerActions: .productionInstance,
            deleteActions: .productionInstance,
            moveToActions: .productionInstance,
            generalActions: .productionInstance,
            replyActions: replyActions,
            mailUserSession: AppContext.shared.userSession,
            navigation: navigation
        ).pickerViewStyle([.large])
    }

    private var mailboxBinding: Binding<MailboxItemActionSheetInput?> {
        .init(get: { state.mailbox }, set: { mailbox in state = state.copy(\.mailbox, to: mailbox) })
    }

}
