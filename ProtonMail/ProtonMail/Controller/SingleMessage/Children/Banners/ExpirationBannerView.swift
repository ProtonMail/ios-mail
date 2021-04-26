//
//  ExpirationBannerView.swift
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

import PMUIFoundations

class ExpirationBannerView: UIView {

    let iconView = SubviewsFactory.iconImageView
    let titleLabel = UILabel()

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        backgroundColor = UIColorManager.NotificationWarning
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

    func updateTitleWith(offset: Int) {
        let (d, h, m) = durationsBySecond(seconds: offset)
        var textAttribute = FontManager.DefaultSmallStrong
        textAttribute.addTruncatingTail()
        if offset <= 0 {
            titleLabel.attributedText = NSAttributedString(string: LocalString._message_expired,
                                                           attributes: textAttribute)
        } else {
            let text = String(format: LocalString._expires_in_days_hours_mins_seconds, d, h, m)
            titleLabel.attributedText = NSAttributedString(string: text,
                                                           attributes: textAttribute)
        }
    }

    private func durationsBySecond(seconds s: Int) -> (days: Int, hours: Int, minutes: Int) {
        return (s / (24 * 3600), (s % (24 * 3600)) / 3600, s % 3600 / 60)
    }
}

private enum SubviewsFactory {
    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: Asset.mailHourglass.image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColorManager.IconNorm
        return imageView
    }
}
