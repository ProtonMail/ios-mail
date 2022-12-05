//
//  NewMailboxMessageCellContentView.swift
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
import UIKit

class NewMailboxMessageCellContentView: UIView {

    let messageContentView = NewMailboxMessageContentView()
    let leftContainer = UIControl()
    let initialsContainer = SubviewsFactory.container
    let initialsLabel = UILabel.initialsLabel
    let checkBoxView = NewMailboxMessageCheckBoxView()
    let scheduledIconView = SubviewsFactory.scheduledIconView
    let scheduledContainer = SubviewsFactory.scheduledContainer

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(messageContentView)
        addSubview(leftContainer)
        leftContainer.addSubview(initialsContainer)
        leftContainer.addSubview(checkBoxView)
        leftContainer.addSubview(scheduledIconView)
        leftContainer.addSubview(scheduledContainer)
        initialsContainer.addSubview(initialsLabel)
    }

    private func setUpLayout() {
        [
            leftContainer.heightAnchor.constraint(equalToConstant: 28),
            leftContainer.widthAnchor.constraint(equalToConstant: 28),
            leftContainer.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            leftContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18)
        ]
            .activate()

        [
            messageContentView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageContentView.leadingAnchor.constraint(equalTo: leftContainer.trailingAnchor, constant: 16),
            messageContentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            messageContentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ]
            .activate()

        [initialsContainer, checkBoxView, scheduledContainer].forEach { view in
            [
                view.topAnchor.constraint(equalTo: leftContainer.topAnchor),
                view.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: leftContainer.bottomAnchor)
            ]
                .activate()
        }

        [
            scheduledIconView.centerXAnchor.constraint(equalTo: leftContainer.centerXAnchor),
            scheduledIconView.centerYAnchor.constraint(equalTo: leftContainer.centerYAnchor),
            scheduledIconView.widthAnchor.constraint(equalToConstant: 20),
            scheduledIconView.heightAnchor.constraint(equalToConstant: 20)
        ].activate()

        [
            initialsLabel.leadingAnchor.constraint(equalTo: initialsContainer.leadingAnchor, constant: 2),
            initialsLabel.trailingAnchor.constraint(equalTo: initialsContainer.trailingAnchor, constant: -2),
            initialsLabel.centerYAnchor.constraint(equalTo: initialsContainer.centerYAnchor)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {
    static var container: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.InteractionWeak
        view.layer.cornerRadius = 8
        view.isUserInteractionEnabled = false
        return view
    }

    static var scheduledIconView: UIImageView {
        let view = UIImageView(image: IconProvider.clock)
        view.contentMode = .scaleAspectFit
        view.tintColor = ColorProvider.IconNorm
        return view
    }

    static var scheduledContainer: UIView {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorProvider.SeparatorNorm.cgColor
        view.isUserInteractionEnabled = false
        return view
    }
}
