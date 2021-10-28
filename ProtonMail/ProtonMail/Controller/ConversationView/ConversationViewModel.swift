import ProtonCore_UIFoundations
import CoreData

class ConversationViewModel {

    var headerSectionDataSource: [ConversationViewItemType] = []
    var messagesDataSource: [ConversationViewItemType] = [] {
        didSet { refreshView?() }
    }
    private(set) var isTrashedMessageHidden = false

    var refreshView: (() -> Void)?
    var dismissView: (() -> Void)?
    var dismissDeletedMessageActionSheet: ((String) -> Void)?

    var showNewMessageArrivedFloaty: ((String) -> Void)?

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
    let messageService: MessageDataService
    /// MessageID that want to expand at the begining
    let targetID: String?
    private let conversationMessagesProvider: ConversationMessagesProvider
    private let conversationUpdateProvider: ConversationUpdateProvider
    private let conversationService: ConversationProvider
    private let eventsService: EventsFetching
    private let contactService: ContactDataService
    private let coreDataService: CoreDataService
    private let sharedReplacingEmails: [Email]
    private(set) weak var tableView: UITableView?
    var selectedMoveToFolder: MenuLabel?
    var selectedLabelAsLabels: Set<LabelLocation> = Set()
    var openFromNotification = false
    var shouldIgnoreUpdateOnce = false
    weak var conversationViewController: ConversationViewController?

    /// Used to decide if there is any new messages coming
    private var recordNumOfMessages = 0
    private(set) var isExpandedAtLaunch = false

    /// Used to find out if there is any changes of the items of action types
    var actionTypeSnapshot: [MailboxViewModel.ActionTypes] = []

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
         user: UserManager,
         openFromNotification: Bool = false,
         coreDataService: CoreDataService,
         targetID: String? = nil) {
        self.labelId = labelId
        self.conversation = conversation
        self.messageService = user.messageService
        self.conversationService = user.conversationService
        self.contactService = user.contactService
        self.eventsService = user.eventsService
        self.coreDataService = coreDataService
        self.user = user
        self.conversationMessagesProvider = ConversationMessagesProvider(conversation: conversation)
        self.conversationUpdateProvider = ConversationUpdateProvider(conversationID: conversation.conversationID,
                                                                     coreDataService: coreDataService)
        self.openFromNotification = openFromNotification
        self.sharedReplacingEmails = contactService.allAccountEmails()
        self.targetID = targetID
        headerSectionDataSource = [.header(subject: conversation.subject)]

        recordNumOfMessages = conversation.numMessages.intValue
    }

    func fetchConversationDetails(completion: (() -> Void)?) {
        conversationService.fetchConversation(with: conversation.conversationID, includeBodyOf: nil) { _ in
            completion?()
        }
    }

    func message(by objectID: NSManagedObjectID) -> Message? {
        conversationMessagesProvider.message(by: objectID)
    }

    func observeConversationUpdate() {
        conversationUpdateProvider.observe { [weak self] in
            self?.refreshView?()
        }
    }

    func observeConversationMessages(tableView: UITableView) {
        self.tableView = tableView
        conversationMessagesProvider.observe { [weak self] update in
            self?.perform(update: update, on: tableView)
            self?.checkTrashedHintBanner()
        } storedMessages: { [weak self] messages in
            self?.checkTrashedHintBanner()
            var messageDataModels = messages.compactMap { self?.messageType(with: $0) }

            if messages.count == self?.conversation.numMessages.intValue {
                _ = self?.expandSpecificMessage(dataModels: &messageDataModels)
            }
            self?.messagesDataSource = messageDataModels
        }
    }

    func setCellIsExpandedAtLaunch() {
        self.isExpandedAtLaunch = true
    }

    func messageType(with message: Message) -> ConversationViewItemType {
        let viewModel = ConversationMessageViewModel(labelId: labelId,
                                                     message: message,
                                                     user: user,
                                                     replacingEmails: sharedReplacingEmails)
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

    /// Add trashed hint banner if the messages contain trashed message
    private func checkTrashedHintBanner() {
        let trashed = self.messagesDataSource
            .filter { $0.messageViewModel?.isTrashed ?? false }
        let hasTrashed = !trashed.isEmpty
        let isAllTrashed = trashed.count == self.messagesDataSource.count

        let row = IndexPath(row: 1, section: 0)
        let visible = self.tableView?.visibleCells.count ?? 0
        guard hasTrashed else {
            if let index = self.headerSectionDataSource.firstIndex(of: .trashedHint) {
                self.headerSectionDataSource.remove(at: index)
                if visible > 0 {
                    self.tableView?.deleteRows(at: [row], with: .automatic)
                }
            }
            return
        }
        if isAllTrashed {
            if let index = self.headerSectionDataSource.firstIndex(of: .trashedHint) {
                self.headerSectionDataSource.remove(at: index)
                if visible > 0 {
                    self.tableView?.deleteRows(at: [row], with: .automatic)
                }
            }
            if self.isTrashedMessageHidden {
                self.isTrashedMessageHidden = false
                let section = IndexSet(integer: 1)
                self.tableView?.reloadSections(section, with: .automatic)
            }
        } else if !self.headerSectionDataSource.contains(.trashedHint) {
            self.headerSectionDataSource.append(.trashedHint)
            if visible > 0 {
                self.tableView?.insertRows(at: [row], with: .automatic)
            }
        }
    }

    private func writeToTemporaryUrl(_ content: String, filename: String) throws -> URL {
        let tempFileUri = FileManager.default.temporaryDirectoryUrl
            .appendingPathComponent(filename, isDirectory: false).appendingPathExtension("txt")
        try? FileManager.default.removeItem(at: tempFileUri)
        try content.write(to: tempFileUri, atomically: true, encoding: .utf8)
        return tempFileUri
    }

    private func observeNewMessages() {
        if messagesDataSource.count > recordNumOfMessages && messagesDataSource.last?.message?.draft == false {
            showNewMessageArrivedFloaty?(messagesDataSource.newestMessage?.messageID ?? "")
        }
        recordNumOfMessages = messagesDataSource.count
    }

    private func updateDataSource(with messages: [Message]) {
        messagesDataSource = messages.map { newMessage -> ConversationViewItemType in
            if let viewModel = messagesDataSource.first(where: { $0.message?.messageID == newMessage.messageID }) {
                return viewModel
            }
            return messageType(with: newMessage)
        }
        if self.messagesDataSource.isEmpty {
            let context = self.coreDataService.operationContext
            context.perform { [weak self] in
                guard let self = self,
                      let object = try? context.existingObject(with: self.conversation.objectID) else {
                          self?.dismissView?()
                    return
                }
                context.delete(object)
                self.dismissView?()
            }
        }
    }

    private func perform(update: ConversationUpdateType, on tableView: UITableView) {
        switch update {
        case .willUpdate:
            tableView.beginUpdates()
        case let .didUpdate(messages):
            updateDataSource(with: messages)
            tableView.endUpdates()

            observeNewMessages()

            if !isExpandedAtLaunch && recordNumOfMessages == messagesDataSource.count && !shouldIgnoreUpdateOnce {
                if let path = self.expandSpecificMessage(dataModels: &self.messagesDataSource) {
                    tableView.reloadRows(at: [path], with: .automatic)
                    delay(1) { [weak tableView] in
                        tableView?.scrollToRow(at: path, at: .top, animated: true)
                    }
                    setCellIsExpandedAtLaunch()
                }
            }
            shouldIgnoreUpdateOnce = false

            refreshView?()
        case let .insert(row):
            tableView.insertRows(at: [.init(row: row, section: 1)], with: .automatic)
        case let .update(message, fromRow, toRow):
            let messageId = message.messageID
            guard let index = messagesDataSource.firstIndex(where: { $0.message?.messageID == messageId }),
                  let viewModel = messagesDataSource[index].messageViewModel else {
                return
            }
            viewModel.messageHasChanged(message: message)

            if fromRow != toRow {
                tableView.moveRow(at: .init(row: fromRow, section: 1), to: .init(row: toRow, section: 1))
            }

            if viewModel.state.isExpanded {
                viewModel.state.expandedViewModel?.message = message
            } else {
                let path = IndexPath(row: toRow, section: 1)
                guard tableView.cellForRow(at: path) != nil else { return }
                tableView.reloadRows(at: [path], with: .automatic)
            }
        case let .delete(row, messageID):
            tableView.deleteRows(at: [.init(row: row, section: 1)], with: .automatic)
            dismissDeletedMessageActionSheet?(messageID)
        case let .move(fromRow, toRow):
            guard fromRow != toRow else { return }
            tableView.moveRow(at: .init(row: fromRow, section: 1), to: .init(row: toRow, section: 1))
        }
    }
}

// MARK: - Actions
extension ConversationViewModel {

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

    func handleToolBarAction(_ action: MailboxViewModel.ActionTypes) {
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
                conversationService.markAsRead(
                    conversationIDs: [conversation.conversationID],
                    labelID: labelId
                ) { [weak self] result in
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
        case .markRead:
            conversationService.markAsRead(conversationIDs: [conversation.conversationID],
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
                let conversationIDsToApply = findConversationIDsToApplyLabels(conversations: conversations,
                                                                              labelID: label.location.labelID)
                conversationService.label(conversationIDs: conversationIDsToApply,
                                          as: label.location.labelID,
                                          completion: fetchEvents)
            } else {
                let conversationIDsToRemove = findConversationIDSToRemoveLables(conversations: conversations,
                                                                                labelID: label.location.labelID)
                conversationService.unlabel(conversationIDs: conversationIDsToRemove,
                                            as: label.location.labelID,
                                            completion: fetchEvents)
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

    private func findConversationIDsToApplyLabels(conversations: [Conversation], labelID: String) -> [String] {
        var conversationIDsToApplyLabel: [String] = []
        conversations.forEach { conversaion in
            if let context = conversaion.managedObjectContext {
                context.performAndWait {
                    let messages = Message.messagesForConversationID(conversaion.conversationID,
                                                                     inManagedObjectContext: context)
                    let needToUpdate = messages?
                        .allSatisfy({ $0.contains(label: labelID) }) == false
                    if needToUpdate {
                        conversationIDsToApplyLabel.append(conversaion.conversationID)
                    }
                }
            }
        }
        return conversationIDsToApplyLabel
    }

    private func findConversationIDSToRemoveLables(conversations: [Conversation], labelID: String) -> [String] {
        var conversationIDsToRemove: [String] = []
        conversations.forEach { conversaion in
            if let context = conversaion.managedObjectContext {
                context.performAndWait {
                    let messages = Message.messagesForConversationID(conversaion.conversationID,
                                                                     inManagedObjectContext: context)
                    let needToUpdate = messages?
                        .allSatisfy({ !$0.contains(label: labelID) }) == false
                    if needToUpdate {
                        conversationIDsToRemove.append(conversaion.conversationID)
                    }
                }
            }
        }
        return conversationIDsToRemove
    }

    private func expandSpecificMessage(dataModels: inout [ConversationViewItemType]) -> IndexPath? {
        var indexToOpen: Int?

        guard dataModels.count == recordNumOfMessages else {
            return nil
        }
        guard !dataModels
                .contains(where: { $0.messageViewModel?.state.isExpanded ?? false }) else { return nil }

        if let targetID = self.targetID,
           let index = dataModels.lastIndex(where: { $0.message?.messageID == targetID }) {
            if dataModels[index].messageViewModel?.isDraft ?? false {
                // The draft can't expand
                return nil
            }
            dataModels[index].messageViewModel?.toggleState()
            return IndexPath(row: index, section: 1)
        }

        // open the latest message if it contains all_sent label and is read.
        if let latestMessageIndex = dataModels.lastIndex(where: { $0.message?.draft == false }),
           let latestMessage = dataModels[safe: latestMessageIndex]?.message,
           latestMessage.contains(label: Message.HiddenLocation.sent.rawValue),
           latestMessage.unRead == false {
            dataModels[latestMessageIndex].messageViewModel?.toggleState()
            return IndexPath(row: latestMessageIndex, section: 1)
        }

        let isLatestMessageUnread = dataModels.isLatestMessageUnread(location: labelId)

        switch labelId {
        case Message.Location.allmail.rawValue, Message.Location.spam.rawValue:
            indexToOpen = getIndexOfMessageToExpandInSpamOrAllMail(dataModels: dataModels,
                                                                   isLatestMessageUnread: isLatestMessageUnread)
        case Message.Location.trash.rawValue:
            indexToOpen = getIndexOfMessageToExpandInTrashFolder(dataModels: dataModels,
                                                                 isLatestMessageUnread: isLatestMessageUnread)
        default:
            indexToOpen = getIndexOfMessageToExpand(dataModels: dataModels,
                                                    isLatestMessageUnread: isLatestMessageUnread)
        }

        if let index = indexToOpen {
            dataModels[index].messageViewModel?.toggleState()
            return IndexPath(row: index, section: 1)
        } else {
            return nil
        }
    }

    private func getIndexOfMessageToExpand(dataModels: [ConversationViewItemType],
                                           isLatestMessageUnread: Bool) -> Int? {
        if isLatestMessageUnread {
            // latest message of current location is unread, open the oldest of the unread messages
            // of the latest chunk of unread messages (excluding trash, draft).
            return getTheOldestIndexOfTheLatestChunckOfUnreadMessages(dataModels: dataModels,
                                                                      targetLabelID: labelId,
                                                                      shouldExcludeTrash: true)
        } else {
            // latest message of current location is read, open that message (excluding draft, trash)
            return getLatestMessageIndex(of: labelId, dataModels: dataModels)
        }
    }

    private func getIndexOfMessageToExpandInSpamOrAllMail(dataModels: [ConversationViewItemType],
                                                          isLatestMessageUnread: Bool) -> Int? {
        if isLatestMessageUnread {
            // latest message is unread, open the oldest of the unread messages
            // of the latest chunk of unread messages (excluding trash, draft).
            return getTheOldestIndexOfTheLatestChunckOfUnreadMessages(dataModels: dataModels,
                                                                      shouldExcludeTrash: true)
        } else {
            return getLatestMessageIndex(of: nil, dataModels: dataModels, excludeTrash: false)
        }
    }

    private func getIndexOfMessageToExpandInTrashFolder(dataModels: [ConversationViewItemType],
                                                        isLatestMessageUnread: Bool) -> Int? {
        if isLatestMessageUnread {
            // latest message of trashed is unread, open the oldest of the unread messages
            // of the latest chunk of unread messages (excluding draft).
            return getTheOldestIndexOfTheLatestChunckOfUnreadMessages(dataModels: dataModels)
        } else {
            // latest message of trashed is read, open that message
            return getLatestMessageIndex(of: labelId, dataModels: dataModels, excludeTrash: false)
        }
    }

    private func getLatestMessageIndex(of labelID: String?,
                                       dataModels: [ConversationViewItemType],
                                       excludeDraft: Bool = true,
                                       excludeTrash: Bool = true) -> Int? {
        let shouldCheckLabelId = labelID != nil
        if let latestMessageModelIndex = dataModels.lastIndex(where: {
            ($0.message?.contains(label: labelId) == true || !shouldCheckLabelId) &&
            ($0.message?.draft == false || !excludeDraft) &&
            ($0.message?.contains(label: Message.Location.trash.rawValue) == false || !excludeTrash)
        }) {
            return latestMessageModelIndex
        } else {
            return nil
        }
    }

    private func getTheOldestIndexOfTheLatestChunckOfUnreadMessages(dataModels: [ConversationViewItemType],
                                                                    targetLabelID: String? = nil,
                                                                    shouldExcludeTrash: Bool = false) -> Int? {
        // find the oldeset message of latest chunk of unread messages
        if let latestIndex = getLatestMessageIndex(of: targetLabelID,
                                                   dataModels: dataModels,
                                                   excludeTrash: shouldExcludeTrash) {
            var indexOfOldestUnreadMessage: Int?
            for index in (0...latestIndex).reversed() {
                if dataModels[index].message?.unRead != true || dataModels[index].message?.draft == true {
                    break
                }
                if shouldExcludeTrash && (dataModels[index].message?.contains(label: .trash) == true) {
                    break
                }
                if let labelToCheck = targetLabelID, dataModels[index].message?.contains(label: labelToCheck) == false {
                    break
                }
                indexOfOldestUnreadMessage = index
            }
            return indexOfOldestUnreadMessage
        }
        return nil
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

extension ConversationViewModel: ConversationViewTrashedHintDelegate {
    func clickTrashedMessageSettingButton() {
        self.isTrashedMessageHidden = !self.isTrashedMessageHidden

        var reloadRows: [IndexPath] = []
        self.messagesDataSource.enumerated().forEach { index, item in
            guard let viewModel = item.messageViewModel,
                  viewModel.isTrashed else { return }
            reloadRows.append(.init(row: index, section: 1))
        }
        reloadRows.append(.init(row: 1, section: 0))
        self.tableView?.reloadRows(at: reloadRows, with: .automatic)
    }
}
