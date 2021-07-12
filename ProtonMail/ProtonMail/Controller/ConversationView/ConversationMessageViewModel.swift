class ConversationMessageViewModel {

    private(set) var message: Message {
        didSet {
            state.collapsedViewModel?.messageHasChanged(message: message)
            state.expandedViewModel?.messageHasChanged(message: message)
        }
    }

    private(set) var state: ConversationMessageState
    private let labelId: String
    private let user: UserManager
    private let messageContentViewModelFactory = SingleMessageContentViewModelFactory()

    var isDraft: Bool {
        let isDraft = message.labels
            .compactMap { $0 as? Label }
            .map(\.labelID)
            .contains(Message.Location.draft.rawValue)
        guard isDraft else { return false }
        return true
    }

    var isTrashed: Bool {
        return message.labels
            .compactMap { $0 as? Label }
            .map(\.labelID)
            .contains(Message.Location.trash.rawValue)
    }

    init(labelId: String, message: Message, user: UserManager) {
        self.labelId = labelId
        self.message = message
        self.user = user
        self.state = .collapsed(viewModel: .init(message: message, contactService: user.contactService))
    }

    func messageHasChanged(message: Message) {
        self.message = message
    }

    func toggleState() {
        state = state.isExpanded ?
            .collapsed(viewModel: .init(message: message, contactService: user.contactService)) :
            .expanded(viewModel: .init(message: message, messageContent: singleMessageContentViewModel(for: message)))
    }

    private func singleMessageContentViewModel(for message: Message) -> SingleMessageContentViewModel {
        let context = SingleMessageContentViewContext(
            labelId: labelId,
            message: message,
            viewMode: .conversation
        )
        return messageContentViewModelFactory.createViewModel(context: context, user: user)
    }

}

extension ConversationMessageState {

    var isExpanded: Bool {
        guard case .expanded = self else { return false }
        return true
    }

}
