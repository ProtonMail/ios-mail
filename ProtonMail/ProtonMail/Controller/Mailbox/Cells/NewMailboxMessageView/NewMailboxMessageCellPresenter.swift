//
//  NewMailboxMessageCellPresenter.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import PMUIFoundations
import UIKit

class NewMailboxMessageCellPresenter {

    private let tagsPresenter = TagsPresenter()

    func present(viewModel: NewMailboxMessageViewModel, in view: NewMailboxMessageCellContentView) {
        view.initialsLabel.attributedText = viewModel.initial
        view.initialsLabel.textAlignment = .center
        presentContent(viewModel: viewModel, in: view.messageContentView)
        presentTags(tags: viewModel.tags, in: view.messageContentView)
        presentSelectionStyle(style: viewModel.style, in: view)
    }

    func presentSelectionStyle(style: NewMailboxMessageViewStyle, in view: NewMailboxMessageCellContentView) {
        switch style {
        case .normal:
            view.initialsLabel.isHidden = false
            view.checkBoxView.isHidden = true
        case .selection(let isSelected):
            view.initialsLabel.isHidden = true
            view.checkBoxView.isHidden = false
            let backgroundColor = isSelected ? UIColorManager.InteractionNorm : UIColorManager.BackgroundSecondary
            view.checkBoxView.backgroundColor = backgroundColor
            view.checkBoxView.tickImageView.image = isSelected ? Asset.mailTickIcon.image : nil
        }
    }

    private func presentTags(tags: [TagViewModel], in view: NewMailboxMessageContentView) {
        tagsPresenter.presentTags(tags: tags, in: view.tagsView)

        tags.isEmpty ? view.removeTagsView() : view.addTagsView()
    }

    private func presentContent(viewModel: NewMailboxMessageViewModel, in view: NewMailboxMessageContentView) {
        view.forwardImageView.tintColor = viewModel.isRead ? UIColorManager.IconWeak : UIColorManager.IconNorm
        view.forwardImageView.isHidden = !viewModel.isForwarded

        view.replyImageView.tintColor = viewModel.isRead ? UIColorManager.IconWeak : UIColorManager.IconNorm
        view.replyImageView.isHidden = !viewModel.isReply

        view.replyAllImageView.tintColor = viewModel.isRead ? UIColorManager.IconWeak : UIColorManager.IconNorm
        view.replyAllImageView.isHidden = !viewModel.isReplyAll

        let sender = viewModel.sender
            .apply(style: viewModel.isRead ? FontManager.Default : FontManager.DefaultStrongBold)
        view.senderLabel.attributedText = sender
        view.senderLabel.lineBreakMode = .byTruncatingTail

        let time = viewModel.time
            .apply(style: viewModel.isRead ? FontManager.CaptionWeak : FontManager.CaptionStrong)
        view.timeLabel.attributedText = time
        view.timeLabel.lineBreakMode = .byTruncatingTail

        view.attachmentImageView.isHidden = !viewModel.hasAttachment

        view.starImageView.isHidden = !viewModel.isStarred

        let topic = viewModel.topic
            .apply(style: viewModel.isRead ? FontManager.DefaultSmallWeak : FontManager.DefaultSmallStrong)
        view.titleLabel.attributedText = topic
        view.titleLabel.lineBreakMode = .byTruncatingTail

        view.draftImageView.isHidden = viewModel.location != .draft

        if viewModel.displayOriginIcon {
            let isOriginHidden = viewModel.messageLocation?.originImage == nil && !viewModel.isCustomFolderLocation
            view.originImageView.isHidden = isOriginHidden
            let originImage = viewModel.isCustomFolderLocation ?
                Asset.mailCustomFolder.image : viewModel.messageLocation?.originImage
            view.originImageView.image = originImage
            view.originImageView.tintColor = viewModel.isRead ? UIColorManager.IconWeak : UIColorManager.IconNorm
        } else {
            view.originImageView.isHidden = true
        }
    }

}

extension NewMailboxMessageViewModel {

    var displayOriginIcon: Bool {
        location == .allmail || location == .starred || isLabelLocation || location == nil
    }

}
