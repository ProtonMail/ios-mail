//
//  NewMailboxMessageCellPresenter.swift
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

import ProtonCore_DataModel
import ProtonCore_UIFoundations
import UIKit

class NewMailboxMessageCellPresenter {

    private let tagsPresenter = TagsPresenter()

    func present(viewModel: NewMailboxMessageViewModel, in view: NewMailboxMessageCellContentView) {
        view.initialsLabel.text = viewModel.initial.string
        view.initialsLabel.textAlignment = .center
        presentContent(viewModel: viewModel, in: view.messageContentView)
        presentTags(tags: viewModel.tags, in: view.messageContentView)
        presentSelectionStyle(style: viewModel.style, in: view)
    }

    func presentSelectionStyle(style: NewMailboxMessageViewStyle, in view: NewMailboxMessageCellContentView) {
        switch style {
        case .normal:
            view.initialsLabel.isHidden = false
            view.initialsContainer.isHidden = false
            view.checkBoxView.isHidden = true
            view.scheduledIconView.isHidden = true
            view.scheduledContainer.isHidden = true
        case .selection(let isSelected):
            view.initialsLabel.isHidden = true
            view.initialsContainer.isHidden = false
            view.checkBoxView.isHidden = false
            view.scheduledIconView.isHidden = true
            view.scheduledContainer.isHidden = true
            let backgroundColor: UIColor = isSelected ? ColorProvider.InteractionNorm : ColorProvider.BackgroundSecondary
            view.checkBoxView.backgroundColor = backgroundColor
            view.checkBoxView.tickImageView.image = isSelected ? IconProvider.checkmark : nil
            if #available(iOS 13, *) {
                view.checkBoxView.tickImageView.tintColor = ColorProvider.IconInverted
                    .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            } else {
                view.checkBoxView.tickImageView.tintColor = ColorProvider.IconInverted
            }
        case .scheduled:
            view.scheduledIconView.isHidden = false
            view.scheduledContainer.isHidden = false
            view.initialsContainer.isHidden = true
            view.initialsLabel.isHidden = true
            view.checkBoxView.isHidden = true
        }
    }

    private func presentTags(tags: [TagUIModel], in view: NewMailboxMessageContentView) {
        tagsPresenter.presentTags(tags: tags, in: view.tagsView)

        if tags.isEmpty {
            view.removeTagsView()
        } else {
            view.addTagsView()
        }
    }

    private func presentContent(viewModel: NewMailboxMessageViewModel, in view: NewMailboxMessageContentView) {
        view.forwardImageView.tintColor = viewModel.isRead ? ColorProvider.IconWeak : ColorProvider.IconNorm
        view.forwardImageView.isHidden = !viewModel.isForwarded

        view.replyImageView.tintColor = viewModel.isRead ? ColorProvider.IconWeak : ColorProvider.IconNorm
        view.replyImageView.isHidden = !viewModel.isReply

        view.replyAllImageView.tintColor = viewModel.isRead ? ColorProvider.IconWeak : ColorProvider.IconNorm
        view.replyAllImageView.isHidden = !viewModel.isReplyAll

        var sender = viewModel.sender
            .applyMutable(style: viewModel.isRead ? FontManager.DefaultWeak : FontManager.DefaultStrongBold)

        // Highlight search keywords
        if UserInfo.isEncryptedSearchEnabledFreeUsers || UserInfo.isEncryptedSearchEnabledPaidUsers {
            if userCachedStatus.isEncryptedSearchOn {
                sender = EncryptedSearchService.shared.addKeywordHighlightingToAttributedString(stringToHighlight: sender)
            }
        }
        view.senderLabel.attributedText = sender
        view.senderLabel.lineBreakMode = .byTruncatingTail

        if let scheduledTime = viewModel.scheduledTime {
            var style = viewModel.isRead ? FontManager.CaptionWeak : FontManager.CaptionStrong
            if viewModel.isScheduledTimeInNext10Mins {
                let color: UIColor = ColorProvider.NotificationError
                style[.foregroundColor] = color
            }
            let time = scheduledTime.apply(style: style)
            view.timeLabel.attributedText = time
        } else {
            let time = viewModel.time
                .apply(style: viewModel.isRead ? FontManager.CaptionWeak : FontManager.CaptionStrong)
            view.timeLabel.attributedText = time
        }
        view.timeLabel.lineBreakMode = .byTruncatingTail

        view.attachmentImageView.isHidden = !viewModel.hasAttachment

        view.starImageView.isHidden = !viewModel.isStarred

        var topic = viewModel.topic
            .applyMutable(style: viewModel.isRead ? FontManager.DefaultSmallWeak : FontManager.DefaultSmallStrong)

        // Highlight search keywords
        if UserInfo.isEncryptedSearchEnabledFreeUsers || UserInfo.isEncryptedSearchEnabledPaidUsers {
            if userCachedStatus.isEncryptedSearchOn {
                topic = EncryptedSearchService.shared.addKeywordHighlightingToAttributedString(stringToHighlight: topic)
            }
        }
        view.titleLabel.attributedText = topic
        view.titleLabel.lineBreakMode = .byTruncatingTail

        view.draftImageView.isHidden = viewModel.location != .draft

        let colorForCount = viewModel.isRead ? FontManager.OverlineSemiBoldTextWeak : FontManager.OverlineSemiBoldText
        let count = viewModel.messageCount > 1 ? "\(viewModel.messageCount)".apply(style: colorForCount) : nil
        view.messageCountLabel.isHidden = count == nil
        view.messageCountLabel.attributedText = count
        view.messageCountLabel.layer.borderColor = viewModel.isRead ?
            ColorProvider.TextWeak.cgColor : ColorProvider.TextNorm.cgColor

        guard viewModel.displayOriginIcon,
              !viewModel.folderIcons.isEmpty else {
            view.originalImagesStackView.isHidden = true
            view.removeOriginImages()
            return
        }
        view.originalImagesStackView.subviews.forEach { $0.removeFromSuperview() }
        viewModel.folderIcons.forEach { image in
            addOriginalImage(image, isRead: viewModel.isRead, in: view)
        }
        view.originalImagesStackView.isHidden = false
    }

    private func addOriginalImage(_ image: UIImage, isRead: Bool, in view: NewMailboxMessageContentView) {
        let viewToAdd = makeOriginalImageView(image, isRead: isRead)
        view.originalImagesStackView.addArrangedSubview(viewToAdd)
        [
            viewToAdd.heightAnchor.constraint(equalToConstant: 16),
            viewToAdd.widthAnchor.constraint(equalToConstant: 16)
        ].activate()
    }

    private func makeOriginalImageView(_ image: UIImage, isRead: Bool) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        imageView.tintColor = isRead ? ColorProvider.IconWeak : ColorProvider.IconNorm
        return imageView
    }
}

extension NewMailboxMessageViewModel {
    var displayOriginIcon: Bool {
        location == .allmail || location == .starred || isLabelLocation
    }

}
