class ConversationMessageViewModel {
    typealias Dependencies = SingleMessageContentViewModelFactory.Dependencies
    & HasInternetConnectionStatusProviderProtocol
    & HasMailboxMessageCellHelper

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
        dependencies.user.userInfo.weekStartValue
    }

    private(set) var state: ConversationMessageState
    private let labelId: LabelID
    private let messageContentViewModelFactory: SingleMessageContentViewModelFactory
    private let replacingEmailsMap: [String: EmailEntity]
    private let contactGroups: [ContactGroupVO]
    private let dependencies: Dependencies
    let highlightedKeywords: [String]
    private let goToDraft: (MessageID, Date?) -> Void

    init(labelId: LabelID,
         message: MessageEntity,
         replacingEmailsMap: [String: EmailEntity],
         contactGroups: [ContactGroupVO],
         dependencies: Dependencies,
         highlightedKeywords: [String],
         goToDraft: @escaping (MessageID, Date?) -> Void
    ) {
        self.labelId = labelId
        self.message = message
        self.replacingEmailsMap = replacingEmailsMap
        self.contactGroups = contactGroups
        self.dependencies = dependencies
        self.goToDraft = goToDraft
        self.highlightedKeywords = highlightedKeywords
        messageContentViewModelFactory = SingleMessageContentViewModelFactory(dependencies: dependencies)
        let collapsedViewModel = ConversationCollapsedMessageViewModel(
            message: message,
            weekStart: dependencies.user.userInfo.weekStartValue,
            replacingEmailsMap: replacingEmailsMap,
            contactGroups: contactGroups,
            mailboxMessageCellHelper: dependencies.mailboxMessageCellHelper
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
                replacingEmailsMap: replacingEmailsMap,
                contactGroups: contactGroups,
                mailboxMessageCellHelper: dependencies.mailboxMessageCellHelper
            )) :
            .expanded(viewModel: .init(
                message: message,
                messageContent: singleMessageContentViewModel(for: message)
            ))
    }

    private func singleMessageContentViewModel(
        for message: MessageEntity
    ) -> SingleMessageContentViewModel {
        let context = SingleMessageContentViewContext(
            labelId: labelId,
            message: message,
            viewMode: .conversation
        )
        return messageContentViewModelFactory.createViewModel(
            context: context,
            highlightedKeywords: highlightedKeywords,
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
