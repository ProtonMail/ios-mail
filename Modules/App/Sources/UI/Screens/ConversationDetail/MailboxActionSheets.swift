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

import SwiftUI
import proton_app_uniffi

struct MailboxActionSheetsState {
    let mailbox: MailboxItemActionSheetInput?
    let labelAs: LabelAsActionSheetInput?
    let moveTo: LabelAsActionSheetInput?
    let isCreateLabelScreenPresented: Bool
}

extension View {
    func actionSheetsFlow(mailbox: @escaping () -> Mailbox, state: Binding<MailboxActionSheetsState>) -> some View {
        modifier(MailboxActionSheets(mailbox: mailbox, state: state))
    }
}

private struct MailboxActionSheets: ViewModifier {
    @Binding var state: MailboxActionSheetsState
    private let mailbox: () -> Mailbox

    init(mailbox: @escaping () -> Mailbox, state: Binding<MailboxActionSheetsState>) {
        self.mailbox = mailbox
        self._state = state
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: mailboxBinding, content: mailboxItemActionPicker)
            .sheet(item: labelAsBinding, content: labelAsActionPicker)
            .sheet(item: moveToBinding, content: moveToActionPicker)
    }

    @MainActor private func mailboxItemActionPicker(input: MailboxItemActionSheetInput) -> some View {
        let model = MailboxItemActionSheetModel(
            input: input,
            mailbox: mailbox(),
            actionsProvider: .productionInstance
        ) { navigation in
            switch navigation {
            case .labelAs:
                state = state
                    .copy(labelAs: .init(ids: input.ids, type: input.type))
                    .copy(mailbox: nil)
            case .moveTo:
                state = state
                    .copy(moveTo: .init(ids: input.ids, type: input.type))
                    .copy(mailbox: nil)
            }
        }
        return MailboxItemActionSheet(model: model)
            .pickerViewStyle([.large])
    }

    @MainActor private func labelAsActionPicker(input: LabelAsActionSheetInput) -> some View {
        let model = LabelAsSheetModel(
            input: input,
            mailbox: mailbox(),
            availableLabelAsActions: .productionInstance
        ) { navigation in
            switch navigation {
            case .dismiss:
                state = state.dismissed()
            case .createLabel:
                state = state.copy(isCreateLabelScreenPresented: true)
            }
        }
        return LabelAsSheet(model: model)
            .sheet(isPresented: isCreateLabelScreenPresentedBinding) {
                CreateFolderOrLabelScreen()
            }
    }

    @MainActor private func moveToActionPicker(input: LabelAsActionSheetInput) -> some View {
        let model = MoveToSheetModel(
            input: input,
            mailbox: mailbox(),
            availableMoveToActions: .productionInstance
        ) { navigation in
            switch navigation {
            case .createFolder:
                state = state.copy(isCreateLabelScreenPresented: true)
            case .dismiss:
                state = state.dismissed()
            }
        }
        return MoveToSheet(model: model)
            .sheet(isPresented: isCreateLabelScreenPresentedBinding) {
                CreateFolderOrLabelScreen()
            }
    }

    private var mailboxBinding: Binding<MailboxItemActionSheetInput?> {
        .init(get: { state.mailbox }, set: { mailbox in state = state.copy(mailbox: mailbox) })
    }

    private var labelAsBinding: Binding<LabelAsActionSheetInput?> {
        .init(get: { state.labelAs }, set: { labelAs in state = state.copy(labelAs: labelAs) })
    }

    private var moveToBinding: Binding<LabelAsActionSheetInput?> {
        .init(get: { state.moveTo }, set: { moveTo in state = state.copy(moveTo: moveTo) })
    }

    private var isCreateLabelScreenPresentedBinding: Binding<Bool> {
        .init(
            get: { state.isCreateLabelScreenPresented },
            set: { isPresented in state = state.copy(isCreateLabelScreenPresented: isPresented) }
        )
    }

}

extension MailboxActionSheetsState {
    func copy(mailbox: MailboxItemActionSheetInput?) -> Self {
        .init(
            mailbox: mailbox,
            labelAs: labelAs,
            moveTo: moveTo,
            isCreateLabelScreenPresented: isCreateLabelScreenPresented
        )
    }

    func copy(labelAs: LabelAsActionSheetInput?) -> Self {
        .init(
            mailbox: mailbox,
            labelAs: labelAs,
            moveTo: moveTo,
            isCreateLabelScreenPresented: isCreateLabelScreenPresented
        )
    }

    func copy(isCreateLabelScreenPresented: Bool) -> Self {
        .init(
            mailbox: mailbox,
            labelAs: labelAs,
            moveTo: moveTo,
            isCreateLabelScreenPresented: isCreateLabelScreenPresented
        )
    }

    func copy(moveTo: LabelAsActionSheetInput?) -> Self {
        .init(
            mailbox: mailbox,
            labelAs: labelAs,
            moveTo: moveTo,
            isCreateLabelScreenPresented: isCreateLabelScreenPresented
        )
    }

    func dismissed() -> Self {
        .init(mailbox: nil, labelAs: nil, moveTo: nil, isCreateLabelScreenPresented: false)
    }
}
