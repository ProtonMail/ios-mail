//
//  NewMailboxMessageCellContentView.swift
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
import UIKit

class NewMailboxMessageCellContentView: UIView {

    let messageContentView = NewMailboxMessageContentView()
    let leftContainer = UIControl()
    let initialsLabel = SubviewsFactory.initialsLabel
    let checkBoxView = NewMailboxMessageCheckBoxView()

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColorManager.BackgroundNorm
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(messageContentView)
        addSubview(leftContainer)
        leftContainer.addSubview(initialsLabel)
        leftContainer.addSubview(checkBoxView)
    }

    private func setUpLayout() {
        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        [
            leftContainer.heightAnchor.constraint(equalToConstant: 28),
            leftContainer.widthAnchor.constraint(equalToConstant: 28),
            leftContainer.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            leftContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18)
        ]
            .activate()

        messageContentView.translatesAutoresizingMaskIntoConstraints = false
        [
            messageContentView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageContentView.leadingAnchor.constraint(equalTo: leftContainer.trailingAnchor, constant: 16),
            messageContentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            messageContentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ]
            .activate()

        [initialsLabel, checkBoxView].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            [
                view.topAnchor.constraint(equalTo: leftContainer.topAnchor),
                view.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: leftContainer.bottomAnchor)
            ]
                .activate()
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var initialsLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.backgroundColor = UIColorManager.InteractionWeak
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.isUserInteractionEnabled = false
        return label
    }

}
