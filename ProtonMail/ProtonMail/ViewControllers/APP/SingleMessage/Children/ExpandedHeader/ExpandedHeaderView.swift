//
//  ExpandedHeaderView.swift
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

class ExpandedHeaderView: HeaderView {

    let contentStackView = UIStackView.stackView(axis: .vertical, distribution: .fill, alignment: .fill)
    let senderEmailControl = TextControl()
    let hideDetailButton = SubviewsFactory.hideDetailButton

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        lockImageControl.addSubview(lockImageView)

        addSubview(initialsContainer)

        let firstLineViews: [UIView] = [
            senderLabel,
            officialBadge,
            UIView(),
            starImageView,
            timeLabel
        ]
        firstLineViews.forEach(firstLineStackView.addArrangedSubview(_:))
        addSubview(firstLineStackView)

        addSubview(senderEmailControl)
        addSubview(lockContainer)
        addSubview(contentStackView)
        initialsContainer.addSubview(initialsLabel)
        initialsContainer.addSubview(senderImageView)
    }

    private func setUpLayout() {
        setUpInitialsLayout()
        setUpFirstLineLayout()
        setUpSenderMailLineLayout()
        setUpContentStackViewLayout()
    }

    func preferredContentSizeChanged() {
        senderLabel.font = .adjustedFont(forTextStyle: .subheadline)
        hideDetailButton.titleLabel?.font = .adjustedFont(forTextStyle: .footnote)
        [initialsLabel, timeLabel, senderEmailControl.label]
            .forEach { $0.font = .adjustedFont(forTextStyle: .footnote) }
    }

    required init?(coder: NSCoder) {
        nil
    }
}

// MARK: Auto layout
extension ExpandedHeaderView {
    private func setUpInitialsLayout() {
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
        senderImageView.fillSuperview()
    }

    private func setUpFirstLineLayout() {
        [
            firstLineStackView.leadingAnchor.constraint(equalTo: initialsContainer.trailingAnchor, constant: 10),
            firstLineStackView.topAnchor.constraint(equalTo: initialsContainer.topAnchor),
            firstLineStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            starImageView.widthAnchor.constraint(equalToConstant: 16),
            starImageView.heightAnchor.constraint(equalToConstant: 16)
        ].activate()

        timeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    private func setUpSenderMailLineLayout() {
        lockImageView.fillSuperview()

        [
            lockContainer.heightAnchor.constraint(equalToConstant: 16),
            lockContainer.widthAnchor.constraint(equalToConstant: 16),
            lockContainer.leadingAnchor.constraint(equalTo: senderLabel.leadingAnchor),
            lockContainer.centerYAnchor.constraint(equalTo: senderEmailControl.centerYAnchor)
        ].activate()

        [
            senderEmailControl.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 4),
            senderEmailControl.leadingAnchor.constraint(equalTo: lockContainer.trailingAnchor, constant: 4),
            senderEmailControl.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -88),
            senderEmailControl.bottomAnchor.constraint(equalTo: contentStackView.topAnchor, constant: -5)
        ].activate()
    }

    private func setUpContentStackViewLayout() {
        [
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ].activate()
    }
}
