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
import InboxDesignSystem
import SwiftUI

struct EnterPINView<Button: View>: View {
    @Binding private var text: String
    @Binding private var validation: FormTextInput.ValidationStatus
    @FocusState private var isFocused: Bool
    private let title: LocalizedStringResource
    private let isInputFooterVisible: Bool
    private let bottomButton: () -> Button

    init(
        title: LocalizedStringResource,
        text: Binding<String>,
        isInputFooterVisible: Bool,
        validation: Binding<FormTextInput.ValidationStatus>,
        bottomButton: @escaping () -> Button
    ) {
        self.title = title
        self._text = text
        self.isInputFooterVisible = isInputFooterVisible
        self._validation = validation
        self.bottomButton = bottomButton
    }

    var body: some View {
        VStack(spacing: DS.Spacing.huge) {
            Image(DS.Images.lock)
                .resizable()
                .square(size: 64)

            FormTextInput(
                title: title,
                placeholder: .init(stringLiteral: .empty),
                footer: isInputFooterVisible ? L10n.Settings.App.setPINInformation : nil,
                text: $text,
                validation: $validation,
                inputType: .secureOneline(.pinSettingsInput)
            )
            .focused($isFocused)

            Spacer()

            bottomButton()
                .buttonStyle(BigButtonStyle())
                .padding(.horizontal, DS.Spacing.standard)
                .padding(.bottom, DS.Spacing.extraLarge)
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
            isInputFooterVisible: true,
            validation: .noValidation
        ) {
            Button(action: {}, label: { Text("Confirm".notLocalized) })
        }
    }
}
