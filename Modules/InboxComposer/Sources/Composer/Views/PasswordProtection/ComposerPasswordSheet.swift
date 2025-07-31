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
import InboxDesignSystem
import SwiftUI

struct ComposerPasswordSheet: View {
    typealias Save = (_ password: String, _ hint: String?) async -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openUrl

    @State private var state: ComposerPasswordState
    @FocusState private var isPasswordFocused: Bool
    private var passwordBinding: Binding<String> {
        .init(
            get: { state.password },
            set: { value in
                state =
                    state
                    .copy(\.password, to: value)
                    .copy(\.passwordValidation, to: .ok)
            }
        )
    }

    private let onSave: Save
    private let learnMoreUrl = URL(string: "https://proton.me/support/password-protected-emails")

    init(state: ComposerPasswordState, onSave: @escaping Save) {
        self.state = state
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.large) {
            HStack {
                Button(CommonL10n.cancel.string, action: { dismiss() })
                    .foregroundStyle(DS.Color.Text.accent)
                    .font(.body)
                    .fontWeight(.regular)

                Spacer()
                Text(L10n.PasswordProtection.title)
                    .lineLimit(1)
                    .foregroundStyle(DS.Color.Text.norm)
                    .font(.body)
                    .fontWeight(.semibold)

                Spacer()
                Button(CommonL10n.save.string) {
                    guard validate() else { return }
                    Task {
                        await onSave(state.password, state.hint)
                        dismiss()
                    }
                }
                .foregroundStyle(DS.Color.InteractionBrand.norm)
                .font(.body)
                .fontWeight(.semibold)
            }
            .padding(DS.Spacing.large)

            ScrollView {
                VStack(spacing: DS.Spacing.extraLarge) {
                    descriptionView()

                    FormTextInput(
                        title: L10n.PasswordProtection.messagePassword,
                        placeholder: .init(stringLiteral: .empty),
                        footer: L10n.PasswordProtection.passwordConditions,
                        text: passwordBinding,
                        validation: $state.passwordValidation,
                        inputType: .secureOneline(.default)
                    )
                    .focused($isPasswordFocused)

                    FormTextInput(
                        title: L10n.PasswordProtection.passwordHint,
                        placeholder: .init(stringLiteral: "".notLocalized),
                        footer: .none,
                        text: $state.hint,
                        validation: .noValidation,
                        inputType: .multiline
                    )

                    Spacer()
                        .frame(maxHeight: .infinity)

                }
                .padding(.horizontal, DS.Spacing.extraLarge)
            }
        }
        .background(DS.Color.Background.secondary)
        .onAppear {
            isPasswordFocused = state.password.isEmpty && state.hint.isEmpty
        }
    }

    private func descriptionView() -> some View {
        let description = String(localized: L10n.PasswordProtection.description)
        let learnMore = String(localized: CommonL10n.learnMore)

        var attributed = AttributedString(description + " " + learnMore)
        if let range = attributed.range(of: learnMore) {
            attributed[range].link = learnMoreUrl
            attributed[range].foregroundColor = DS.Color.Text.accent
        }

        return Text(attributed)
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }

    private func validate() -> Bool {
        let validPasswordLength = 8...21
        let isValid = validPasswordLength.contains(state.password.count)
        state.passwordValidation = isValid ? .ok : .failure(L10n.PasswordProtection.passwordConditions.string)
        return isValid
    }
}
