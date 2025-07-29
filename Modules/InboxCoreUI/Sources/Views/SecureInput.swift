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
import UIKit

public struct SecureInput: UIViewRepresentable {
    struct Configuration {
        let font: UIFont?
        let alignment: NSTextAlignment
        let placeholder: LocalizedStringResource?
        let keyboardType: UIKeyboardType
        let allowedCharacters: CharacterSet?

        static var `default`: Self {
            .init(font: nil, alignment: .left, placeholder: nil, keyboardType: .default, allowedCharacters: nil)
        }

        static var pinSettingsInput: Self {
            .init(font: nil, alignment: .left, placeholder: nil, keyboardType: .numberPad, allowedCharacters: CharacterSet.decimalDigits)
        }

        static var pinLock: Self {
            .init(
                font: .font(textStyle: .title3, weight: .semibold),
                alignment: .center,
                placeholder: L10n.PINLock.pinInputPlaceholder,
                keyboardType: .numberPad,
                allowedCharacters: CharacterSet.decimalDigits
            )
        }
    }

    let configuration: Configuration
    @Binding var text: String
    @Binding var isSecure: Bool

    init(configuration: Configuration, text: Binding<String>, isSecure: Binding<Bool>) {
        self.configuration = configuration
        self._text = text
        self._isSecure = isSecure
    }

    public func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.textAlignment = configuration.alignment
        textField.font = configuration.font
        textField.placeholder = configuration.placeholder?.string
        textField.isSecureTextEntry = isSecure
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.borderStyle = .none
        textField.keyboardType = configuration.keyboardType
        textField.tintColor = UIColor(DS.Color.Text.accent)

        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
        return textField
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.isSecureTextEntry = isSecure
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SecureInput

        init(_ parent: SecureInput) {
            self.parent = parent
        }

        @objc func textChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        public func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            guard !string.isEmpty else { return true }
            guard let allowedCharacters = parent.configuration.allowedCharacters else { return true }
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
    }
}
