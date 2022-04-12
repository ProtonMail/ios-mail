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
    let timeLabel = SubviewsFactory.timeLabel
    let contentStackView = UIStackView.stackView(axis: .vertical, spacing: 8)
    let recipientLabel = UILabel()
    let tagsView = SingleRowTagsView()
    let showDetailsControl = SubviewsFactory.showDetailControl
    let starImageView = SubviewsFactory.starImageView
    private(set) lazy var lockContainer = StackViewContainer(view: lockImageControl, top: 4)

    private let firstLineStackView = UIStackView.stackView(axis: .horizontal, distribution: .fill, alignment: .center)
    private let senderAddressStack = UIStackView.stackView(axis: .horizontal, distribution: .fill, alignment: .center)
    private let recipientStack = UIStackView.stackView(axis: .horizontal, distribution: .fill, alignment: .center)

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(initialsContainer)
        addSubview(contentStackView)
        addSubview(showDetailsControl)

        initialsContainer.addSubview(initialsLabel)
        lockImageControl.addSubview(lockImageView)

        contentStackView.addArrangedSubview(firstLineStackView)
        contentStackView.setCustomSpacing(4, after: firstLineStackView)

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
        contentStackView.setCustomSpacing(4, after: senderAddressStack)
        senderAddressStack.addArrangedSubview(lockContainer)
        senderAddressStack.addArrangedSubview(senderAddressLabel)
        senderAddressStack.addArrangedSubview(UIView(frame: .zero))
        senderAddressStack.setCustomSpacing(4, after: lockContainer)
        // 32 reply button + 8 * 2 spacing + 32 more button
        senderAddressStack.setCustomSpacing(80, after: senderAddressLabel)

        recipientStack.addArrangedSubview(recipientLabel)
        recipientStack.setCustomSpacing(80, after: recipientLabel)
        recipientStack.addArrangedSubview(UIView())
        contentStackView.addArrangedSubview(recipientStack)
        contentStackView.setCustomSpacing(4, after: recipientStack)
        contentStackView.addArrangedSubview(tagsView)
    }

    private func setUpLayout() {
        [
            initialsContainer.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            initialsContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
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
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
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

        [
            recipientLabel.heightAnchor.constraint(equalToConstant: 20)
        ].activate()
        [
            showDetailsControl.leadingAnchor.constraint(equalTo: recipientLabel.leadingAnchor),
            showDetailsControl.topAnchor.constraint(equalTo: recipientLabel.topAnchor),
            showDetailsControl.trailingAnchor.constraint(equalTo: recipientLabel.trailingAnchor),
            showDetailsControl.bottomAnchor.constraint(equalTo: recipientLabel.bottomAnchor)
        ].activate()
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

    static var showDetailControl: UIControl {
        let control = UIControl()
        return control
    }

    static var timeLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.textAlignment = .right
        return label
    }
}
