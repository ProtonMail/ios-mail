import ProtonCore_UIFoundations

class ConversationViewModel {

    var headerSectionDataSource: [ConversationViewItemType] = []

    var messagesDataSource: [ConversationViewItemType] = [] {
        didSet { refreshView?() }
    }

    var refreshView: (() -> Void)?

    var messagesTitle: String {
        .localizedStringWithFormat(LocalString._general_message, messagesDataSource.count)
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
    let messageService: MessageDataService
    private let conversationMessagesProvider: ConversationMessagesProvider
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

    init(labelId: String,
         conversation: Conversation,
         user: UserManager) {
        self.labelId = labelId
        self.conversation = conversation
        self.messageService = user.messageService
        self.conversationService = user.conversationService
        self.contactService = user.contactService
        self.eventsService = user.eventsService
        self.user = user
        self.conversationMessagesProvider = ConversationMessagesProvider(conversation: conversation)
        headerSectionDataSource = [.header(subject: conversation.subject)]
    }

    func fetchConversationDetails() {
        conversationService.fetchConversation(with: conversation.conversationID, includeBodyOf: nil) { _ in }
    }

    func observeConversationMessages(tableView: UITableView) {
        conversationMessagesProvider.observe { [weak self] update in
            self?.perform(update: update, on: tableView)
        } storedMessages: { [weak self] messages in
            self?.messagesDataSource = messages.compactMap { self?.messageType(with: $0) }
        }
    }

    func messageType(with message: Message) -> ConversationViewItemType {
        let viewModel = ConversationMessageViewModel(labelId: labelId, message: message, user: user)
        return .message(viewModel: viewModel)
    }

    func getMessageHeaderUrl(message: Message) -> URL? {
        let time = dateFormatter.string(from: message.time ?? Date())
        let title = message.title.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let filename = "headers-" + time + "-" + title.joined(separator: "-")
        guard let header = message.header else {
            assert(false, "No header in message")
            return nil
        }
        return try? self.writeToTemporaryUrl(header, filename: filename)
    }

    func getMessageBodyUrl(message: Message) -> URL? {
        let time = dateFormatter.string(from: message.time ?? Date())
        let title = message.title.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let filename = "body-" + time + "-" + title.joined(separator: "-")
        guard let body = try? messageService.decryptBodyIfNeeded(message: message) else {
            return nil
        }
        return try? self.writeToTemporaryUrl(body, filename: filename)
    }

    private func writeToTemporaryUrl(_ content: String, filename: String) throws -> URL {
        let tempFileUri = FileManager.default.temporaryDirectoryUrl
            .appendingPathComponent(filename, isDirectory: false).appendingPathExtension("txt")
        try? FileManager.default.removeItem(at: tempFileUri)
        try content.write(to: tempFileUri, atomically: true, encoding: .utf8)
        return tempFileUri
    }

    private func perform(update: ConversationUpdateType, on tableView: UITableView) {
        switch update {
        case .willUpdate:
            tableView.beginUpdates()
        case .didUpdate:
            tableView.endUpdates()
        case let .insert(message, row):
            insert(message, row, tableView)
        case let .update(message, row):
            if let viewModel = messagesDataSource[safe: row]?.messageViewModel {
                viewModel.messageHasChanged(message: message)
            }
        case let .delete(message):
            if let index = messagesDataSource.firstIndex(where: { $0.message?.messageID == message.messageID }) {
                messagesDataSource.remove(at: index)
                tableView.deleteRows(at: [.init(row: index, section: 1)], with: .automatic)
            }
        case let .move(fromRow, toRow):
            if let item = messagesDataSource[safe: fromRow] {
                messagesDataSource.remove(at: fromRow)
                messagesDataSource.insert(item, at: toRow)
                tableView.moveRow(at: .init(row: fromRow, section: 1), to: .init(row: toRow, section: 1))
            }
        }
    }

    private func insert(_ message: Message, _ row: Int, _ tableView: UITableView) {
        if row > messagesDataSource.endIndex {
            (messagesDataSource.endIndex...(messagesDataSource.endIndex + (row - messagesDataSource.endIndex)))
                .forEach { messagesDataSource.insert(.empty, at: $0) }
        }

        if let currentElement = messagesDataSource[safe: row], currentElement.isEmpty {
            messagesDataSource.remove(at: row)
        } else if let toRemove = messagesDataSource.indexAfterIndex(row, where: { $0.isEmpty }) {
            messagesDataSource.remove(at: toRemove)
        }

        messagesDataSource.insert(messageType(with: message), at: row)
        tableView.insertRows(at: [.init(row: row, section: 1)], with: .automatic)
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
        if let newestMessage = messagesDataSource.newestMessage {
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
        guard let message = messages.first else { return }
        for (label, status) in currentOptionsStatus {
            guard status != .dash else { continue } // Ignore the option in dash
            if selectedLabelAsLabels
                .contains(where: { $0.labelID == label.location.labelID }) {
                // Add to message which does not have this label
                if !message.contains(label: label.location.labelID) {
                    messageService.label(messages: messages,
                                         label: label.location.labelID,
                                         apply: true)
                }
            } else {
                if message.contains(label: label.location.labelID) {
                    messageService.label(messages: messages,
                                         label: label.location.labelID,
                                         apply: false)
                }
            }
        }

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            if let fLabel = message.firstValidFolder() {
                messageService.move(messages: messages,
                                    from: [fLabel],
                                    to: Message.Location.archive.rawValue)
            }
        }
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
        guard let destination = selectedMoveToFolder else { return }
        user.messageService.move(messages: messages, to: destination.location.labelID)
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
