import ProtonCoreUIFoundations
import UIKit

class ConversationMessageCellPresenter {
    private let tagsPresenter = TagsPresenter()

    func present(model: ConversationMessageModel, in view: ConversationMessageView, highlightedKeywords: [String]) {
        presentInitialsView(model: model, in: view)
        presentTexts(model: model, in: view, highlightedKeywords: highlightedKeywords)
        presentIcons(model: model, in: view)
        presentOrigin(model: model, in: view)
        presentSentLocation(model: model, in: view)
        presentTags(model: model, in: view)
    }

    func present(senderImage: UIImage, in view: ConversationMessageView) {
        view.senderImageView.image = senderImage
        view.initialsLabel.isHidden = true
    }

    private func presentInitialsView(model: ConversationMessageModel, in view: ConversationMessageView) {
        if let initials = model.initial {
            view.initialsLabel.isHidden = false
            view.initialsIcon.isHidden = true
            view.scheduledIcon.isHidden = true
            view.initialsLabel.text = initials.string
            view.initialsLabel.textAlignment = .center
        }

        if model.messageLocation == .draft || model.isDraft {
            view.initialsLabel.isHidden = true
            view.initialsIcon.isHidden = false
            view.scheduledIcon.isHidden = true
        }

        if model.isScheduled {
            view.initialsLabel.isHidden = true
            view.initialsIcon.isHidden = true
            view.scheduledIcon.isHidden = false
            view.initialsContainer.backgroundColor = .clear
        }
    }

    private func presentTexts(
        model: ConversationMessageModel,
        in view: ConversationMessageView,
        highlightedKeywords: [String]
    ) {
        let color: UIColor = model.isRead ? ColorProvider.TextWeak : ColorProvider.TextNorm
        let weight: UIFont.Weight = model.isRead ? .regular : .semibold
        view.timeLabel.set(text: model.time,
                           preferredFont: .footnote,
                           weight: weight,
                           textColor: color)

        view.configureSenderRow(
            components: model.sender,
            highlightedKeywords: highlightedKeywords,
            preferredFont: .subheadline,
            weight: weight,
            textColor: color
        )
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
        IconProvider.folder :
        model.messageLocation?.originImage(viewMode: .conversation,
                                           isAutoDeletingMessage: model.isAutoDeletingMessage)
        view.originImageView.image = originImage
        view.originImageView.tintColor = model.isRead ? ColorProvider.IconWeak : ColorProvider.IconNorm
    }

    private func presentTags(model: ConversationMessageModel, in view: ConversationMessageView) {
        view.expirationView.isHidden = model.expirationTag == nil || !model.isExpirationFrozen

        if let expirationTag = model.expirationTag {
            view.expirationView.tagLabel.set(text: expirationTag.title,
                                             preferredFont: .caption1,
                                             weight: expirationTag.titleWeight,
                                             textColor: expirationTag.titleColor)
            view.expirationView.backgroundColor = expirationTag.tagColor
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
