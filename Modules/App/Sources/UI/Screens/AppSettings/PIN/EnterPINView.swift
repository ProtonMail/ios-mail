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

import InboxDesignSystem
import SwiftUI

struct EnterPINView: View {
    @Binding private var text: String
    @Binding private var validation: FormTextInput.ValidationStatus
    @FocusState private var isFocused: Bool
    private let title: LocalizedStringResource

    init(
        title: LocalizedStringResource,
        text: Binding<String>,
        validation: Binding<FormTextInput.ValidationStatus>
    ) {
        self.title = title
        self._text = text
        self._validation = validation
    }

    var body: some View {
        VStack(spacing: DS.Spacing.huge) {
            Image(DS.Images.lock)
            FormTextInput(
                title: title,
                placeholder: .init(stringLiteral: .empty),
                footer: L10n.Settings.App.setPINInformation,
                text: $text,
                validation: $validation,
                inputType: .secureOneline
            )
            .focused($isFocused)

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.large)
        .padding(.top, DS.Spacing.extraLarge)
        .background(DS.Color.BackgroundInverted.norm)
        .navigationBarTitleDisplayMode(.inline)
        .onLoad { isFocused = true }
        .onChange(of: isFocused) { _, _ in
            isFocused = true
        }
    }

}

#Preview {
    NavigationStack {
        EnterPINView(
            title: L10n.Settings.App.setPINInputTitle,
            text: .constant(.empty),
            validation: .noValidation
        )
    }
}
