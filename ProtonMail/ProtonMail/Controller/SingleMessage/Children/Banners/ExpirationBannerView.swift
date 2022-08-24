//
//  ExpirationBannerView.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations

class ExpirationBannerView: UIView {

    let iconView = SubviewsFactory.iconImageView
    let titleLabel = UILabel()

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        backgroundColor = ColorProvider.NotificationWarning
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func addSubviews() {
        addSubview(iconView)
        addSubview(titleLabel)
    }

    private func setUpLayout() {
        [
            iconView.topAnchor.constraint(equalTo: self.topAnchor, constant: 14.0),
            iconView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -14.0),
            iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16.0),
            iconView.heightAnchor.constraint(equalToConstant: 20.0),
            iconView.widthAnchor.constraint(equalToConstant: 20.0)
        ].activate()

        [
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16)
        ].activate()
    }
}

private enum SubviewsFactory {
    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: IconProvider.hourglass)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorProvider.IconNorm
        return imageView
    }
}
