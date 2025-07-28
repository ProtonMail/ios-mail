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

import InboxDesignSystem
import UIKit

final class SubjectFieldView: UIView {

    enum Event {
        case onStartEditing
        case onSubjectChange(String)
    }

    private let stack = SubviewFactory.stack
    private let title = SubviewFactory.title
    private let textField = SubviewFactory.textField
    var onEvent: ((Event) -> Void)?

    var text: String {
        get { textField.text ?? .empty }
        set { textField.text = newValue }
    }

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(textField)
        addSubview(stack)

        title.setContentHuggingPriority(.required, for: .horizontal)
        title.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),

            textField.topAnchor.constraint(equalTo: stack.topAnchor, constant: DS.Spacing.moderatelyLarge),
            textField.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: -DS.Spacing.moderatelyLarge),
        ])

        textField.addTarget(self, action: #selector(onStartEditing), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(onTextChange), for: .editingChanged)
    }
    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: CGSize {
        stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    @objc
    private func onStartEditing() {
        onEvent?(.onStartEditing)
    }

    @objc
    private func onTextChange(textField: UITextField) {
        onEvent?(.onSubjectChange(textField.text ?? .empty))
    }
}

extension SubjectFieldView {

    private enum SubviewFactory {

        static var stack: UIStackView {
            ComposerSubviewFactory.regularFieldStack
        }

        static var title: UILabel {
            let view = ComposerSubviewFactory.fieldTitle
            view.text = L10n.Composer.subject.string
            return view
        }

        static var textField: UITextField {
            ComposerSubviewFactory.regularTextField
        }
    }
}
