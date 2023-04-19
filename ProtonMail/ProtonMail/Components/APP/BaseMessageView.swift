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

class BaseMessageView: UIView {
    let sendersStackView = UIStackView.stackView(alignment: .center, spacing: 2)
    let attachmentImageView = SubviewsFactory.attachmentImageView
    let forwardImageView = SubviewsFactory.forwardImageView
    let replyAllImageView = SubviewsFactory.replyAllImageView
    let replyImageView = SubviewsFactory.replyImageView
    let starImageView = SubviewsFactory.starImageView
    let tagsView = SingleRowTagsView()
    let timeLabel = UILabel()

    func configureSenderRow(
        components: [SenderRowComponent],
        preferredFont: UIFont.TextStyle,
        weight: UIFont.Weight,
        textColor: UIColor
    ) {
        sendersStackView.clearAllViews()

        let views: [UIView] = components.map { component in
            switch component {
            case .string(let string):
                let label = UILabel()
                label.lineBreakMode = .byTruncatingTail
                label.set(text: string, preferredFont: preferredFont, weight: weight, textColor: textColor)
                return label
            case .officialBadge:
                return OfficialBadge()
            }
        }

        for (index, view) in views.enumerated() {
            // subsequent views have lower resistance to emulate truncation
            let priority = UILayoutPriority(rawValue: UILayoutPriority.required.rawValue - Float(index + 1))
            view.setContentCompressionResistancePriority(priority, for: .horizontal)

            sendersStackView.addArrangedSubview(view)
        }
    }
}

extension BaseMessageView {
    class SubviewsFactory {
        class var attachmentImageView: UIImageView {
            .make(icon: \.paperClip, tintColor: \.IconNorm)
        }

        class var draftImageView: UIImageView {
            .make(icon: \.pencil, tintColor: \.IconNorm)
        }

        class var forwardImageView: UIImageView {
            .make(icon: \.arrowRight, tintColor: \.IconNorm)
        }

        class var replyImageView: UIImageView {
            .make(icon: \.arrowUpAndLeft, tintColor: \.IconNorm)
        }

        class var replyAllImageView: UIImageView {
            .make(icon: \.arrowsUpAndLeft, tintColor: \.IconNorm)
        }

        class var starImageView: UIImageView {
            .make(icon: \.starFilled, tintColor: \.NotificationWarning)
        }
    }
}
