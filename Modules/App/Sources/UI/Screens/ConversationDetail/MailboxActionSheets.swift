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
    func actionSheetsFlow(
        mailbox: @escaping () -> Mailbox,
        state: Binding<MailboxActionSheetsState>,
        goBackNavigation: (() -> Void)? = nil
    ) -> some View {
        modifier(MailboxActionSheets(mailbox: mailbox, state: state, goBackNavigation: goBackNavigation))
    }
}

private struct MailboxActionSheets: ViewModifier {
    @Binding var state: MailboxActionSheetsState
    private let mailbox: () -> Mailbox
    private let goBackNavigation: (() -> Void)?

    init(
        mailbox: @escaping () -> Mailbox, 
        state: Binding<MailboxActionSheetsState>,
        goBackNavigation: (() -> Void)?
    ) {
        self.mailbox = mailbox
        self._state = state
        self.goBackNavigation = goBackNavigation
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: mailboxBinding, content: mailboxItemActionPicker)
            .sheet(item: labelAsBinding, content: labelAsActionPicker)
            .sheet(item: moveToBinding, content: moveToActionPicker)
    }

    @MainActor
    private func mailboxItemActionPicker(input: MailboxItemActionSheetInput) -> some View {
        let navigation: (MailboxItemActionSheetNavigation) -> Void = { navigation in
            switch navigation {
            case .labelAs:
                state = state
                    .copy(\.labelAs, to: .init(ids: input.ids, type: input.type))
                    .copy(\.mailbox, to: nil)
            case .moveTo:
                state = state
                    .copy(\.moveTo, to: .init(ids: input.ids, type: input.type))
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
            mailUserSession: AppContext.shared.userSession,
            navigation: navigation
        ).pickerViewStyle([.large])
    }

    @MainActor
    private func labelAsActionPicker(input: ActionSheetInput) -> some View {
        let model = LabelAsSheetModel(
            input: input,
            mailbox: mailbox(),
            availableLabelAsActions: .productionInstance, 
            labelAsActions: .productionInstance
        ) {
            state = state.dismissed()
        }
        return LabelAsSheet(model: model)
    }

    @MainActor
    private func moveToActionPicker(input: ActionSheetInput) -> some View {
        MoveToSheet(
            input: input,
            mailbox: mailbox(),
            availableMoveToActions: .productionInstance,
            moveToActions: .productionInstance
        ) { navigation in
            state = state.dismissed()
            switch navigation {
            case .dismissAndGoBack:
                goBackNavigation?()
            case .dismiss:
                break
            }
        }
    }

    private var mailboxBinding: Binding<MailboxItemActionSheetInput?> {
        .init(get: { state.mailbox }, set: { mailbox in state = state.copy(\.mailbox, to: mailbox) })
    }

    private var labelAsBinding: Binding<ActionSheetInput?> {
        .init(get: { state.labelAs }, set: { labelAs in state = state.copy(\.labelAs, to: labelAs) })
    }

    private var moveToBinding: Binding<ActionSheetInput?> {
        .init(get: { state.moveTo }, set: { moveTo in state = state.copy(\.moveTo, to: moveTo) })
    }

}

extension MailboxActionSheetsState {
    func dismissed() -> Self {
        .init(mailbox: nil, labelAs: nil, moveTo: nil)
    }
}
