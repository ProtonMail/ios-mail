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
        user.userInfo.weekStartValue
    }

    private(set) var state: ConversationMessageState
    private let labelId: LabelID
    private let user: UserManager
    private let messageContentViewModelFactory = SingleMessageContentViewModelFactory()
    private let replacingEmails: [Email]
    private let contactGroups: [ContactGroupVO]
    private let isDarkModeEnableClosure: () -> Bool
    private let internetStatusProvider: InternetConnectionStatusProvider
    private let goToDraft: (MessageID) -> Void

    init(labelId: LabelID,
         message: MessageEntity,
         user: UserManager,
         replacingEmails: [Email],
         contactGroups: [ContactGroupVO],
         internetStatusProvider: InternetConnectionStatusProvider,
         isDarkModeEnableClosure: @escaping () -> Bool,
         goToDraft: @escaping (MessageID) -> Void
    ) {
        self.labelId = labelId
        self.message = message
        self.user = user
        self.replacingEmails = replacingEmails
        self.contactGroups = contactGroups
        self.isDarkModeEnableClosure = isDarkModeEnableClosure
        self.internetStatusProvider = internetStatusProvider
        self.goToDraft = goToDraft
        let collapsedViewModel = ConversationCollapsedMessageViewModel(
            message: message,
            weekStart: user.userInfo.weekStartValue,
            replacingEmails: replacingEmails,
            contactGroups: contactGroups
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
            .collapsed(viewModel: .init(
                message: message,
                weekStart: weekStart,
                replacingEmails: replacingEmails,
                contactGroups: contactGroups
            )) :
            .expanded(viewModel: .init(
                message: message,
                messageContent: singleMessageContentViewModel(for: message)
            ))
    }

    private func singleMessageContentViewModel(for message: MessageEntity) -> SingleMessageContentViewModel {
        let context = SingleMessageContentViewContext(
            labelId: labelId,
            message: message,
            viewMode: .conversation
        )
        return messageContentViewModelFactory.createViewModel(
            context: context,
            user: user,
            internetStatusProvider: internetStatusProvider,
            systemUpTime: userCachedStatus,
            isDarkModeEnableClosure: isDarkModeEnableClosure,
            goToDraft: goToDraft
        )
    }

}

extension ConversationMessageState {

    var isExpanded: Bool {
        guard case .expanded = self else { return false }
        return true
    }

}
