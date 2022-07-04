import UIKit

class ConversationCollapsedMessageViewModel {

    private var message: MessageEntity {
        didSet { reloadView?(model) }
    }

    private let weekStart: WeekStart

    var reloadView: ((ConversationMessageModel) -> Void)?

    let replacingEmails: [Email]

    var model: ConversationMessageModel {
        let tags = message.orderedLabel.map { label in
            TagUIModel(title: label.name.apply(style: FontManager.OverlineSemiBoldTextInverted),
                         icon: nil,
                         color: UIColor(hexString: label.color, alpha: 1.0))
        }

        return ConversationMessageModel(
            messageLocation: message.messageLocation?.toMessageLocation,
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
            isDraft: message.isDraft
        )
    }

    init(message: MessageEntity, weekStart: WeekStart, replacingEmails: [Email]) {
        self.message = message
        self.weekStart = weekStart
        self.replacingEmails = replacingEmails
    }

    func messageHasChanged(message: MessageEntity) {
        self.message = message
    }

    private func date(of message: MessageEntity, weekStart: WeekStart) -> String {
        guard let date = message.time else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }

}
