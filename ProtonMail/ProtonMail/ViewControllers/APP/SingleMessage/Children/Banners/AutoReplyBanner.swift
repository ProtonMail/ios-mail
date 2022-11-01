// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

class AutoReplyBanner: UIView {
    let infoLabel = SubviewsFactory.infoLabel
    private let iconImageView = SubviewsFactory.iconImageView
    private var heightConstraint: NSLayoutConstraint?

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
        addSubview(iconImageView)
    }

    private func setUpLayout() {
        [
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ].activate()
        heightConstraint = infoLabel.heightAnchor.constraint(equalToConstant: infoLabel.contentSize.height)
        [
            infoLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            infoLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            infoLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            infoLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            heightConstraint!
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let textViewContentHeight = infoLabel.contentSize.height
        if heightConstraint?.constant != textViewContentHeight {
            heightConstraint?.constant = textViewContentHeight
            setNeedsLayout()
        }
    }
}

private enum SubviewsFactory {
    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: IconProvider.lightbulb)
        imageView.tintColor = ColorProvider.IconNorm
        return imageView
    }

    static var infoLabel: UITextView {
        let textView = UITextView()
        let text = LocalString._autoreply_banner_description.apply(style: FontManager.Caption)
        let link = LocalString._learn_more.apply(style: FontManager.Caption.link(url: Link.autoReplyInfo))
        textView.attributedText = text + .init(string: " ") + link
        textView.isEditable = false
        textView.isUserInteractionEnabled = true
        textView.textContainerInset = .zero
        textView.backgroundColor = .clear
        return textView
    }
}
