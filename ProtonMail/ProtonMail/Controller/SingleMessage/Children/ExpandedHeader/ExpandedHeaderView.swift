//
//  ExpandedHeaderView.swift
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
import UIKit

class ExpandedHeaderView: UIView {

    let initialsContainer = SubviewsFactory.container
    let initialsLabel = UILabel.initialsLabel
    let contentStackView = UIStackView.stackView(axis: .vertical, distribution: .fill, alignment: .fill)
    let senderNameLabel = UILabel()
    let senderEmailControl = TextControl()
    let timeLabel = UILabel()

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(initialsContainer)
        addSubview(senderNameLabel)
        addSubview(senderEmailControl)
        addSubview(timeLabel)
        addSubview(contentStackView)
        initialsContainer.addSubview(initialsLabel)
    }

    private func setUpLayout() {
        [
            initialsContainer.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            initialsContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            initialsContainer.heightAnchor.constraint(equalToConstant: 28),
            initialsContainer.widthAnchor.constraint(equalToConstant: 28),
            initialsContainer.bottomAnchor.constraint(equalTo: senderEmailControl.topAnchor, constant: -2)
        ].activate()

        [
            initialsLabel.leadingAnchor.constraint(equalTo: initialsContainer.leadingAnchor, constant: 2),
            initialsLabel.trailingAnchor.constraint(equalTo: initialsContainer.trailingAnchor, constant: -2),
            initialsLabel.centerYAnchor.constraint(equalTo: initialsContainer.centerYAnchor)
        ].activate()

        [
            senderNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            senderNameLabel.leadingAnchor.constraint(equalTo: initialsContainer.trailingAnchor, constant: 10),
            senderNameLabel.centerYAnchor.constraint(equalTo: initialsContainer.centerYAnchor),
            senderNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8)
        ].activate()

        [
            timeLabel.centerYAnchor.constraint(equalTo: senderNameLabel.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ].activate()

        [
            senderEmailControl.leadingAnchor.constraint(equalTo: initialsContainer.trailingAnchor, constant: 10),
            senderEmailControl.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -48),
            senderEmailControl.bottomAnchor.constraint(equalTo: contentStackView.topAnchor, constant: -8)
        ].activate()

        [
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {
    static var container: UIView {
        let view = UIView()
        view.backgroundColor = UIColorManager.InteractionWeak
        view.layer.cornerRadius = 6
        view.isUserInteractionEnabled = false
        return view
    }
}
