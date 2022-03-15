//
//  ErrorBannerView.swift
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

class ErrorBannerView: UIView {

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.NotificationError
        setCornerRadius(radius: 8)
        addSubviews()
        setUpLayout()
    }

    let iconView = SubviewsFactory.iconImageView
    let titleLabel = SubviewsFactory.titleLabel

    required init?(coder: NSCoder) {
        nil
    }

    private func addSubviews() {
        addSubview(iconView)
        addSubview(titleLabel)
    }

    private func setUpLayout() {
        [
            iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16.0),
            iconView.heightAnchor.constraint(equalToConstant: 20.0),
            iconView.widthAnchor.constraint(equalToConstant: 20.0)
        ].activate()

        [
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 18),
            titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -18),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8)
        ].activate()
    }

    func setErrorTitle(_ title: String) {
        var titleAttribute = FontManager.DefaultSmall
        titleAttribute[.foregroundColor] = ColorProvider.TextInverted
        titleLabel.attributedText = NSAttributedString(string: title,
                                                       attributes: titleAttribute)
    }
}

private enum SubviewsFactory {

    static var titleLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        return label
    }

    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: Asset.bannerExclamation.image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorProvider.IconInverted
        return imageView
    }
}
