class SingleMessageViewModel {

    let message: Message
    private(set) var starred: Bool
    private(set) lazy var userActivity: NSUserActivity = .messageDetailsActivity(messageId: message.messageID)

    private let messageService: MessageDataService
    private let labelId: String

    init(labelId: String, message: Message, messageService: MessageDataService) {
        self.labelId = labelId
        self.message = message
        self.starred = message.starred
        self.messageService = messageService
    }

    func starTapped() {
        starred.toggle()
        messageService.label(messages: [message], label: Message.Location.starred.rawValue, apply: starred)
    }

    func markReadIfNeeded() {
        guard message.unRead else { return }
        messageService.mark(messages: [message], labelID: labelId, unRead: false)
    }

}

private extension MessageDataService {

    func fetchMessage(messageId: String) -> Message? {
        fetchMessages(withIDs: .init(array: [messageId]), in: CoreDataService.shared.mainContext).first
    }

}
