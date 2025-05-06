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

struct FormTextInput: View {
    enum InputType {
        case secureOneline
        case multiline
    }

    enum ValidationStatus: Equatable {
        case ok
        case failure(LocalizedStringResource)

        var isFailure: Bool {
            switch self {
            case .ok:
                false
            case .failure:
                true
            }
        }
    }

    private let title: LocalizedStringResource
    private let placeholder: LocalizedStringResource
    private let footer: LocalizedStringResource
    private let inputType: InputType
    @Binding private var text: String
    @Binding private var validation: ValidationStatus
    @FocusState private var isFocused: Bool

    init(
        title: LocalizedStringResource,
        placeholder: LocalizedStringResource,
        footer: LocalizedStringResource = .init(stringLiteral: .empty),
        text: Binding<String>,
        validation: Binding<ValidationStatus>,
        inputType: InputType
    ) {
        self.title = title
        self.placeholder = placeholder
        self.footer = footer
        self._text = text
        self._validation = validation
        self.inputType = inputType
    }

    // MARK: - View

    var body: some View {
        VStack(spacing: DS.Spacing.standard) {
            VStack(alignment: .leading, spacing: DS.Spacing.compact) {
                Text(title)
                    .animation(.easeOut(duration: 0.2), value: isFocused)
                    .foregroundStyle(validation.isFailure ? DS.Color.Notification.error : (isFocused ? DS.Color.Text.accent : DS.Color.Text.weak))
                input()
                    .focused($isFocused)
            }
            .padding(.all, DS.Spacing.large)
            .frame(maxWidth: .infinity, minHeight: inputType.minimalContainerHight, alignment: .topLeading)
            .background(DS.Color.BackgroundInverted.secondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Spacing.mediumLight))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Spacing.mediumLight)
                    .stroke(validation.isFailure ? DS.Color.Notification.error : .clear, lineWidth: 1)
            )

            if case .failure(let description) = validation {
                Text(description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Notification.error)
                    .padding(.horizontal, DS.Spacing.large)
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                FormFootnoteText(footer)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Spacing.large)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: validation)
    }

    // MARK: - Style

    @ViewBuilder
    private func input() -> some View {
        switch inputType {
        case .secureOneline:
            FormSecureTextInput(title: title, text: $text)
        case .multiline:
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .padding(.top, -DS.Spacing.standard)
                    .padding(.leading, -DS.Spacing.small)
                    .accentColor(DS.Color.Text.accent)
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(DS.Color.Text.hint)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

extension Binding where Value == FormTextInput.ValidationStatus {

    static var noValidation: Self {
        Binding(get: { .ok }, set: { _ in })
    }

}

private extension FormTextInput.InputType {

    var minimalContainerHight: CGFloat {
        switch self {
        case .secureOneline: 80
        case .multiline: 150
        }
    }

}

struct FormSecureTextInput: View {
    private let title: LocalizedStringResource
    @Binding private var text: String
    @State var pin: String = .empty
    @State var secureEntry: Bool = true

    init(
        title: LocalizedStringResource,
        text: Binding<String>
    ) {
        self.title = title
        self._text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.compact) {
            HStack(spacing: DS.Spacing.mediumLight) {
                ZStack {
                    SecureField(String.empty, text: $pin)
                        .accentColor(DS.Color.Text.accent)
                        .frame(height: 22)
                        .opacity(secureEntry ? 1 : 0)
                        .disabled(!secureEntry)

                    TextField(String.empty, text: $pin)
                        .accentColor(DS.Color.Text.accent)
                        .frame(height: 22)
                        .opacity(secureEntry ? 0 : 1)
                        .disabled(secureEntry)
                }
                Button(action: { secureEntry.toggle() }) {
                    Image(systemName: secureEntry ? "eye" : "eye.slash")
                        .foregroundStyle(DS.Color.Text.hint)
                }
            }
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .frame(maxWidth: .infinity)
    }

}
