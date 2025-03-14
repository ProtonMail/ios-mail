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

struct FormMultilineTextInput: View {
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
    private let placeholder: String
    @Binding private var text: String
    @Binding private var validation: ValidationStatus
    @FocusState private var isFocused: Bool

    init(title: LocalizedStringResource, placeholder: String, text: Binding<String>, validation: Binding<ValidationStatus>) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self._validation = validation
    }

    // MARK: - View

    var body: some View {
        VStack(spacing: DS.Spacing.standard) {
            VStack(alignment: .leading) {
                Text(title)
                    .animation(.easeOut(duration: 0.2), value: isFocused)
                    .fontWeight((isFocused || validation.isFailure) ? .semibold : .regular)
                    .foregroundStyle(validation.isFailure ? DS.Color.Notification.error : (isFocused ? DS.Color.Text.accent : DS.Color.Text.weak))
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
            .padding(.all, DS.Spacing.large)
            .frame(maxWidth: .infinity)
            .frame(minHeight: minimalContainerHight, alignment: .topLeading)
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
            }
        }
        .animation(.easeInOut(duration: 0.2), value: validation)
    }

    // MARK: - Style

    private let minimalContainerHight: CGFloat = 140
}

extension Binding where Value == FormMultilineTextInput.ValidationStatus {

    static var noValidation: Self {
        Binding(get: { .ok }, set: { _ in })
    }

}
