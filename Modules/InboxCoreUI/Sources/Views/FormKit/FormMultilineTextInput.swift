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

public struct FormTextInput: View {
    public enum InputType {
        case secureOneline(SecureInput.Configuration)
        case multiline
    }

    public enum ValidationStatus: Equatable {
        case ok
        case failure(String)

        public var isFailure: Bool {
            switch self {
            case .ok:
                false
            case .failure:
                true
            }
        }

        public var isSuccess: Bool {
            switch self {
            case .ok:
                true
            case .failure:
                false
            }
        }
    }

    private let title: LocalizedStringResource
    private let placeholder: LocalizedStringResource?
    private let footer: LocalizedStringResource?
    private let inputType: InputType
    @Binding private var text: String
    @Binding private var validation: ValidationStatus
    @FocusState private var isFocused: Bool

    public init(
        title: LocalizedStringResource,
        placeholder: LocalizedStringResource? = nil,
        footer: LocalizedStringResource? = nil,
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

    public var body: some View {
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
            } else if let footer {
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
        case .secureOneline(let configuration):
            FormSecureTextInput(configuration: configuration, title: title, text: $text)
        case .multiline:
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .padding(.top, -DS.Spacing.standard)
                    .padding(.leading, -DS.Spacing.small)
                    .accentColor(DS.Color.Text.accent)
                if text.isEmpty, let placeholder {
                    Text(placeholder)
                        .foregroundStyle(DS.Color.Text.hint)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

extension Binding where Value == FormTextInput.ValidationStatus {

    public static var noValidation: Self {
        .readonly { .ok }
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
