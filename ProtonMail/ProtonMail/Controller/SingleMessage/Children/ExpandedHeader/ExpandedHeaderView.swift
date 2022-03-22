//
//  ExpandedHeaderView.swift
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

class ExpandedHeaderView: UIView {

    let initialsContainer = SubviewsFactory.container
    let initialsLabel = UILabel.initialsLabel
    let contentStackView = UIStackView.stackView(axis: .vertical, distribution: .fill, alignment: .fill)
    let senderNameLabel = UILabel()
    let senderEmailControl = TextControl()
    let lockImageView = SubviewsFactory.imageView
    let lockImageControl = UIControl(frame: .zero)
    private(set) lazy var lockContainer = StackViewContainer(view: lockImageControl, top: 4)
    let timeLabel = UILabel()
    let starImageView = SubviewsFactory.starImageView

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        lockImageControl.addSubview(lockImageView)

        addSubview(initialsContainer)
        addSubview(senderNameLabel)
        addSubview(senderEmailControl)
        addSubview(lockContainer)
        addSubview(timeLabel)
        addSubview(starImageView)
        addSubview(contentStackView)
        initialsContainer.addSubview(initialsLabel)
    }

    // swiftlint:disable function_body_length
    private func setUpLayout() {
        [
            initialsContainer.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            initialsContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            initialsContainer.heightAnchor.constraint(equalToConstant: 28),
            initialsContainer.widthAnchor.constraint(equalToConstant: 28)
        ].activate()

        [
            initialsLabel.leadingAnchor.constraint(equalTo: initialsContainer.leadingAnchor, constant: 2),
            initialsLabel.trailingAnchor.constraint(equalTo: initialsContainer.trailingAnchor, constant: -2),
            initialsLabel.topAnchor.constraint(equalTo: initialsContainer.topAnchor, constant: 2),
            initialsLabel.bottomAnchor.constraint(equalTo: initialsContainer.bottomAnchor, constant: -2),
            initialsLabel.centerYAnchor.constraint(equalTo: initialsContainer.centerYAnchor)
        ].activate()

        [
            senderNameLabel.leadingAnchor.constraint(equalTo: initialsContainer.trailingAnchor, constant: 10),
            senderNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            senderNameLabel.trailingAnchor.constraint(equalTo: starImageView.leadingAnchor, constant: -8),
            senderNameLabel.heightAnchor.constraint(equalToConstant: 20)
        ].activate()

        [
            timeLabel.centerYAnchor.constraint(equalTo: senderNameLabel.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ].activate()
        timeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        [
            starImageView.centerYAnchor.constraint(equalTo: senderNameLabel.centerYAnchor),
            starImageView.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -4),
            starImageView.widthAnchor.constraint(equalToConstant: 16),
            starImageView.heightAnchor.constraint(equalToConstant: 16)
        ].activate()

        [
            lockImageView.centerXAnchor.constraint(equalTo: lockImageControl.centerXAnchor),
            lockImageView.centerYAnchor.constraint(equalTo: lockImageControl.centerYAnchor)
        ].activate()

        [
            lockContainer.heightAnchor.constraint(equalToConstant: 16),
            lockContainer.widthAnchor.constraint(equalToConstant: 16),
            lockContainer.leadingAnchor.constraint(equalTo: senderNameLabel.leadingAnchor),
            lockContainer.centerYAnchor.constraint(equalTo: senderEmailControl.centerYAnchor)
        ].activate()

        [
            senderEmailControl.topAnchor.constraint(equalTo: senderNameLabel.bottomAnchor, constant: 4),
            senderEmailControl.leadingAnchor.constraint(equalTo: lockContainer.trailingAnchor, constant: 4),
            senderEmailControl.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -88),
            senderEmailControl.bottomAnchor.constraint(equalTo: contentStackView.topAnchor, constant: -5)
        ].activate()

        [
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
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
        view.backgroundColor = ColorProvider.InteractionWeak
        view.layer.cornerRadius = 8
        view.isUserInteractionEnabled = false
        return view
    }

    static var starImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = IconProvider.starFilled
        imageView.tintColor = ColorProvider.NotificationWarning
        return imageView
    }

    static var imageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
}
