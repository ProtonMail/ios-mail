import ProtonCore_UIFoundations
import UIKit

class ConversationMessageCellPresenter {
    private let tagsPresenter = TagsPresenter()

    func present(model: ConversationMessageModel, in view: ConversationMessageView) {
        presentInitialsView(model: model, in: view)
        presentTexts(model: model, in: view)
        presentIcons(model: model, in: view)
        presentOrigin(model: model, in: view)
        presentSentLocation(model: model, in: view)
        presentTags(model: model, in: view)
    }

    private func presentInitialsView(model: ConversationMessageModel, in view: ConversationMessageView) {
        if let initials = model.initial {
            view.initialsLabel.isHidden = false
            view.initialsIcon.isHidden = true
            view.initialsLabel.text = initials.string
            view.initialsLabel.textAlignment = .center
        }

        if model.messageLocation == .draft || model.isDraft {
            view.initialsLabel.isHidden = true
            view.initialsIcon.isHidden = false
        }
    }

    private func presentTexts(model: ConversationMessageModel, in view: ConversationMessageView) {
        let timeStyle = model.isRead ? FontManager.CaptionWeak : FontManager.CaptionStrong
        let time = model.time.apply(style: timeStyle.lineBreakMode(.byTruncatingTail))
        view.timeLabel.attributedText = time

        let senderStyle = model.isRead ? FontManager.DefaultSmallWeak : FontManager.DefaultSmallStrong
        let sender = model.sender.apply(style: senderStyle.lineBreakMode(.byTruncatingTail))
        view.senderLabel.attributedText = sender
    }

    private func presentIcons(model: ConversationMessageModel, in view: ConversationMessageView) {
        view.replyImageView.isHidden = !model.isReplied
        view.replyImageView.tintColor = model.isRead ? ColorProvider.IconWeak : ColorProvider.IconNorm

        view.replyAllImageView.isHidden = !model.isRepliedToAll
        view.replyAllImageView.tintColor = model.isRead ? ColorProvider.IconWeak : ColorProvider.IconNorm

        view.forwardImageView.isHidden = !model.isForwarded
        view.forwardImageView.tintColor = model.isRead ? ColorProvider.IconWeak : ColorProvider.IconNorm

        view.attachmentImageView.isHidden = !model.hasAttachment

        view.starImageView.isHidden = !model.isStarred
    }

    private func presentOrigin(model: ConversationMessageModel, in view: ConversationMessageView) {
        view.originImageView.isHidden = model.messageLocation == nil && model.isCustomFolderLocation == false

        let originImage = model.isCustomFolderLocation ?
        IconProvider.folder : model.messageLocation?.originImage(viewMode: .conversation)
        view.originImageView.image = originImage
        view.originImageView.tintColor = model.isRead ? ColorProvider.IconWeak : ColorProvider.IconNorm
    }

    private func presentTags(model: ConversationMessageModel, in view: ConversationMessageView) {
        view.expirationView.isHidden = model.expirationTag == nil

        if let expirationTag = model.expirationTag {
            view.expirationView.tagLabel.attributedText = expirationTag.title
            view.expirationView.backgroundColor = expirationTag.color
            view.expirationView.imageView.image = expirationTag.icon
            view.expirationView.imageView.tintColor = ColorProvider.IconNorm
        }
        tagsPresenter.presentTags(tags: model.tags, in: view.tagsView)
    }

    private func presentSentLocation(model: ConversationMessageModel, in view: ConversationMessageView) {
        // message is sent to self.
        if model.isSent && model.messageLocation != .sent {
            view.sentImageView.isHidden = false
        } else {
            view.sentImageView.isHidden = true
        }
    }
}
