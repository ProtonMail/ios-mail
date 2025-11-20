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

import InboxCoreUI
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

private struct LabelAsSheetModifier: ViewModifier {
    private let mailbox: () -> Mailbox
    private let mailUserSession: MailUserSession
    @Binding var input: ActionSheetInput?
    @EnvironmentObject var toastStateStore: ToastStateStore

    init(
        mailbox: @escaping () -> Mailbox,
        mailUserSession: MailUserSession,
        input: Binding<ActionSheetInput?>
    ) {
        self.mailbox = mailbox
        self.mailUserSession = mailUserSession
        self._input = .init(projectedValue: input)
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: $input, content: actionPicker)
    }

    // MARK: - Private

    private func actionPicker(item: ActionSheetInput) -> some View {
        let model = LabelAsSheetModel(
            input: item,
            mailbox: mailbox(),
            availableLabelAsActions: .productionInstance,
            labelAsActions: .productionInstance,
            toastStateStore: toastStateStore,
            mailUserSession: mailUserSession
        ) {
            self.input = nil
        }
        return LabelAsSheet(model: model)
    }

}

extension View {
    func labelAsSheet(
        mailbox: @escaping () -> Mailbox,
        mailUserSession: MailUserSession,
        input: Binding<ActionSheetInput?>
    ) -> some View {
        modifier(LabelAsSheetModifier(mailbox: mailbox, mailUserSession: mailUserSession, input: input))
    }
}
