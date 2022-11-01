// Copyright (c) 2021 Proton AG
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

import UIKit
import ProtonCore_UIFoundations

class MailButton: UIControl {
    let titleLabel = SubviewsFactory.titleView
    let iconView = SubviewsFactory.iconImageView
    private let containerView = UIView()

    var title: String? {
        didSet {
            titleLabel.text = title
            accessibilityLabel = titleLabel.text
        }
    }

    var icon: UIImage? {
        didSet {
            iconView.image = icon
        }
    }

    var tap: (() -> Void)?

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        setUpAction()
    }

    private func addSubviews() {
        addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
    }

    private func setUpLayout() {
        containerView.isUserInteractionEnabled = false
        [
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 6),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ].activate()
        containerView.setContentHuggingPriority(.required, for: .vertical)

        [
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -6.0),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ].activate()

        [
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ].activate()
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        [
            self.heightAnchor.constraint(equalToConstant: 40)
        ].activate()

        layer.borderWidth = 1.0
        layer.borderColor = ColorProvider.InteractionWeak.cgColor
        roundCorner(20.0)
    }

    private func setUpAction() {
        accessibilityTraits = .button
        isAccessibilityElement = true
        addTarget(self, action: #selector(tapAction), for: .touchUpInside)
    }

    @objc
    private func tapAction() {
        tap?()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private enum SubviewsFactory {
        static var iconImageView: UIImageView {
            let view = UIImageView()
            view.contentMode = .scaleAspectFit
            view.tintColor = ColorProvider.IconNorm
            return view
        }

        static var titleView: UILabel {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14.0)
            label.numberOfLines = 2
            label.preferredMaxLayoutWidth = 200
            return label
        }
    }
}
