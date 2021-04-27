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

import UIKit

class ExpandedHeaderView: UIView {

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
        addSubview(initialsLabel)
        addSubview(senderNameLabel)
        addSubview(senderEmailControl)
        addSubview(timeLabel)
        addSubview(contentStackView)
    }

    private func setUpLayout() {
        [
            initialsLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            initialsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            initialsLabel.heightAnchor.constraint(equalToConstant: 28),
            initialsLabel.widthAnchor.constraint(equalToConstant: 28),
            initialsLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -14)
        ].activate()

        [
            senderNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            senderNameLabel.leadingAnchor.constraint(equalTo: initialsLabel.trailingAnchor, constant: 10),
            senderNameLabel.bottomAnchor.constraint(equalTo: senderEmailControl.topAnchor, constant: -8),
            senderNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8)
        ].activate()

        [
            timeLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 18),
            timeLabel.centerYAnchor.constraint(equalTo: senderNameLabel.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            timeLabel.bottomAnchor.constraint(lessThanOrEqualTo: senderEmailControl.topAnchor, constant: -8)
        ].activate()

        [
            senderEmailControl.leadingAnchor.constraint(equalTo: initialsLabel.trailingAnchor, constant: 10),
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
