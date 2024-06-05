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

class AutoDeleteUpsellHeaderView: UIView {
    private let containerView = UIView()
    private let logoImageView = SubviewsFactory.logoImageView
    private let upsellLabel = SubviewsFactory.upsellLabel
    private let learnMoreButton = SubviewsFactory.learnMoreButton

    var learnMoreButtonAction: (() -> Void)?

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
        containerView.addSubview(upsellLabel)
        containerView.addSubview(learnMoreButton)
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
            upsellLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 12),
            upsellLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            upsellLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            learnMoreButton.leadingAnchor.constraint(equalTo: upsellLabel.leadingAnchor, constant: -16),
            learnMoreButton.topAnchor.constraint(greaterThanOrEqualTo: upsellLabel.bottomAnchor, constant: 0),
            learnMoreButton.topAnchor.constraint(greaterThanOrEqualTo: logoImageView.bottomAnchor, constant: 0),
            learnMoreButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
        ].activate()
    }

    private func setupViewsAndControls() {
        containerView.layer.cornerRadius = 12.0
        containerView.layer.borderWidth = 1.0
        containerView.layer.borderColor = ColorProvider.SeparatorNorm

        learnMoreButton.addTarget(self, action: #selector(learnMoreButtonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("Unsupported. Please use `init(frame: CGRect)`")
    }

    @objc
    func learnMoreButtonTapped() {
        self.learnMoreButtonAction?()
    }
}

extension AutoDeleteUpsellHeaderView {
    class SubviewsFactory {
        static var logoImageView: UIView {
            let imageView = UIImageView()
            imageView.image = Asset.upgradeIconBig.image
            return imageView
        }

        static var upsellLabel: UILabel {
            let label = UILabel()
            label.numberOfLines = 0
            label.set(text: L10n.AutoDeleteBanners.freeUpsell, preferredFont: .footnote)
            return label
        }

        static var learnMoreButton: UIButton {
            let button = ProtonButton()
            button.setMode(mode: .text)
            button.setTitle(L10n.AutoDeleteBanners.learnMore, for: .normal)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.sizeToFit()
            return button
        }
    }
}
