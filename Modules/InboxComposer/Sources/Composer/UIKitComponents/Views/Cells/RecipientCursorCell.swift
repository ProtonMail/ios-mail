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
import UIKit

final class RecipientCursorCell: UICollectionViewCell {
    enum Event {
        case onTextChanged(text: String)
        case onReturnKeyPressed
        case onDeleteKeyPressedOnEmptyTextField
    }

    private let textField = CursorTextField()
    private var intentionallyResigningResponder = false
    var shouldEndEditing: () -> Bool = { true }
    var onEvent: ((Event) -> Void)?

    private var widthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
        setUpConstraints()
    }

    required init?(coder: NSCoder) { nil }

    private func setUpView() {
        contentView.backgroundColor = DS.Color.Background.norm.toDynamicUIColor
        contentView.addSubview(textField)

        textField.delegate = self
        textField.onTextChanged = { [weak self] text in
            self?.onEvent?(.onTextChanged(text: text ?? .empty))
        }
        textField.onDeleteBackwardWhenEmpty = { [weak self] in
            self?.onEvent?(.onDeleteKeyPressedOnEmptyTextField)
        }
    }

    private func setUpConstraints() {
        widthConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint?.priority = .defaultHigh
        widthConstraint?.isActive = true

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -1),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func clearText() {
        textField.text = nil
    }

    func setFocus() {
        guard !textField.isFirstResponder else { return }
        textField.becomeFirstResponder()
    }

    func removeFocus() {
        intentionallyResigningResponder = true
        textField.resignFirstResponder()
        intentionallyResigningResponder = false
    }

    func configure(maxWidth: CGFloat) {
        widthConstraint?.constant = maxWidth
    }

    func configure(maxWidth: CGFloat, input: String) {
        textField.text = input
        configure(maxWidth: maxWidth)
    }
}

extension RecipientCursorCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, !text.isEmpty {
            onEvent?(.onReturnKeyPressed)
        }
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if intentionallyResigningResponder { return true }
        return shouldEndEditing()
    }
}

final class CursorTextField: UITextField {
    var onTextChanged: ((_ text: String?) -> Void)?
    var onDeleteBackwardWhenEmpty: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setUpUI()
    }

    required init?(coder: NSCoder) { nil }

    private func setUpUI() {
        translatesAutoresizingMaskIntoConstraints = false
        font = UIFont.preferredFont(forTextStyle: .subheadline)
        textColor = DS.Color.Text.norm.toDynamicUIColor
        autocapitalizationType = .none
        autocorrectionType = .no
        spellCheckingType = .no
        keyboardType = .emailAddress
        tintColor = DS.Color.Icon.accent.toDynamicUIColor
        addTarget(self, action: #selector(CursorTextField.textFieldDidChange(_:)), for: .editingChanged)
    }

    override func deleteBackward() {
        if let text, text.isEmpty {
            onDeleteBackwardWhenEmpty?()
        }
        super.deleteBackward()
    }

    @objc
    private func textFieldDidChange(_: UITextField) {
        onTextChanged?(text)
    }

    override func paste(_ sender: Any?) {
        guard let pastedText = UIPasteboard.general.string else {
            super.paste(sender)
            return
        }
        let sanitizedText = pastedText.replacingOccurrences(of: "mailto:", with: "", options: .caseInsensitive, range: nil)
            .withoutWhitespace
        insertText(sanitizedText)
    }
}
