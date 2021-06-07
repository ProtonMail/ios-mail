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
         contactService: ContactDataService) {
        self.conversation = conversation
        self.labelId = labelId
        self.user = user
        self.messageService = messageService
        self.conversationService = conversationService
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
            conversationService.deleteConversations(with: [conversation.conversationID], labelID: labelId) { _ in }
        case .readUnread:
            if conversation.isUnread(labelID: labelId) {
                conversationService.markAsRead(conversationIDs: [conversation.conversationID]) { _ in }
            } else {
                conversationService.markAsUnread(conversationIDs: [conversation.conversationID],
                                                 labelID: labelId) { _ in }
            }
        case .trash:
            conversationService.move(conversationIDs: [conversation.conversationID],
                                     from: labelId,
                                     to: Message.Location.trash.rawValue) { _ in }
        default:
            return
        }
    }

    func handleActionSheetAction(_ action: MessageViewActionSheetAction,
                                 completion: @escaping () -> Void) {
        switch action {
        case .markUnread:
            conversationService.markAsUnread(conversationIDs: [conversation.conversationID], labelID: labelId) { _ in }
        case .trash:
            conversationService.move(conversationIDs: [conversation.conversationID],
                                     from: labelId,
                                     to: Message.Location.trash.rawValue) { _ in }
        case .archive:
            conversationService.move(conversationIDs: [conversation.conversationID],
                                     from: labelId,
                                     to: Message.Location.archive.rawValue) { _ in }
        case .spam:
            conversationService.move(conversationIDs: [conversation.conversationID],
                                     from: labelId,
                                     to: Message.Location.spam.rawValue) { _ in }
        case .delete:
            conversationService.deleteConversations(with: [conversation.conversationID], labelID: labelId) { _ in }
        case .reportPhishing:
            guard let newestMessage = dataSource.newestMessage else {
                return
            }
            BugDataService(api: self.user.apiService).reportPhishing(messageID: newestMessage.messageID,
                                                                     messageBody: newestMessage.body) { _ in
                self.conversationService.move(conversationIDs: [self.conversation.conversationID],
                                              from: self.labelId,
                                              to: Message.Location.spam.rawValue) { _ in }
                                                                        completion()
            }
            return
        case .inbox, .spamMoveToInbox:
            conversationService.move(conversationIDs: [conversation.conversationID],
                                     from: labelId,
                                     to: Message.Location.spam.rawValue) { _ in }
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
        for (label, status) in currentOptionsStatus {
            guard status != .dash else { continue } // Ignore the option in dash
            if selectedLabelAsLabels
                .contains(where: { $0.labelID == label.location.labelID }) {
                // Add to message which does not have this label
                if !conversation.getLabels().contains(label.location.labelID) {
                    conversationService.label(conversationIDs: conversations.map(\.conversationID),
                                              as: label.location.labelID) { _ in }
                }
            } else {
                if conversation.getLabels().contains(label.location.labelID) {
                    conversationService.unlabel(conversationIDs: conversations.map(\.conversationID),
                                                as: label.location.labelID) { _ in }
                }
            }
        }

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            if let fLabel = conversation.firstValidFolder() {
                conversationService.move(conversationIDs: conversations.map(\.conversationID),
                                         from: fLabel,
                                         to: Message.Location.archive.rawValue) { _ in }
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
                                 to: destination.location.labelID) { _ in }
    }
}

// MARK: - Newest Message Headers & HTML
extension ConversationViewModel {
    func getMessageHeaderUrl() -> URL? {
        guard let message = dataSource.newestMessage else {
            return nil
        }
        let time = dateFormatter.string(from: message.time ?? Date())
        let title = message.title.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let filename = "headers-" + time + "-" + title.joined(separator: "-")
        guard let header = message.header else {
            assert(false, "No header in message")
            return nil
        }
        return try? self.writeToTemporaryUrl(header, filename: filename)
    }

    func getMessageBodyUrl() -> URL? {
        guard let message = dataSource.newestMessage else {
            return nil
        }
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
}
