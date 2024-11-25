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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI
import UIKit

enum RecipientCursorCellEvent {
    case onReturnKeyPressed(text: String)
    case onDeleteKeyPressedOnEmptyTextField
}

final class RecipientCursorCell: UICollectionViewCell {
    private let textField = SubviewFactory.textField
    var onEvent: ((RecipientCursorCellEvent) -> Void)?

    private var widthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
        setUpConstraints()
    }

    required init?(coder: NSCoder) { nil }

    private func setUpView() {
        contentView.backgroundColor = UIColor(DS.Color.Background.norm)
        contentView.addSubview(textField)

        textField.delegate = self
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
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    func clearText() {
        textField.text = nil
    }

    func setFocus() {
        textField.becomeFirstResponder()
    }

    func removeFocus() {
        textField.resignFirstResponder()
    }

    func configure(maxWidth: CGFloat) {
        widthConstraint?.constant = maxWidth
    }
}

extension RecipientCursorCell: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, !text.isEmpty {
            onEvent?(.onReturnKeyPressed(text: text))
        }
        return true
    }
}

extension RecipientCursorCell {

    private enum SubviewFactory {

        static var textField: RecipientCursorTextField {
            let view = RecipientCursorTextField()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.autocapitalizationType = .none
            view.autocorrectionType = .no
            view.spellCheckingType = .no
            view.keyboardType = .emailAddress
            view.tintColor = UIColor(DS.Color.Icon.accent)
            return view
        }
    }
}

final class RecipientCursorTextField: UITextField {
    var onDeleteBackwardWhenEmpty: (() -> Void)?

    override func deleteBackward() {
        if let text, text.isEmpty {
            onDeleteBackwardWhenEmpty?()
        }
        super.deleteBackward()
    }
}
