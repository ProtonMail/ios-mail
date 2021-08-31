class ConversationCollapsedMessageViewModel {

    private var message: Message {
        didSet { reloadView?(model) }
    }

    private let weekStart: WeekStart

    var reloadView: ((ConversationMessageModel) -> Void)?

    var subject: String {
        message.subject
    }

    let replacingEmails: [Email]

    var model: ConversationMessageModel {
        .init(
            messageLocation: message.messageLocation,
            isCustomFolderLocation: message.isCustomFolder,
            initial: message.displaySender(replacingEmails).initials().apply(style: FontManager.body3RegularNorm),
            isRead: !message.unRead,
            sender: message.displaySender(replacingEmails),
            time: date(of: message, weekStart: weekStart),
            isForwarded: message.forwarded,
            isReplied: message.replied,
            isRepliedToAll: message.repliedAll,
            isStarred: message.starred,
            hasAttachment: message.numAttachments.intValue > 0,
            tags: message.orderedLabels.map { UIColor(hexString: $0.color, alpha: 1.0) },
            expirationTag: message.createTagFromExpirationDate
        )
    }

    init(message: Message, weekStart: WeekStart, replacingEmails: [Email]) {
        self.message = message
        self.weekStart = weekStart
        self.replacingEmails = replacingEmails
    }

    func messageHasChanged(message: Message) {
        self.message = message
    }

    private func date(of message: Message, weekStart: WeekStart) -> String {
        guard let date = message.time else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }

}
