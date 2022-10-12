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

final class BannerWithButton: BaseBannerView {
    private let iconView = SubviewsFactory.iconImageView
    private let contentTextView = SubviewsFactory.contentTextView
    private let button = SubviewsFactory.button
    private let action: () -> Void
    private var row: UIStackView!

    init(icon: UIImage, content: String, buttonTitle: String, action: @escaping () -> Void) {
        self.action = action

        super.init()

        iconView.image = icon
        iconView.tintColor = ColorProvider.NotificationError

        contentTextView.set(text: content, preferredFont: .footnote)

        button.titleLabel?.set(text: nil, preferredFont: .footnote, weight: .semibold)
        button.setTitle(buttonTitle, for: .normal)
        button.setTitleColor(ColorProvider.TextNorm, for: .normal)

        setCornerRadius(radius: 8)
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        row = UIStackView(arrangedSubviews: [iconView, contentTextView, button])
        row.alignment = .center
        row.distribution = .equalSpacing
        row.spacing = 10
        addSubview(row)

        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }

    private func setUpLayout() {
        row.centerInSuperview()
        [
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            row.topAnchor.constraint(equalTo: topAnchor, constant: 6)
        ].activate()
    }

    @objc
    private func actionButtonTapped() {
        action()
    }
}

private enum SubviewsFactory {
    static var iconImageView: UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        [
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        ].activate()
        return imageView
    }

    static var contentTextView: UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isSelectable = false
        textView.zeroPadding()
        return textView
    }

    static var button: UIButton {
        let button = UIButton()
        button.backgroundColor = ColorProvider.InteractionWeak
        button.contentEdgeInsets = UIEdgeInsets(all: 8)
        button.roundCorner(8)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }
}
