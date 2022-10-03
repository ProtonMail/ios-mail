import ProtonCore_UIFoundations
import UIKit

class ConversationCollapsedMessageViewModel {

    private var message: MessageEntity {
        didSet { reloadView?(self.model(customFolderLabels: cachedCustomFolderLabels)) }
    }

    private let weekStart: WeekStart

    var reloadView: ((ConversationMessageModel) -> Void)?

    let replacingEmails: [Email]
    private var cachedCustomFolderLabels: [LabelEntity] = []

    private let dateFormatter: PMDateFormatter
    private let contactGroups: [ContactGroupVO]

    init(
        message: MessageEntity,
        weekStart: WeekStart,
        replacingEmails: [Email],
        contactGroups: [ContactGroupVO],
        dateFormatter: PMDateFormatter = .shared
    ) {
        self.message = message
        self.weekStart = weekStart
        self.replacingEmails = replacingEmails
        self.dateFormatter = dateFormatter
        self.contactGroups = contactGroups
    }

    func model(customFolderLabels: [LabelEntity]) -> ConversationMessageModel {
        cachedCustomFolderLabels = customFolderLabels
        let tags = message.orderedLabel.map { label in
            TagUIModel(
                title: label.name,
                titleColor: .white,
                titleWeight: .semibold,
                icon: nil,
                tagColor: UIColor(hexString: label.color, alpha: 1.0)
            )
        }

        return ConversationMessageModel(
            messageLocation: message
                .getFolderMessageLocation(customFolderLabels: customFolderLabels)?.toMessageLocation,
            isCustomFolderLocation: message.isCustomFolder,
            initial: message.displaySender(replacingEmails).initials().apply(style: FontManager.body3RegularNorm),
            isRead: !message.unRead,
            sender: message.getSenderName(replacingEmails: replacingEmails, groupContacts: contactGroups),
            time: date(of: message, weekStart: weekStart),
            isForwarded: message.isForwarded,
            isReplied: message.isReplied,
            isRepliedToAll: message.isRepliedAll,
            isStarred: message.isStarred,
            hasAttachment: message.numAttachments > 0,
            tags: tags,
            expirationTag: message.createTagFromExpirationDate(),
            isDraft: message.isDraft,
            isScheduled: message.contains(location: .scheduled),
            isSent: message.isSent
        )
    }

    func messageHasChanged(message: MessageEntity) {
        self.message = message
    }

    private func date(of message: MessageEntity, weekStart: WeekStart) -> String {
        guard let date = message.time else { return .empty }
        if message.isScheduledSend {
            return dateFormatter.stringForScheduledMsg(from: date, inListView: true)
        } else {
            return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
        }
    }
}
