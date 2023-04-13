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

import ProtonCore_Foundations
import ProtonCore_UIFoundations
import UIKit

final class DownloadedMessagesInfoCell: UITableViewCell {
    private let stackView = SubviewFactory.stackView
    private let titleLabel = SubviewFactory.titleLabel
    private let subtitleTextview = SubviewFactory.subtitleTextview
    private let storageLabel = SubviewFactory.defaultLabel
    private let disabledLabel = SubviewFactory.disabledLabel

    private enum Layout {
        static let hMargin = 16.0
        static let vMargin = 12.0
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpView()
        setUpConstraints()
    }

    private func setUpView() {
        [storageLabel, disabledLabel].forEach { $0.isHidden = true }
        [titleLabel, subtitleTextview, storageLabel, disabledLabel].forEach {
            stackView.addArrangedSubview($0)
        }
        contentView.addSubview(stackView)
    }

    private func setUpConstraints() {
        [
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ].activate()
    }

    func configure(info: Info) {
        [storageLabel, disabledLabel].forEach { $0.isHidden = true }
        switch info {
        case .storage(let value):
            storageLabel.text = value.toByteCount
            storageLabel.isHidden = false
        case .disabled:
            disabledLabel.isHidden = false
        }
    }
}

extension DownloadedMessagesInfoCell {

    enum Info {
        case storage(ByteCount)
        case disabled
    }
}

extension DownloadedMessagesInfoCell {

    private enum SubviewFactory {

        static var stackView: UIStackView {
            let stack = UIStackView()
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.axis = .vertical
            stack.distribution = .equalSpacing
            stack.alignment = .leading
            stack.layoutMargins = UIEdgeInsets(
                top: Layout.vMargin,
                left: Layout.hMargin,
                bottom: Layout.vMargin,
                right: Layout.hMargin
            )
            stack.isLayoutMarginsRelativeArrangement = true
            stack.spacing = 8
            return stack
        }

        static var titleLabel: UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .adjustedFont(forTextStyle: .headline)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = ColorProvider.TextNorm
            label.numberOfLines = 0
            label.text = L11n.EncryptedSearch.downloaded_messages
            return label
        }

        static var subtitleTextview: UITextView {
            let textView = UITextView()
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.isScrollEnabled = false
            textView.isEditable = false
            textView.backgroundColor = .clear
            textView.font = .adjustedFont(forTextStyle: .footnote)
            textView.adjustsFontForContentSizeCategory = true
            textView.textContainer.lineFragmentPadding = 0
            textView.textContainerInset = .zero

            let text = LocalString._settings_local_storage_downloaded_messages_text
            let textLink = LocalString._settings_local_storage_downloaded_messages_text_link
            textView.setStyledTextWithLink(text: text, textLink: textLink, linkUrl: Link.encryptedSearchInfo)
            return textView
        }

        static var defaultLabel: UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.font = .adjustedFont(forTextStyle: .subheadline)
            label.adjustsFontForContentSizeCategory = true
            return label
        }

        static var disabledLabel: UILabel {
            let label = defaultLabel
            label.text = LocalString._settings_local_storage_downloaded_messages_text_disabled
            label.textColor = ColorProvider.NotificationError
            return label
        }
    }
}
