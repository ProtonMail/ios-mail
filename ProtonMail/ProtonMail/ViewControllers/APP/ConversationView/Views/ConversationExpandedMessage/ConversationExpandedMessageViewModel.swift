class ConversationExpandedMessageViewModel {

    var recalculateCellHeight: ((_ isLoaded: Bool) -> Void)? {
        didSet { messageContent.recalculateCellHeight = { [weak self] in self?.recalculateCellHeight?($0) } }
    }

    var resetLoadedHeight: (() -> Void)? {
        didSet { messageContent.resetLoadedHeight = { [weak self] in self?.resetLoadedHeight?() } }
    }

    var message: MessageEntity {
        didSet {
            messageContent.messageHasChanged(message: message)
            recalculateCellHeight?(false)
        }
    }

    let messageContent: SingleMessageContentViewModel

    init(message: MessageEntity, messageContent: SingleMessageContentViewModel) {
        self.message = message
        self.messageContent = messageContent
    }

    func messageHasChanged(message: MessageEntity) {
        self.message = message
    }

}
