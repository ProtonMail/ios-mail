//
//  EmbeddedImageBannerView.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations

class EmbeddedImageBannerView: UIView {

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundSecondary
        setCornerRadius(radius: 8)
        addSubviews()
        setUpLayout()
    }

    let loadContentButton = SubviewsFactory.loadContentButton
    let iconView = SubviewsFactory.iconImageView
    let titleLabel = SubviewsFactory.titleLabel

    required init?(coder: NSCoder) {
        nil
    }

    private func addSubviews() {
        addSubview(iconView)
        addSubview(loadContentButton)
        addSubview(titleLabel)
    }

    private func setUpLayout() {
        [
            iconView.topAnchor.constraint(equalTo: self.topAnchor, constant: 16.0),
            iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16.0),
            iconView.heightAnchor.constraint(equalToConstant: 20.0),
            iconView.widthAnchor.constraint(equalToConstant: 20.0)
        ].activate()

        [
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: iconView.topAnchor)
        ].activate()
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        [
            loadContentButton.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12.0),
            loadContentButton.leadingAnchor.constraint(equalTo: iconView.leadingAnchor),
            loadContentButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            loadContentButton.heightAnchor.constraint(equalToConstant: 32),
            loadContentButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16)
        ].activate()
    }
}

private enum SubviewsFactory {

    static var loadContentButton: UIButton {
        let button = UIButton(frame: .zero)
        button.backgroundColor = ColorProvider.InteractionWeak
        button.setCornerRadius(radius: 3)
        button.setAttributedTitle(
            LocalString._banner_load_embedded_image.apply(style: FontManager.body3RegularNorm),
            for: .normal
        )
        return button
    }

    static var titleLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.attributedText = LocalString._banner_embedded_image_title.apply(style: FontManager.Caption)
        label.numberOfLines = 0
        return label
    }

    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: Asset.mailRemoteContentIcon.image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorProvider.IconNorm
        return imageView
    }
}
