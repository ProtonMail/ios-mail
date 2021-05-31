class ConversationViewModel {

    var dataSource: [ConversationViewItemType] = [] {
        didSet {
            reloadTableView?()
        }
    }

    var reloadTableView: (() -> Void)?

    var messagesTitle: String {
        .localizedStringWithFormat(LocalString._general_message, conversation.numMessages.intValue)
    }

    var simpleNavigationViewType: NavigationViewType {
        .simple(numberOfMessages: messagesTitle.apply(style: FontManager.body3RegularWeak))
    }

    var detailedNavigationViewType: NavigationViewType {
        .detailed(
            subject: conversation.subject.apply(style: FontManager.DefaultSmallStrong.lineBreakMode(.byTruncatingTail)),
            numberOfMessages: messagesTitle.apply(style: FontManager.OverlineRegularTextWeak)
        )
    }

    private let conversation: Conversation
    private let conversationMessagesProvider: ConversationMessagesProvider
    private let messageService: MessageDataService
    private let contactService: ContactDataService

    private var header: ConversationViewItemType {
        .header(subject: conversation.subject)
    }

    init(conversation: Conversation, messageService: MessageDataService, contactService: ContactDataService) {
        self.conversation = conversation
        self.messageService = messageService
        self.contactService = contactService
        self.conversationMessagesProvider = ConversationMessagesProvider(conversation: conversation)
        observeConversationMessages()
    }

    func fetchConversationDetails() {
        messageService.fetchConversationDetail(by: conversation.conversationID) { _ in }
    }

    func observeConversationMessages() {
        conversationMessagesProvider.observe { [weak self] messages in
            self?.refreshDataSource(with: messages)
        }
    }

    func refreshDataSource(with messages: [Message]) {
        dataSource = [header] + messages.map {
            .message(viewModel: .init(message: $0, messageService: messageService, contactService: contactService))
        }
    }

}
