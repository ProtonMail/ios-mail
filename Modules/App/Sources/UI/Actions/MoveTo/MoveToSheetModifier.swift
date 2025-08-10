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
import SwiftUI

private struct MoveToSheetModifier: ViewModifier {
    private let mailbox: () -> Mailbox
    private let mailUserSession: MailUserSession
    @Binding var input: ActionSheetInput?
    private let navigation: (MoveToSheetNavigation) -> Void

    init(
        mailbox: @escaping () -> Mailbox,
        mailUserSession: MailUserSession,
        input: Binding<ActionSheetInput?>,
        navigation: @escaping (MoveToSheetNavigation) -> Void
    ) {
        self.mailbox = mailbox
        self.mailUserSession = mailUserSession
        self._input = .init(projectedValue: input)
        self.navigation = navigation
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: $input, content: actionPicker)
    }

    // MARK: - Private

    private func actionPicker(input: ActionSheetInput) -> some View {
        MoveToSheet(
            input: input,
            mailbox: mailbox(),
            availableMoveToActions: .productionInstance,
            moveToActions: .productionInstance,
            navigation: navigation,
            mailUserSession: mailUserSession
        )
    }
}

extension View {
    func moveToSheet(
        mailbox: @escaping () -> Mailbox,
        mailUserSession: MailUserSession,
        input: Binding<ActionSheetInput?>,
        navigation: @escaping (MoveToSheetNavigation) -> Void
    ) -> some View {
        modifier(
            MoveToSheetModifier(
                mailbox: mailbox,
                mailUserSession: mailUserSession,
                input: input,
                navigation: navigation
            )
        )
    }
}
