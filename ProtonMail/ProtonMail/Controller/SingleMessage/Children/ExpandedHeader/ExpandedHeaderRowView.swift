//
//  ExpandedHeaderRowView.swift
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
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

class ExpandedHeaderRowView: UIView {

    let titleLabel = UILabel(frame: .zero)
    let iconImageView = SubviewsFactory.iconImageView
    let contentStackView = UIStackView.stackView(axis: .vertical, distribution: .fill, alignment: .fill)
    private let titleContainer = UIView()

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(titleContainer)
        titleContainer.addSubview(titleLabel)
        titleContainer.addSubview(iconImageView)

        addSubview(contentStackView)
    }

    private func setUpLayout() {
        [
            titleContainer.topAnchor.constraint(equalTo: topAnchor),
            titleContainer.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            titleContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleContainer.trailingAnchor.constraint(equalTo: contentStackView.leadingAnchor, constant: -10),
            titleContainer.widthAnchor.constraint(equalToConstant: 28),
            titleContainer.heightAnchor.constraint(equalToConstant: 28)
        ].activate()

        [iconImageView, titleLabel].forEach { view in
            [
                view.centerXAnchor.constraint(equalTo: titleContainer.centerXAnchor),
                view.centerYAnchor.constraint(equalTo: titleContainer.centerYAnchor),
                view.topAnchor.constraint(greaterThanOrEqualTo: titleContainer.topAnchor),
                view.leadingAnchor.constraint(greaterThanOrEqualTo: titleContainer.leadingAnchor),
                view.trailingAnchor.constraint(lessThanOrEqualTo: titleContainer.trailingAnchor),
                view.bottomAnchor.constraint(lessThanOrEqualTo: titleContainer.bottomAnchor)
            ].activate()
        }

        [
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var iconImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.tintColor = UIColorManager.IconWeak
        return imageView
    }

}
