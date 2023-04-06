// Copyright (c) 2023 Proton Technologies AG
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

class HeaderView: UIView {
    let initialsContainer = SubviewsFactory.container
    let initialsLabel = UILabel.initialsLabel
    let senderImageView = SubviewsFactory.senderImageView
    let senderLabel = SubviewsFactory.senderLabel
    let lockImageView = SubviewsFactory.lockImageView
    let lockImageControl = UIControl(frame: .zero)
    let officialBadge = SubviewsFactory.officialBadge
    let timeLabel = SubviewsFactory.timeLabel
    let starImageView = SubviewsFactory.starImageView
    private(set) lazy var lockContainer = StackViewContainer(view: lockImageControl, top: 4)

    let firstLineStackView = UIStackView.stackView(
        axis: .horizontal,
        distribution: .fill,
        alignment: .center,
        spacing: 5
    )

    class SubviewsFactory {
        class var container: UIView {
            let view = UIView()
            view.backgroundColor = ColorProvider.InteractionWeak
            view.layer.cornerRadius = 8
            view.isUserInteractionEnabled = false
            return view
        }

        class var lockImageView: UIImageView {
            let imageView = UIImageView(frame: .zero)
            imageView.contentMode = .scaleAspectFill
            return imageView
        }

        class var officialBadge: UIView {
            let view = OfficialBadge()
            view.isHidden = true
            // this is needed to make the badge compress before the senderLabel does
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            return view
        }

        class var senderLabel: UILabel {
            let label = UILabel(frame: .zero)
            label.set(text: nil, preferredFont: .subheadline)
            return label
        }

        class var starImageView: UIImageView {
            let imageView = UIImageView(frame: .zero)
            imageView.contentMode = .scaleAspectFit
            imageView.image = IconProvider.starFilled
            imageView.tintColor = ColorProvider.NotificationWarning
            return imageView
        }

        class var timeLabel: UILabel {
            let label = UILabel(frame: .zero)
            label.textAlignment = .right
            label.set(text: nil, preferredFont: .footnote, textColor: ColorProvider.TextWeak)
            return label
        }

        class var hideDetailButton: UIButton {
            let button = UIButton()
            button.titleLabel?.set(text: nil, preferredFont: .footnote)
            button.setTitle(LocalString._hide_details, for: .normal)
            button.setTitleColor(ColorProvider.InteractionNorm, for: .normal)
            button.setContentCompressionResistancePriority(.required, for: .vertical)
            return button
        }

        class var senderImageView: UIImageView {
            let view = UIImageView(image: nil)
            view.contentMode = .scaleAspectFit
            view.layer.cornerRadius = 8
            view.layer.masksToBounds = true
            return view
        }

        private init() { }
    }
}
