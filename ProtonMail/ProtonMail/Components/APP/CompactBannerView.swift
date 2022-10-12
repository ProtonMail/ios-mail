// Copyright (c) 2022 Proton AG
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

import ProtonCore_UIFoundations
import UIKit

final class CompactBannerView: BaseBannerView {
    let iconImageView: UIImageView = SubviewsFactory.iconImageView
    let titleLabel: UILabel = SubviewsFactory.titleLabel

    let action: (() -> Void)?
    let appearance: Appearance

    enum Appearance {
        case normal
        case expiration
        case alert

        var backgroundColor: UIColor {
            switch self {
            case .normal, .alert:
                return ColorProvider.BackgroundNorm
            case .expiration:
                return ColorProvider.NotificationError
            }
        }

        var textColor: UIColor {
            switch self {
            case .normal, .alert:
                return ColorProvider.TextNorm
            case .expiration:
                return .white
            }
        }

        var iconColor: UIColor {
            switch self {
            case .normal:
                return ColorProvider.IconNorm
            case .expiration:
                return .white
            case .alert:
                return ColorProvider.NotificationError
            }
        }
    }

    init(
        appearance: Appearance,
        title: String,
        icon: UIImage,
        action: (() -> Void)?
    ) {
        self.appearance = appearance
        self.action = action

        super.init()

        addSubviews()
        setupLayout()

        self.backgroundColor = appearance.backgroundColor
        iconImageView.image = icon
            .withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = appearance.iconColor
        titleLabel.set(text: title,
                       preferredFont: .footnote,
                       textColor: appearance.textColor)
        if action != nil {
            setupTapGesture()
        }
    }

    private func addSubviews() {
        addSubview(iconImageView)
        addSubview(titleLabel)
    }

    private func setupLayout() {
        [
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            iconImageView.widthAnchor.constraint(equalToConstant: 20.0),
            iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor)
        ].activate()

        [
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10.0),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ].activate()
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    func updateTitleText(newTitle: String) {
        titleLabel.set(text: newTitle,
                       preferredFont: .footnote,
                       textColor: appearance.textColor)
    }

    func disableTapGesture() {
        gestureRecognizers?.forEach(removeGestureRecognizer)
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    @objc
    private func tapped() {
        action?()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                layer.borderColor = ColorProvider.InteractionWeak.cgColor
            }
        }
    }
}

private enum SubviewsFactory {
    static var titleLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        return label
    }

    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: nil)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
}
