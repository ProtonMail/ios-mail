import UIKit

class ConversationCollapsedMessageViewModel {

    private var message: MessageEntity {
        didSet { reloadView?(self.model(customFolderLabels: cachedCustomFolderLabels)) }
    }

    private let weekStart: WeekStart

    var reloadView: ((ConversationMessageModel) -> Void)?

    let replacingEmails: [Email]
    private var cachedCustomFolderLabels: [LabelEntity] = []

    init(message: MessageEntity, weekStart: WeekStart, replacingEmails: [Email]) {
        self.message = message
        self.weekStart = weekStart
        self.replacingEmails = replacingEmails
    }

    func model(customFolderLabels: [LabelEntity]) -> ConversationMessageModel {
        cachedCustomFolderLabels = customFolderLabels
        let tags = message.orderedLabel.map { label in
            TagUIModel(title: label.name.apply(style: FontManager.OverlineSemiBoldTextInverted),
                       icon: nil,
                       color: UIColor(hexString: label.color, alpha: 1.0))
        }

        return ConversationMessageModel(
            messageLocation: message
                .getFolderMessageLocation(customFolderLabels: customFolderLabels)?.toMessageLocation,
            isCustomFolderLocation: message.isCustomFolder,
            initial: message.displaySender(replacingEmails).initials().apply(style: FontManager.body3RegularNorm),
            isRead: !message.unRead,
            sender: message.displaySender(replacingEmails),
            time: date(of: message, weekStart: weekStart),
            isForwarded: message.isForwarded,
            isReplied: message.isReplied,
            isRepliedToAll: message.isRepliedAll,
            isStarred: message.isStarred,
            hasAttachment: message.numAttachments > 0,
            tags: tags,
            expirationTag: message.createTagFromExpirationDate(),
            isDraft: message.isDraft,
            isSent: message.isSent
        )
    }

    func messageHasChanged(message: MessageEntity) {
        self.message = message
    }

    private func date(of message: MessageEntity, weekStart: WeekStart) -> String {
        guard let date = message.time else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }

}
