//
//  NonExpandedHeaderView.swift
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

class NonExpandedHeaderView: UIView {

    let initialsContainer = SubviewsFactory.container
    let initialsLabel = UILabel.initialsLabel
    let senderLabel = UILabel(frame: .zero)
    let senderAddressLabel = TextControl()
    let lockImageView = SubviewsFactory.imageView
    let lockImageControl = UIControl(frame: .zero)
    let originImageView = SubviewsFactory.originImageView
    let timeLabel = UILabel(frame: .zero)
    let contentStackView = UIStackView.stackView(axis: .vertical, spacing: 8)
    let recipientLabel = UILabel()
    let tagsView = SingleRowTagsView()
    let showDetailsButton = SubviewsFactory.showDetailButton
    let starImageView = SubviewsFactory.starImageView
    private(set) lazy var lockContainer = StackViewContainer(view: lockImageControl, top: 4)

    private let firstLineStackView = UIStackView.stackView(axis: .horizontal, distribution: .fill, alignment: .center)
    private let senderAddressStack = UIStackView.stackView(axis: .horizontal, distribution: .fill, alignment: .center)
    private let detailButtonStack = UIStackView.stackView(axis: .horizontal, distribution: .fill, alignment: .center)

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(initialsContainer)
        addSubview(contentStackView)

        initialsContainer.addSubview(initialsLabel)
        lockImageControl.addSubview(lockImageView)

        contentStackView.addArrangedSubview(firstLineStackView)

        let originContainer = StackViewContainer(view: originImageView, top: 2)

        firstLineStackView.addArrangedSubview(senderLabel)
        firstLineStackView.addArrangedSubview(UIView())
        firstLineStackView.addArrangedSubview(starImageView)
        firstLineStackView.addArrangedSubview(originContainer)
        firstLineStackView.addArrangedSubview(timeLabel)

        firstLineStackView.setCustomSpacing(4, after: senderLabel)
        firstLineStackView.setCustomSpacing(6, after: originContainer)
        firstLineStackView.setCustomSpacing(4, after: starImageView)

        contentStackView.addArrangedSubview(senderAddressStack)
        senderAddressStack.addArrangedSubview(lockContainer)
        senderAddressStack.addArrangedSubview(senderAddressLabel)
        senderAddressStack.addArrangedSubview(UIView(frame: .zero))
        senderAddressStack.setCustomSpacing(4, after: lockContainer)
        senderAddressStack.setCustomSpacing(32, after: senderAddressLabel)

        contentStackView.addArrangedSubview(StackViewContainer(view: recipientLabel, trailing: -70))
        contentStackView.addArrangedSubview(tagsView)

        contentStackView.addArrangedSubview(detailButtonStack)
        detailButtonStack.addArrangedSubview(showDetailsButton)
        detailButtonStack.addArrangedSubview(UIView())
    }

    private func setUpLayout() {
        [
            initialsContainer.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            initialsContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            initialsContainer.trailingAnchor.constraint(equalTo: firstLineStackView.leadingAnchor, constant: -10),
            initialsContainer.heightAnchor.constraint(equalToConstant: 28),
            initialsContainer.widthAnchor.constraint(equalToConstant: 28)
        ].activate()

        [
            initialsLabel.centerYAnchor.constraint(equalTo: initialsContainer.centerYAnchor),
            initialsLabel.leadingAnchor.constraint(equalTo: initialsContainer.leadingAnchor, constant: 2),
            initialsLabel.trailingAnchor.constraint(equalTo: initialsContainer.trailingAnchor, constant: -2)
        ].activate()

        [
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ].activate()

        [
            lockImageView.centerXAnchor.constraint(equalTo: lockImageControl.centerXAnchor),
            lockImageView.centerYAnchor.constraint(equalTo: lockImageControl.centerYAnchor)
        ].activate()

        [
            lockContainer.heightAnchor.constraint(equalToConstant: 16),
            lockContainer.widthAnchor.constraint(equalToConstant: 16)
        ].activate()

        [recipientLabel.heightAnchor.constraint(equalToConstant: 20)].activate()

        senderLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        timeLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        timeLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var contentStackView: UIStackView {
        UIStackView.stackView(axis: .vertical, spacing: 8)
    }

    static var originImageView: UIImageView {
        let imageView = self.imageView
        imageView.tintColor = ColorProvider.IconWeak
        return imageView
    }

    static var container: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.InteractionWeak
        view.layer.cornerRadius = 8
        view.isUserInteractionEnabled = false
        return view
    }

    static var imageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    static var starImageView: UIImageView {
        let imageView = imageView
        imageView.image = Asset.mailStar.image
        return imageView
    }

    static var showDetailButton: UIButton {
        let button = UIButton()
        button.setTitle(LocalString._show_details, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }
}
