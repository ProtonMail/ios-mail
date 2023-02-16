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
import ProtonCore_Utilities
import UIKit

final class EncryptedSearchBannerFooterView: UITableViewHeaderFooterView {
    private let container = SubviewFactory.container
    private let stackView = SubviewFactory.stackView
    private let iconView = SubviewFactory.iconImageView
    private let messageLabel = SubviewFactory.messageLabel

    private enum Layout {
        static let containerMargin = 16.0
        static let hMargin = 16.0
        static let vMargin = 12.0
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setUpUI()
        setUpConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpUI() {
        [iconView, messageLabel].forEach {
            stackView.addArrangedSubview($0)
        }
        container.addSubview(stackView)
        addSubview(container)
    }

    private func setUpConstraints() {
        [
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.containerMargin),
            container.topAnchor.constraint(equalTo: topAnchor, constant: Layout.containerMargin),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.containerMargin),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.containerMargin),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: container.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ].activate()
    }
}

extension EncryptedSearchBannerFooterView {

    private enum SubviewFactory {

        static var stackView: UIStackView {
            let stack = UIStackView()
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.axis = .horizontal
            stack.distribution = .fill
            stack.spacing = 10
            stack.layoutMargins = UIEdgeInsets(
                top: Layout.vMargin,
                left: Layout.hMargin,
                bottom: Layout.vMargin,
                right: Layout.hMargin
            )
            stack.isLayoutMarginsRelativeArrangement = true
            return stack
        }

        static var container: UIView {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = UIColor(RRGGBB: UInt(0x25272C))
            view.layer.cornerRadius = 8
            view.layer.masksToBounds = true
            return view
        }

        static var iconImageView: UIImageView {
            let imageView = UIImageView(image: IconProvider.exclamationCircle)
            imageView.tintColor = ColorProvider.White
            imageView.contentMode = .scaleAspectFit
            return imageView
        }

        static var messageLabel: UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .adjustedFont(forTextStyle: .footnote)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = .white
            label.numberOfLines = 0
            label.text = L11n.EncryptedSearch.download_will_stop_desc
            return label
        }
    }
}
