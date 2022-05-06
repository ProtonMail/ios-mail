//
//  UnsubscribeBanner.swift
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
        backgroundColor = ColorProvider.BackgroundSecondary
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
        button.setBackgroundImage(.color(ColorProvider.InteractionWeak), for: .normal)
        button.setCornerRadius(radius: 8)
        return button
    }

    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: IconProvider.envelope)
        imageView.tintColor = ColorProvider.IconNorm
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
