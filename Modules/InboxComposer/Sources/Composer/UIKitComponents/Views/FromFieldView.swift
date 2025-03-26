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

enum FromFieldViewEvent {
    case onFieldTap
}

final class FromFieldView: UIView {
    private let stack = SubviewFactory.stack
    private let title = SubviewFactory.title
    private let label = SubviewFactory.label
    private let chevronButton = SubviewFactory.chevronButton
    var onEvent: ((FromFieldViewEvent) -> Void)?

    var text: String {
        get { label.text ?? .empty }
        set { label.text = newValue }
    }

    init() {
        super.init(frame: .zero)
        setUpUI()
        setUpConstraints()
    }
    required init?(coder: NSCoder) { nil }

    private func setUpUI() {
        [title, label, chevronButton].forEach(stack.addArrangedSubview)
        addSubview(stack)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        label.addGestureRecognizer(tapGesture)
        chevronButton.addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false

        title.setContentHuggingPriority(.required, for: .horizontal)
        title.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),

            label.topAnchor.constraint(equalTo: stack.topAnchor, constant: DS.Spacing.moderatelyLarge),
            label.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: -DS.Spacing.moderatelyLarge),

            chevronButton.widthAnchor.constraint(equalToConstant: 40),
            chevronButton.heightAnchor.constraint(equalTo: chevronButton.widthAnchor),
        ])
    }

    override var intrinsicContentSize: CGSize {
        stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    @objc
    private func onTap() {
        onEvent?(.onFieldTap)
    }
}

extension FromFieldView {

    private enum SubviewFactory {

        static var stack: UIStackView {
            ComposerSubviewFactory.regularFieldStack
        }
        
        static var title: UILabel {
            let view = ComposerSubviewFactory.fieldTitle
            view.text = L10n.Composer.from.string
            return view
        }

        static var label: UILabel {
            let view = ComposerSubviewFactory.regularLabel
            view.isUserInteractionEnabled = true
            return view
        }

        static var chevronButton: UIButton {
            ComposerSubviewFactory.chevronButton
        }
    }
}
