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

class AutoDeleteSpamInfoHeaderView: AutoDeleteInfoHeaderView {
    override class var emptyButton: UIButton {
        let button = ProtonButton()
        button.setMode(mode: .text)
        button.setTitle(L10n.AutoDeleteBanners.emptySpam, for: .normal)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.sizeToFit()
        return button
    }
}

class AutoDeleteTrashInfoHeaderView: AutoDeleteInfoHeaderView {
    override class var emptyButton: UIButton {
        let button = ProtonButton()
        button.setMode(mode: .text)
        button.setTitle(L10n.AutoDeleteBanners.emptyTrash, for: .normal)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.sizeToFit()
        return button
    }
}

class AutoDeleteInfoHeaderView: UIView {
    private let containerView = UIView()
    private let trashImageView = SubviewsFactory.trashIconImageView
    private let infoLabel = SubviewsFactory.infoLabel
    private lazy var emptyButton = Self.emptyButton

    var emptyButtonAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ColorProvider.BackgroundNorm
        addViews()
        buildLayout()
        setupViewsAndControls()

    }

    private func addViews() {
        addSubview(containerView)
        containerView.addSubview(trashImageView)
        containerView.addSubview(infoLabel)
        containerView.addSubview(emptyButton)
    }

    private func buildLayout() {
        [
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            trashImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            trashImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            trashImageView.heightAnchor.constraint(equalToConstant: 20),
            trashImageView.widthAnchor.constraint(equalTo: trashImageView.heightAnchor, multiplier: 1),
            infoLabel.leadingAnchor.constraint(equalTo: trashImageView.trailingAnchor, constant: 12),
            infoLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            emptyButton.leadingAnchor.constraint(equalTo: infoLabel.leadingAnchor, constant: -16),
            emptyButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 0),
            emptyButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
        ].activate()
    }

    private func setupViewsAndControls() {
        containerView.layer.cornerRadius = 12.0
        containerView.layer.borderWidth = 1.0
        containerView.layer.borderColor = ColorProvider.SeparatorNorm

        emptyButton.addTarget(self, action: #selector(emptyButtonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("Unsupported. Please use `init(frame: CGRect)`")
    }

    class var emptyButton: UIButton {
        fatalError("Please use one of the subclasses")
    }

    @objc
    func emptyButtonTapped() {
        self.emptyButtonAction?()
    }

    func toggleEmptyButton(shouldEnable: Bool) {
        emptyButton.isEnabled = shouldEnable
    }
}

extension AutoDeleteInfoHeaderView {
    class SubviewsFactory {
        static var trashIconImageView: UIView {
            let imageView = UIImageView()
            imageView.image = IconProvider.trashClock
            imageView.tintColor = ColorProvider.IconNorm
            return imageView
        }

        static var infoLabel: UILabel {
            let label = UILabel()
            label.numberOfLines = 0
            let style = FontManager.Caption.foregroundColor(ColorProvider.TextNorm)
            label.set(text: L10n.AutoDeleteBanners.enabledInfoText.apply(style: style), preferredFont: .body)
            return label
        }
    }
}
