// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreUIFoundations
import UIKit

class AutoDeletePromptHeaderView: UIView {
    private let containerView = UIView()
    private let logoImageView = SubviewsFactory.logoImageView
    private let promptLabel = SubviewsFactory.promptLabel
    private let enableButton = SubviewsFactory.enableButton
    private let noThanksButton = SubviewsFactory.noThanksButton

    var enableButtonAction: (() -> Void)?
    var noThanksButtonAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ColorProvider.BackgroundNorm
        addViews()
        buildLayout()
        setupViewsAndControls()

    }

    private func addViews() {
        addSubview(containerView)
        containerView.addSubview(logoImageView)
        containerView.addSubview(promptLabel)
        containerView.addSubview(enableButton)
        containerView.addSubview(noThanksButton)
    }

    private func buildLayout() {
        [
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            logoImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            logoImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            logoImageView.heightAnchor.constraint(equalToConstant: 48),
            logoImageView.widthAnchor.constraint(equalTo: logoImageView.heightAnchor, multiplier: 1),
            promptLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 12),
            promptLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            promptLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            enableButton.heightAnchor.constraint(equalToConstant: 32),
            enableButton.leadingAnchor.constraint(equalTo: logoImageView.leadingAnchor),
            enableButton.topAnchor.constraint(greaterThanOrEqualTo: logoImageView.bottomAnchor, constant: 12)
                .setPriority(as: .defaultLow),
            enableButton.topAnchor.constraint(greaterThanOrEqualTo: promptLabel.bottomAnchor, constant: 12)
                .setPriority(as: .defaultLow),
            enableButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            noThanksButton.leadingAnchor.constraint(equalTo: enableButton.trailingAnchor, constant: 12),
            noThanksButton.topAnchor.constraint(equalTo: enableButton.topAnchor),
            noThanksButton.trailingAnchor.constraint(equalTo: promptLabel.trailingAnchor),
            noThanksButton.bottomAnchor.constraint(equalTo: enableButton.bottomAnchor),
            noThanksButton.heightAnchor.constraint(equalTo: enableButton.heightAnchor, multiplier: 1),
            enableButton.widthAnchor.constraint(equalTo: noThanksButton.widthAnchor, multiplier: 1)
        ].activate()
    }

    private func setupViewsAndControls() {
        containerView.layer.cornerRadius = 12.0
        containerView.layer.borderWidth = 1.0
        containerView.layer.borderColor = ColorProvider.SeparatorNorm

        enableButton.addTarget(self, action: #selector(enableButtonTapped), for: .touchUpInside)
        noThanksButton.addTarget(self, action: #selector(noThanksButtonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("Unsupported. Please use `init(frame: CGRect)`")
    }

    @objc
    func enableButtonTapped() {
        self.enableButtonAction?()
    }

    @objc
    func noThanksButtonTapped() {
        self.noThanksButtonAction?()
    }
}

extension AutoDeletePromptHeaderView {
    class SubviewsFactory {
        static var logoImageView: UIView {
            let imageView = UIImageView()
            imageView.image = Asset.upgradeIconBig.image
            return imageView
        }

        static var promptLabel: UILabel {
            let label = UILabel()
            label.numberOfLines = 0
            label.set(text: L10n.AutoDeleteBanners.paidPrompt, preferredFont: .footnote)
            return label
        }

        static var enableButton: UIButton {
            let button = ProtonButton()
            button.setMode(mode: .solid)
            button.setTitle(L10n.AutoDeleteBanners.enableButtonTitle, for: .normal)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.numberOfLines = 1
            return button
        }

        static var noThanksButton: UIButton {
            let button = ProtonButton()
            button.setMode(mode: .outlined)
            button.layer.borderWidth = 0
            button.setBackgroundImage(UIImage.colored(with: ColorProvider.InteractionWeak), for: .normal)
            button.setTitleColor(ColorProvider.TextNorm, for: .normal)
            button.setTitleColor(ColorProvider.TextNorm, for: .highlighted)
            button.setTitle(L10n.AutoDeleteBanners.noThanksButtonTitle, for: .normal)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.numberOfLines = 1
            return button
        }
    }
}
