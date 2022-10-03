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

import ProtonCore_UIFoundations
import UIKit

class NewMailboxMessageCellPresenter {

    private let tagsPresenter = TagsPresenter()

    func present(viewModel: NewMailboxMessageViewModel, in view: NewMailboxMessageCellContentView) {
        view.initialsLabel.set(text: viewModel.initial,
                               preferredFont: .footnote,
                               weight: .regular)
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

        let color: UIColor = viewModel.isRead ? ColorProvider.TextWeak: ColorProvider.TextNorm
        view.senderLabel.set(text: viewModel.sender,
                             preferredFont: .body,
                             weight: viewModel.isRead ? .regular: .bold,
                             textColor: color)

        let weight: UIFont.Weight = viewModel.isRead ? .regular: .semibold
        if let scheduledTime = viewModel.scheduledTime {
            var scheduledColor = color
            if viewModel.isScheduledTimeInNext10Mins {
                scheduledColor = ColorProvider.NotificationError
            }
            view.timeLabel.set(text: scheduledTime,
                               preferredFont: .footnote,
                               weight: weight,
                               textColor: scheduledColor)
        } else {
            view.timeLabel.set(text: viewModel.time,
                               preferredFont: .footnote,
                               weight: weight,
                               textColor: color)
        }

        view.titleLabel.set(text: viewModel.topic,
                            preferredFont: .body,
                            weight: weight,
                            textColor: color)

        view.attachmentImageView.isHidden = !viewModel.hasAttachment
        view.starImageView.isHidden = !viewModel.isStarred
        view.draftImageView.isHidden = viewModel.location != .draft

        let count = viewModel.messageCount > 1 ? "\(viewModel.messageCount)": nil
        view.messageCountLabel.isHidden = count == nil
        view.messageCountLabel.set(text: count,
                                   preferredFont: .caption2,
                                   weight: .semibold,
                                   textColor: color)
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
