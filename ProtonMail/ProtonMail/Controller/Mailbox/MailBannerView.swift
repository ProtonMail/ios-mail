//
//  MailBannerView.swift
//  ProtonMail
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
import UIKit

class MailBannerView: UIView {

    let contentContainer = UIView()
    let label = SubviewsFactory.label

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        setUpSelf()
    }

    private func addSubviews() {
        addSubview(contentContainer)

        contentContainer.addSubview(label)
    }

    private func setUpLayout() {
        [
            contentContainer.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            label.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -16)
        ].activate()
    }

    private func setUpSelf() {
        contentContainer.backgroundColor = ColorProvider.NotificationError
        contentContainer.layer.cornerRadius = 8
        contentContainer.layer.apply(shadow: .default)
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var stackView: UIStackView {
        .stackView(distribution: .fillProportionally, spacing: 8)
    }

    static var imageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = IconProvider.arrowsRotate
        imageView.tintColor = ColorProvider.IconInverted
        return imageView
    }

    static var label: UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        return label
    }

}

private extension TempFigmaShadow {

    static var banner: TempFigmaShadow {
        .init(color: UIColor.black.withAlphaComponent(0.1), x: 0, y: 4, blur: 8, spread: 0)
    }

}
