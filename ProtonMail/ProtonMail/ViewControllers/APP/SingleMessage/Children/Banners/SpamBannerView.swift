//
//  SpamBannerView.swift
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

class SpamBannerView: UIView {

    let iconImageView = SubviewsFactory.iconImageView
    let infoTextView = SubviewsFactory.infoTextView
    let button = SubviewsFactory.button
    private let topContainer = UIView()
    private let contentStackView = UIStackView.stackView(axis: .vertical, spacing: 12)

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.NotificationError
        roundCorner(8)
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(contentStackView)
        topContainer.addSubview(iconImageView)
        topContainer.addSubview(infoTextView)

        contentStackView.addArrangedSubview(topContainer)
        contentStackView.addArrangedSubview(button)
    }

    private var heightConstraint: NSLayoutConstraint?

    override func layoutSubviews() {
        super.layoutSubviews()

        heightConstraint?.constant = infoTextView.intrinsicContentSize.height
    }

    private func setUpLayout() {
        [
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ].activate()

        [
            iconImageView.topAnchor.constraint(greaterThanOrEqualTo: topContainer.topAnchor),
            iconImageView.bottomAnchor.constraint(lessThanOrEqualTo: topContainer.bottomAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: infoTextView.centerYAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            iconImageView.widthAnchor.constraint(equalToConstant: 20)
        ].activate()

        [
            infoTextView.topAnchor.constraint(equalTo: topContainer.topAnchor),
            infoTextView.bottomAnchor.constraint(equalTo: topContainer.bottomAnchor),
            infoTextView.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor),
            infoTextView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8)
        ].activate()

        heightConstraint = infoTextView.heightAnchor.constraint(
            equalToConstant: infoTextView.intrinsicContentSize.height
        )
        heightConstraint?.isActive = true

        [button.heightAnchor.constraint(equalToConstant: 32)].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var infoTextView: UITextView {
        let textView = UITextView(frame: .zero)
        textView.linkTextAttributes = [.link: ColorProvider.TextInverted as UIColor]
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.backgroundColor = .clear
        return textView
    }

    static var iconImageView: UIImageView {
        let imageView = UIImageView()
        imageView.tintColor = ColorProvider.IconInverted
        return imageView
    }

    static var button: UIButton {
        let button = UIButton()
        button.setBackgroundImage(.colored(with: .init(red: 1, green: 1, blue: 1, alpha: 0.35)), for: .normal)
        button.roundCorner(8)
        return button
    }

}
