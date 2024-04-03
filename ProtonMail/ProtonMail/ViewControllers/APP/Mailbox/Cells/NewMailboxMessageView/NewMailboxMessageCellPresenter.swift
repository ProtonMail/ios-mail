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

import ProtonCoreUIFoundations
import UIKit

class NewMailboxMessageCellPresenter {

    private let tagsPresenter = TagsPresenter()

    func present(
        viewModel: NewMailboxMessageViewModel,
        in view: NewMailboxMessageCellContentView,
        highlightedKeywords: [String] = []
    ) {
        view.initialsLabel.set(text: viewModel.initial,
                               preferredFont: .footnote,
                               weight: .regular)
        view.initialsLabel.textAlignment = .center
        presentContent(viewModel: viewModel, in: view.messageContentView, highlightedKeywords: highlightedKeywords)
        presentAttachmentsPreview(viewModel: viewModel, in: view.messageContentView)
        presentTags(tags: viewModel.tags, in: view.messageContentView)
        presentSelectionStyle(style: viewModel.style, in: view)
        updateCustomSpacing(viewModel: viewModel, in: view.messageContentView)
    }

    func presentSelectionStyle(style: NewMailboxMessageViewStyle, in view: NewMailboxMessageCellContentView) {
        switch style {
        case .normal:
            view.initialsContainer.isHidden = false
            view.checkBoxView.isHidden = true
            view.scheduledIconView.isHidden = true
            view.scheduledContainer.isHidden = true

        case let .selection(isSelected, isAbleToBeSelected):
            view.initialsContainer.isHidden = false
            view.checkBoxView.isHidden = false
            view.scheduledIconView.isHidden = true
            view.scheduledContainer.isHidden = true

            let backgroundColor: UIColor
            let borderColor: UIColor
            if isSelected {
                backgroundColor = ColorProvider.InteractionNorm
                view.checkBoxView.tickImageView.image = IconProvider.checkmark
                borderColor = ColorProvider.InteractionNorm
            } else {
                backgroundColor = isAbleToBeSelected ? ColorProvider.BackgroundSecondary : ColorProvider.BackgroundNorm
                view.checkBoxView.tickImageView.image = nil
                borderColor = isAbleToBeSelected ? ColorProvider.InteractionNorm : ColorProvider.SeparatorNorm
            }
            view.checkBoxView.backgroundColor = backgroundColor
            view.checkBoxView.tickImageView.tintColor = ColorProvider.IconInverted
                .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            view.checkBoxView.layer.borderColor = borderColor.cgColor
        case .scheduled:
            view.scheduledIconView.isHidden = false
            view.scheduledContainer.isHidden = false
            view.initialsContainer.isHidden = true
            view.initialsLabel.isHidden = true
            view.checkBoxView.isHidden = true
        }
    }

    func presentSenderImage(_ image: UIImage, in view: NewMailboxMessageCellContentView) {
        view.senderImageView.image = image
        view.senderImageView.isHidden = false
        view.initialsLabel.isHidden = true
    }

    private func presentTags(tags: [TagUIModel], in view: NewMailboxMessageContentView) {
        tagsPresenter.presentTags(tags: tags, in: view.tagsView)

        if tags.isEmpty {
            view.removeTagsView()
        } else {
            view.addTagsView()
        }
    }

    // swiftlint:disable:next function_body_length
    private func presentContent(
        viewModel: NewMailboxMessageViewModel,
        in view: NewMailboxMessageContentView,
        highlightedKeywords: [String] = []
    ) {
        view.forwardImageView.tintColor = viewModel.isRead ? ColorProvider.IconWeak : ColorProvider.IconNorm
        view.forwardImageView.isHidden = !viewModel.isForwarded

        view.replyImageView.tintColor = viewModel.isRead ? ColorProvider.IconWeak : ColorProvider.IconNorm
        view.replyImageView.isHidden = !viewModel.isReply || viewModel.isReplyAll

        view.replyAllImageView.tintColor = viewModel.isRead ? ColorProvider.IconWeak : ColorProvider.IconNorm
        view.replyAllImageView.isHidden = !viewModel.isReplyAll

        let color: UIColor = viewModel.isRead ? ColorProvider.TextWeak : ColorProvider.TextNorm
        view.configureSenderRow(
            components: viewModel.sender,
            highlightedKeywords: highlightedKeywords,
            preferredFont: .body,
            weight: viewModel.isRead ? .regular : .bold,
            textColor: color
        )

        let weight: UIFont.Weight = viewModel.isRead ? .regular : .semibold
        if let scheduledTime = viewModel.scheduledTime {
            var scheduledColor = color
            if viewModel.isScheduledTimeInNext10Mins {
                scheduledColor = ColorProvider.NotificationError
            }
            view.timeLabel.set(text: scheduledTime,
                               preferredFont: .footnote,
                               weight: weight,
                               textColor: scheduledColor)
        } else if viewModel.hasShowReminderFlag, let reminderTime = viewModel.reminderTime {
            view.timeLabel.set(
                text: reminderTime,
                preferredFont: .footnote,
                weight: weight,
                textColor: ColorProvider.NotificationWarning
            )
        } else {
            view.timeLabel.set(text: viewModel.time,
                               preferredFont: .footnote,
                               weight: weight,
                               textColor: color)
        }

        view.titleLabel.set(text: viewModel.topic.keywordHighlighting.asAttributedString(keywords: highlightedKeywords),
                            preferredFont: .subheadline,
                            weight: weight,
                            textColor: color)

        view.attachmentImageView.isHidden = !viewModel.hasAttachment
        view.starImageView.isHidden = !viewModel.isStarred
        view.draftImageView.isHidden = viewModel.location != .draft

        let count = viewModel.messageCount > 1 ? "\(viewModel.messageCount)" : nil
        view.messageCountLabel.isHidden = count == nil
        view.messageCountLabel.set(text: count,
                                   preferredFont: .caption2,
                                   weight: .semibold,
                                   textColor: color)
        view.messageCountLabel.layer.borderColor = viewModel.isRead ?
            ColorProvider.TextWeak.cgColor : ColorProvider.TextNorm

        if viewModel.hasSnoozeLabel, let snoozeTime = viewModel.snoozeTime {
            view.snoozeTimeLabel.set(
                text: snoozeTime,
                preferredFont: .footnote,
                weight: .bold,
                textColor: ColorProvider.NotificationWarning
            )
            view.snoozeTimeStackView.isHidden = false
        } else {
            view.snoozeTimeStackView.isHidden = true
        }

        guard !viewModel.folderIcons.isEmpty else {
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

    private func presentAttachmentsPreview(
        viewModel: NewMailboxMessageViewModel,
        in view: NewMailboxMessageContentView
    ) {
        let maxNumberOfPreviews: Int
        if UIDevice.current.userInterfaceIdiom == .pad ||
           UIDevice.current.orientation == .landscapeLeft ||
           UIDevice.current.orientation == .landscapeRight {
            maxNumberOfPreviews = 3
        } else {
            maxNumberOfPreviews = 2
        }

        let attachmentsVMs = viewModel.attachmentsPreviewViewModels.prefix(maxNumberOfPreviews)

        guard !attachmentsVMs.isEmpty else {
            return
        }

        view.attachmentImageView.isHidden = true
        let remainder = viewModel.numberOfAttachments - attachmentsVMs.count

        for (index, attachmentToPreview) in attachmentsVMs.enumerated() {
            let attachmentPreviewView = AttachmentPreviewView(attachmentPreview: attachmentToPreview)
            attachmentPreviewView.attachmentSelected = { [weak view] in
                view?.selectAttachmentAction?(index)
            }
            view.attachmentsPreviewStackView.addArrangedSubview(attachmentPreviewView)
        }

        view.attachmentsPreviewStackView.addArrangedSubview(UIView())

        if remainder > 0 {
            let style = FontManager.Caption.foregroundColor(ColorProvider.TextWeak)
            view.remainingAttachmentsLabel.attributedText = "+\(remainder)".apply(style: style)
        }

        view.attachmentsPreviewStackView.distribution = .fillProportionally
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

    private func updateCustomSpacing(viewModel: NewMailboxMessageViewModel, in view: NewMailboxMessageContentView) {
        let hasAttachments = !viewModel.attachmentsPreviewViewModels.isEmpty
        let space1: CGFloat = hasAttachments ? 8 : 0
        view.contentStackView.setCustomSpacing(space1, after: view.secondLineStackView)

        let hasTags = !viewModel.tags.isEmpty
        let space2: CGFloat = hasTags ? 4 : 0
        view.contentStackView.setCustomSpacing(space2, after: view.attachmentsPreviewLine)

        let space3: CGFloat = viewModel.hasSnoozeLabel ? 4 : 0
        view.contentStackView.setCustomSpacing(space3, after: view.tagsView)
    }
}
