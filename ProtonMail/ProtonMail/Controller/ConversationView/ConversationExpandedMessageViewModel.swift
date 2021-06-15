class ConversationExpandedMessageViewModel {

    var updateTableView: (() -> Void)? {
        didSet { messageContent.updateTableView = { [weak self] in self?.updateTableView?() } }
    }

    var storeHeight: (() -> Void)? {
        didSet { messageContent.storeHeight = { [weak self] in self?.storeHeight?() } }
    }

    var message: Message {
        didSet {
            messageContent.messageHasChanged(message: message)
            updateTableView?()
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
