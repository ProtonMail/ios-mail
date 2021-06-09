import ProtonCore_UIFoundations

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

    let conversation: Conversation
    let labelId: String
    let user: UserManager
    private let conversationMessagesProvider: ConversationMessagesProvider
    private let messageService: MessageDataService
    private let conversationService: ConversationProvider
    private let eventsService: EventsFetching
    private let contactService: ContactDataService
    var selectedMoveToFolder: MenuLabel?
    var selectedLabelAsLabels: Set<LabelLocation> = Set()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    private var header: ConversationViewItemType {
        .header(subject: conversation.subject)
    }

    init(conversation: Conversation,
         labelId: String,
         user: UserManager,
         messageService: MessageDataService,
         conversationService: ConversationProvider,
         eventsService: EventsFetching,
         contactService: ContactDataService) {
        self.conversation = conversation
        self.labelId = labelId
        self.user = user
        self.messageService = messageService
        self.conversationService = conversationService
        self.eventsService = eventsService
        self.contactService = contactService
        self.conversationMessagesProvider = ConversationMessagesProvider(conversation: conversation)
        observeConversationMessages()
    }

    func fetchConversationDetails() {
        conversationService.fetchConversation(with: conversation.conversationID, includeBodyOf: nil) { _ in }
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

    func starTapped(completion: @escaping (Result<Bool, Error>) -> Void) {
        if conversation.starred {
            conversationService.unlabel(conversationIDs: [conversation.conversationID],
                                        as: Message.Location.starred.rawValue) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    completion(.success(false))
                    self.eventsService.fetchEvents(labelID: self.labelId)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            conversationService.label(conversationIDs: [conversation.conversationID],
                                      as: Message.Location.starred.rawValue) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    completion(.success(true))
                    self.eventsService.fetchEvents(labelID: self.labelId)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    func getActionTypes() -> [MailboxViewModel.ActionTypes] {
        var actions: [MailboxViewModel.ActionTypes] = []
        if let newestMessage = dataSource.newestMessage {
            let isHavingMoreThanOneContact = (newestMessage.toList.toContacts() +
                                                newestMessage.ccList.toContacts()).count > 1
            actions.append(isHavingMoreThanOneContact ? .replyAll : .reply)
        }
        actions.append(.readUnread)
        let deleteLocation = [
            Message.Location.draft.rawValue,
            Message.Location.spam.rawValue,
            Message.Location.trash.rawValue
        ]
        actions.append(deleteLocation.contains(labelId) ? .delete : .trash)
        actions.append(.more)
        return actions
    }

    func handleActionBarAction(_ action: MailboxViewModel.ActionTypes) {
        switch action {
        case .delete:
            conversationService.deleteConversations(with: [conversation.conversationID],
                                                    labelID: labelId) { [weak self] result in
                guard let self = self else { return }
                if (try? result.get()) != nil {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
        case .readUnread:
            if conversation.isUnread(labelID: labelId) {
                conversationService.markAsRead(conversationIDs: [conversation.conversationID]) { [weak self] result in
                    guard let self = self else { return }
                    if (try? result.get()) != nil {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            } else {
                conversationService.markAsUnread(conversationIDs: [conversation.conversationID],
                                                 labelID: labelId) { [weak self] result in
                    guard let self = self else { return }
                    if (try? result.get()) != nil {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            }
        case .trash:
            conversationService.move(conversationIDs: [conversation.conversationID],
                                     from: labelId,
                                     to: Message.Location.trash.rawValue) { [weak self] result in
                guard let self = self else { return }
                if (try? result.get()) != nil {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
        default:
            return
        }
    }

    func handleActionSheetAction(_ action: MessageViewActionSheetAction, completion: @escaping () -> Void) {
        let fetchEvents = { [weak self] (result: Result<Void, Error>) in
            guard let self = self else { return }
            if (try? result.get()) != nil { self.eventsService.fetchEvents(labelID: self.labelId) }
        }
        let moveAction = { (destination: Message.Location) in
            self.conversationService.move(conversationIDs: [self.conversation.conversationID],
                                          from: self.labelId,
                                          to: destination.rawValue,
                                          completion: fetchEvents)
        }
        switch action {
        case .markUnread:
            conversationService.markAsUnread(conversationIDs: [conversation.conversationID],
                                             labelID: labelId,
                                             completion: fetchEvents)
        case .trash:
            moveAction(Message.Location.trash)
        case .archive:
            moveAction(Message.Location.archive)
        case .spam:
            moveAction(Message.Location.spam)
        case .delete:
            conversationService.deleteConversations(with: [conversation.conversationID],
                                                    labelID: labelId,
                                                    completion: fetchEvents)
        case .inbox, .spamMoveToInbox:
            moveAction(Message.Location.inbox)
        default:
            break
        }
        completion()
    }
}

// MARK: - Label As Action Sheet Implementation
extension ConversationViewModel: LabelAsActionSheetProtocol {
    func handleLabelAsAction(messages: [Message],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) {
        fatalError("Not implemented")
    }

    func handleLabelAsAction(conversations: [Conversation],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) {
        let fetchEvents = { [weak self] (result: Result<Void, Error>) in
            guard let self = self else { return }
            if (try? result.get()) != nil {
                self.eventsService.fetchEvents(labelID: self.labelId)
            }
        }
        for (label, status) in currentOptionsStatus {
            guard status != .dash else { continue } // Ignore the option in dash
            if selectedLabelAsLabels
                .contains(where: { $0.labelID == label.location.labelID }) {
                // Add to message which does not have this label
                if !conversation.getLabels().contains(label.location.labelID) {
                    conversationService.label(conversationIDs: conversations.map(\.conversationID),
                                              as: label.location.labelID,
                                              completion: fetchEvents)
                }
            } else {
                if conversation.getLabels().contains(label.location.labelID) {
                    conversationService.unlabel(conversationIDs: conversations.map(\.conversationID),
                                                as: label.location.labelID,
                                                completion: fetchEvents)
                }
            }
        }

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            if let fLabel = conversation.firstValidFolder() {
                conversationService.move(conversationIDs: conversations.map(\.conversationID),
                                         from: fLabel,
                                         to: Message.Location.archive.rawValue,
                                         completion: fetchEvents)
            }
        }
    }
}

// MARK: - Move TO Action Sheet Implementation
extension ConversationViewModel: MoveToActionSheetProtocol {
    func handleMoveToAction(messages: [Message]) {
        fatalError("Not implemented")
    }

    func handleMoveToAction(conversations: [Conversation]) {
        guard let destination = selectedMoveToFolder else { return }
        conversationService.move(conversationIDs: conversations.map(\.conversationID),
                                 from: "",
                                 to: destination.location.labelID) { [weak self] result in
            guard let self = self else { return }
            if (try? result.get()) != nil {
                self.eventsService.fetchEvents(labelID: self.labelId)
            }
        }
    }
}
