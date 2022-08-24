class ConversationMessageViewModel {

    var isDraft: Bool {
        message.isDraft
    }

    var isTrashed: Bool {
        message.isTrash
    }

    var isSpam: Bool {
        message.contains(location: .spam)
    }

    private(set) var message: MessageEntity {
        didSet {
            state.collapsedViewModel?.messageHasChanged(message: message)
            state.expandedViewModel?.messageHasChanged(message: message)
        }
    }

    private var weekStart: WeekStart {
        user.userinfo.weekStartValue
    }

    private(set) var state: ConversationMessageState
    private let labelId: LabelID
    private let user: UserManager
    private let messageContentViewModelFactory = SingleMessageContentViewModelFactory()
    private let replacingEmails: [Email]
    private let isDarkModeEnableClosure: () -> Bool
    private let internetStatusProvider: InternetConnectionStatusProvider

    init(labelId: LabelID,
         message: MessageEntity,
         user: UserManager,
         replacingEmails: [Email],
         internetStatusProvider: InternetConnectionStatusProvider,
         isDarkModeEnableClosure: @escaping () -> Bool
    ) {
        self.labelId = labelId
        self.message = message
        self.user = user
        self.replacingEmails = replacingEmails
        self.isDarkModeEnableClosure = isDarkModeEnableClosure
        self.internetStatusProvider = internetStatusProvider
        let collapsedViewModel = ConversationCollapsedMessageViewModel(
            message: message,
            weekStart: user.userinfo.weekStartValue,
            replacingEmails: replacingEmails
        )
        self.state = .collapsed(viewModel: collapsedViewModel)
    }

    func messageHasChanged(message: MessageEntity) {
        guard self.message != message else {
            return
        }
        self.message = message
    }

    func toggleState() {
        state = state.isExpanded ?
            .collapsed(viewModel: .init(message: message, weekStart: weekStart, replacingEmails: replacingEmails)) :
            .expanded(viewModel: .init(message: message, messageContent: singleMessageContentViewModel(for: message)))
    }

    private func singleMessageContentViewModel(for message: MessageEntity) -> SingleMessageContentViewModel {
        let context = SingleMessageContentViewContext(
            labelId: labelId,
            message: message,
            viewMode: .conversation
        )
        return messageContentViewModelFactory.createViewModel(context: context,
                                                              user: user,
                                                              internetStatusProvider: internetStatusProvider,
                                                              isDarkModeEnableClosure: isDarkModeEnableClosure)
    }

}

extension ConversationMessageState {

    var isExpanded: Bool {
        guard case .expanded = self else { return false }
        return true
    }

}
