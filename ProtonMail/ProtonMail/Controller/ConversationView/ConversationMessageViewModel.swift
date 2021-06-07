class ConversationMessageViewModel {

    let message: Message

    var state: ConversationMessageState

    init(message: Message, messageService: MessageDataService, contactService: ContactDataService) {
        self.message = message
        self.state = .collapsed(viewModel: .init(message: message, contactService: contactService))
    }

}
