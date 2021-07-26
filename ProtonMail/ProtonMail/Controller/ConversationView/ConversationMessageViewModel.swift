class ConversationMessageViewModel {

    var isDraft: Bool {
        let labelIds = message.labels
            .compactMap { $0 as? Label }
            .map(\.labelID)
        let isDraft: Bool
        if labelIds.contains(Message.Location.draft.rawValue)
            || labelIds.contains(Message.HiddenLocation.draft.rawValue) {
            isDraft = true
        } else {
            isDraft = false
        }
        guard isDraft else { return false }
        return true
    }

    var isTrashed: Bool {
        return message.labels
            .compactMap { $0 as? Label }
            .map(\.labelID)
            .contains(Message.Location.trash.rawValue)
    }

    private(set) var message: Message {
        didSet {
            state.collapsedViewModel?.messageHasChanged(message: message)
            state.expandedViewModel?.messageHasChanged(message: message)
        }
    }

    private var weekStart: WeekStart {
        user.userinfo.weekStartValue
    }

    private(set) var state: ConversationMessageState
    private let labelId: String
    private let user: UserManager
    private let messageContentViewModelFactory = SingleMessageContentViewModelFactory()

    init(labelId: String, message: Message, user: UserManager) {
        self.labelId = labelId
        self.message = message
        self.user = user
        let collapsedViewModel = ConversationCollapsedMessageViewModel(
            message: message,
            contactService: user.contactService,
            weekStart: user.userinfo.weekStartValue
        )
        self.state = .collapsed(viewModel: collapsedViewModel)
    }

    func messageHasChanged(message: Message) {
        self.message = message
    }

    func toggleState() {
        state = state.isExpanded ?
            .collapsed(viewModel: .init(message: message, contactService: user.contactService, weekStart: weekStart)) :
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
