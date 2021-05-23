//
//  UnsubscribeBanner.swift
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
import ProtonCore_UIFoundations

class UnsubscribeBanner: UIView {

    let infoLabel = SubviewsFactory.infoLabel
    let unsubscribeButton = SubviewsFactory.unsubscribeButton
    private let iconImageView = SubviewsFactory.iconImageView

    init() {
        super.init(frame: .zero)
        setUpSelf()
        addSubviews()
        setUpLayout()
    }

    private func setUpSelf() {
        backgroundColor = UIColorManager.BackgroundSecondary
        roundCorner(8)
    }

    private func addSubviews() {
        addSubview(infoLabel)
        addSubview(unsubscribeButton)
        addSubview(iconImageView)
    }

    private func setUpLayout() {
        [
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            iconImageView.widthAnchor.constraint(equalToConstant: 20)
        ].activate()

        [
            infoLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            infoLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            infoLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            infoLabel.bottomAnchor.constraint(equalTo: unsubscribeButton.topAnchor, constant: -14),
            infoLabel.heightAnchor.constraint(equalToConstant: infoLabel.contentSize.height)
        ].activate()

        [
            unsubscribeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            unsubscribeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            unsubscribeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            unsubscribeButton.heightAnchor.constraint(equalToConstant: 32)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var unsubscribeButton: UIButton {
        let button = UIButton(frame: .zero)
        button.setAttributedTitle(LocalString._unsubscribe.apply(style: FontManager.body3RegularNorm), for: .normal)
        button.setBackgroundImage(.color(UIColorManager.InteractionWeak), for: .normal)
        button.setCornerRadius(radius: 3)
        return button
    }

    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: Asset.envelope.image)
        imageView.tintColor = UIColorManager.IconNorm
        return imageView
    }

    static var infoLabel: UITextView {
        let textView = UITextView()
        let text = LocalString._unsubscribe_banner_description.apply(style: FontManager.Caption)
        let link = LocalString._learn_more.apply(style: FontManager.Caption.link(url: Link.unsubscribeInfo))
        textView.attributedText = text + .init(string: " ") + link
        textView.isEditable = false
        textView.isUserInteractionEnabled = true
        textView.textContainerInset = .zero
        textView.backgroundColor = .clear
        return textView
    }

}
