// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import UIKit
import ProtonCore_UIFoundations

class MailButton: UIControl {
    let titleLabel = SubviewsFactory.titleView
    let iconView = SubviewsFactory.iconImageView
    private let stackView = SubviewsFactory.stackView
    private let containerView = UIView()

    var title: String? {
        didSet {
            titleLabel.text = title
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
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 15),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -15),
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 24.0)
        ].activate()

        [
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -6.0),
            iconView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            iconView.topAnchor.constraint(equalTo: containerView.topAnchor)
        ].activate()

        [
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ].activate()

        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        layer.borderWidth = 1.0
        layer.borderColor = UIColorManager.InteractionWeak.cgColor
        roundCorner(20.0)
    }

    private func setUpAction() {
        self.addTarget(self, action: #selector(tapAction), for: .touchUpInside)
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
            view.tintColor = UIColorManager.IconNorm
            return view
        }

        static var titleView: UILabel {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14.0)
            label.numberOfLines = 2
            return label
        }

        static var stackView: UIStackView {
            let view = UIStackView()
            view.axis = .horizontal
            view.spacing = 6
            view.isUserInteractionEnabled = false
            return view
        }

    }
}
