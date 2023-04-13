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

final class EncryptedSearchDownloadedMessagesCell: UITableViewCell {
    private let stackView = SubviewFactory.stackView
    private let titleStackView = SubviewFactory.titleStackView
    private let iconView = SubviewFactory.iconImageView
    private let titleLabel = SubviewFactory.titleLabel
    private let oldestMessageLabel = SubviewFactory.infoLabel
    private let additionalInfoLabel = SubviewFactory.infoLabel

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
        [iconView, titleLabel].forEach {
            titleStackView.addArrangedSubview($0)
        }
        [titleStackView, oldestMessageLabel, additionalInfoLabel].forEach {
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

    func configure(info: DownloadedMessagesInfo) {
        iconView.image = info.icon.image
        iconView.tintColor = info.icon.tintColor
        titleLabel.text = info.title.string
        oldestMessageLabel.attributedText = info.oldestMessage.attributedString
        oldestMessageLabel.isHidden = oldestMessageLabel.attributedText == nil
        additionalInfoLabel.attributedText = info.additionalInfo.attributedString
    }
}

extension EncryptedSearchDownloadedMessagesCell {

    struct DownloadedMessagesInfo {
        let icon: Icon
        let title: Title
        let oldestMessage: OldestMessage
        let additionalInfo: AdditionalInfo
    }

    enum Icon {
        case success
        case warning

        var image: UIImage {
            switch self {
            case .success:
                return IconProvider.checkmark
            case .warning:
                return IconProvider.exclamationCircleFilled
            }
        }

        var tintColor: UIColor {
            switch self {
            case .success:
                return ColorProvider.NotificationSuccess
            case .warning:
                return ColorProvider.NotificationWarning
            }
        }
    }

    enum Title {
        case downlodedMessages
        case messageHistory

        var string: String {
            switch self {
            case .downlodedMessages:
                return L11n.EncryptedSearch.downloaded_messages
            case .messageHistory:
                return LocalString._settings_title_of_message_history
            }
        }
    }

    struct OldestMessage {
        let date: String?
        let highlight: Bool

        var attributedString: NSAttributedString? {
            guard let date = date else { return nil }
            let prefix = L11n.EncryptedSearch.downloaded_messages_oldest_message
            let message = prefix + date
            let messageAttrString = NSMutableAttributedString(string: message)
            let rangeOfPrefix = NSRange(location: 0, length: message.count)
            messageAttrString.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: ColorProvider.TextWeak as UIColor,
                range: rangeOfPrefix
            )
            let rangeDate = NSRange(location: prefix.count, length: date.count)
            if highlight {
                messageAttrString.addAttribute(
                    NSAttributedString.Key.foregroundColor,
                    value: ColorProvider.NotificationError as UIColor,
                    range: rangeDate
                )
            }
            return messageAttrString
        }
    }

    enum AdditionalInfo {
        case storageUsed(valueInMB: String)
        case allMessagesDownloaded
        case errorOutOfMemory
        case errorLowStorage

        var string: String {
            switch self {
            case .storageUsed(let valueInMB):
                return valueInMB
            case .allMessagesDownloaded:
                return LocalString._settings_message_history_status_all_downloaded
            case .errorOutOfMemory:
                return LocalString._settings_message_history_status_partial_index
            case .errorLowStorage:
                return LocalString._settings_message_history_status_low_storage
            }
        }

        var attributedString: NSAttributedString {
            switch self {
            case .storageUsed(let valueInMB):
                return storageUsed(valueInMB: valueInMB)
            case .allMessagesDownloaded:
                return allMessagesDownloaded(message: string)
            case .errorOutOfMemory, .errorLowStorage:
                return errorMessage(string)
            }
        }

        private func allMessagesDownloaded(message: String) -> NSAttributedString {
            let messageAttrString = NSMutableAttributedString(string: message)
            let rangeOfPrefix = NSRange(location: 0, length: message.count)
            messageAttrString.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: ColorProvider.TextWeak as UIColor,
                range: rangeOfPrefix
            )
            return messageAttrString
        }

        private func storageUsed(valueInMB: String) -> NSAttributedString {
            let prefix = L11n.EncryptedSearch.downloaded_messages_storage_used
            let message = prefix + valueInMB
            let messageAttrString = NSMutableAttributedString(string: message)
            let rangeOfPrefix = NSRange(location: 0, length: prefix.count)
            messageAttrString.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: ColorProvider.TextWeak as UIColor,
                range: rangeOfPrefix
            )
            let rangeOfValue = NSRange(location: prefix.count, length: valueInMB.count)
            messageAttrString.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: ColorProvider.TextNorm as UIColor,
                range: rangeOfValue
            )
            return messageAttrString
        }

        private func errorMessage(_ message: String) -> NSAttributedString {
            let downloadStatus = NSMutableAttributedString(string: message)
            downloadStatus.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: ColorProvider.NotificationError as UIColor,
                range: NSRange(location: 0, length: message.count)
            )
            return downloadStatus
        }
    }
}

extension EncryptedSearchDownloadedMessagesCell {

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

        static var titleStackView: UIStackView {
            let stack = UIStackView()
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.axis = .horizontal
            stack.distribution = .equalSpacing
            stack.isLayoutMarginsRelativeArrangement = true
            stack.spacing = 8
            return stack
        }

        static var iconImageView: UIImageView {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }

        static var titleLabel: UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .adjustedFont(forTextStyle: .headline)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = ColorProvider.TextNorm
            label.numberOfLines = 0
            return label
        }

        static var infoLabel: UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .adjustedFont(forTextStyle: .footnote)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            return label
        }
    }
}
