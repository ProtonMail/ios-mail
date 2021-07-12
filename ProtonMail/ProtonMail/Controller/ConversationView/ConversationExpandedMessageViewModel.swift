class ConversationExpandedMessageViewModel {

    var recalculateCellHeight: (() -> Void)? {
        didSet { messageContent.recalcualteCellHeight = { [weak self] in self?.recalculateCellHeight?() } }
    }

    var message: Message {
        didSet {
            messageContent.messageHasChanged(message: message)
            recalculateCellHeight?()
        }
    }

    let messageContent: SingleMessageContentViewModel

    init(message: Message, messageContent: SingleMessageContentViewModel) {
        self.message = message
        self.messageContent = messageContent
    }

    func messageHasChanged(message: Message) {
        self.message = message
    }

}
