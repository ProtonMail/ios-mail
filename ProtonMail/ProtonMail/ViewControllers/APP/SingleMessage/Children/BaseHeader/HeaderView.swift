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
    let senderLabel = SubviewsFactory.senderLabel
    let lockImageView = SubviewsFactory.lockImageView
    let lockImageControl = UIControl(frame: .zero)
    let timeLabel = SubviewsFactory.timeLabel
    let starImageView = SubviewsFactory.starImageView
    private(set) lazy var lockContainer = StackViewContainer(view: lockImageControl, top: 4)

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

        private init() { }
    }
}
