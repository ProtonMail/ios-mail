class ConversationCollapsedMessageViewModel {

    private var message: Message {
        didSet { reloadView?(model) }
    }

    private let contactService: ContactDataService

    var reloadView: ((ConversationMessageModel) -> Void)?

    var subject: String {
        message.subject
    }

    var replacingEmails: [Email] {
        contactService.allEmails()
    }

    var model: ConversationMessageModel {
        .init(
            messageLocation: message.messageLocation,
            isCustomFolderLocation: message.isCustomFolder,
            initial: message.initial(replacingEmails: replacingEmails).apply(style: FontManager.body3RegularNorm),
            isRead: !message.unRead,
            sender: message.sender(replacingEmails: replacingEmails),
            time: message.messageTime,
            isForwarded: message.forwarded,
            isReplied: message.replied,
            isRepliedToAll: message.repliedAll,
            isStarred: message.starred,
            hasAttachment: message.numAttachments.intValue > 0,
            tags: message.orderedLabels.map { UIColor(hexString: $0.color, alpha: 1.0) },
            expirationTag: message.createTagFromExpirationDate
        )
    }

    init(message: Message, contactService: ContactDataService) {
        self.message = message
        self.contactService = contactService
    }

    func messageHasChanged(message: Message) {
        self.message = message
    }

}
