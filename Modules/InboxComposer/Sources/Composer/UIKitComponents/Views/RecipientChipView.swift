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

final class RecipientChipView: UIView {
    private let stack = SubviewFactory.stack
    private let icon = SubviewFactory.icon
    private let label = SubviewFactory.label

    var recipient: RecipientUIModel? {
        didSet {
            apply(recipient: recipient)
        }
    }

    init() {
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(label)
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        applyCGColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.apply(recipient: self.recipient)
        }
    }
    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: CGSize {
        stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    private func apply(recipient: RecipientUIModel?) {
        isHidden = recipient == nil
        guard let recipient else { return }
        backgroundColor = recipient.backgroundColor
        icon.image = recipient.icon
        icon.isHidden = recipient.icon == nil
        icon.tintColor = recipient.iconTintColor
        label.text = recipient.address
        label.textColor = recipient.textColor
        applyCGColors()
    }

    private func applyCGColors() {
        layoutIfNeeded()
        layer.borderWidth = recipient != nil ? 1 : 0
        layer.masksToBounds = true
        layer.cornerRadius = frame.height / 2.0
        layer.borderColor = recipient?.borderColor.cgColor
    }
}


extension RecipientChipView {

    private enum SubviewFactory {
        static var icon: UIImageView {
            let view = UIImageView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }

        static var label: UILabel {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.font = UIFont.preferredFont(forTextStyle: .subheadline)
            view.textAlignment = .center
            return view
        }

        static var stack: UIStackView {
            let view = UIStackView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.alignment = .center
            view.spacing = DS.Spacing.small
            view.directionalLayoutMargins = .init(top: 0, leading: DS.Spacing.mediumLight, bottom: 0, trailing: DS.Spacing.mediumLight)
            view.isLayoutMarginsRelativeArrangement = true
            return view
        }
    }
}
