class ConversationExpandedMessageViewModel {

    var recalculateCellHeight: ((_ isLoaded: Bool) -> Void)? {
        didSet { messageContent.recalculateCellHeight = { [weak self] in self?.recalculateCellHeight?($0) } }
    }

    var resetLoadedHeight: (() -> Void)? {
        didSet { messageContent.resetLoadedHeight = { [weak self] in self?.resetLoadedHeight?() } }
    }

    var message: Message {
        didSet {
            messageContent.messageHasChanged(message: message)
            recalculateCellHeight?(false)
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
