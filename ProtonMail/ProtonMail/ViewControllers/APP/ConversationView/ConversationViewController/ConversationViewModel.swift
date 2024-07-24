import CoreData
import ProtonCoreUIFoundations
import ProtonCoreDataModel
import ProtonMailAnalytics
import UIKit

enum MessageDisplayRule {
    case showNonTrashedOnly
    case showTrashedOnly
    case showAll
}

// swiftlint:disable type_body_length
class ConversationViewModel {
    typealias Dependencies = ConversationMessageViewModel.Dependencies
    & HasFetchSenderImage
    & HasFetchMessageDetailUseCase
    & HasNextMessageAfterMoveStatusProvider
    & HasNotificationCenter
    & HasUserDefaults
    & HasUserIntroductionProgressProvider
    & HasQueueManager

    var headerSectionDataSource: [ConversationViewItemType] = []
    var messagesDataSource: [ConversationViewItemType] = [] {
        didSet {
            guard messagesDataSource != oldValue else {
                return
            }
            refreshView?()
        }
    }
    private(set) var displayRule = MessageDisplayRule.showNonTrashedOnly
    var refreshView: (() -> Void)?
    var dismissView: (() -> Void)?
    var reloadRows: (([IndexPath]) -> Void)?
    var leaveFocusedMode: (() -> Void)?
    var dismissDeletedMessageActionSheet: ((MessageID) -> Void)?
    var viewModeIsChanged: ((ViewMode) -> Void)?
    var conversationIsReadyToBeDisplayed: (() -> Void)?

    var showNewMessageArrivedFloaty: ((MessageID) -> Void)?

    var reloadTableView: (() -> Void)?
    private(set) var isShowingSkeletonView = true

    var messagesTitle: String {
        .localizedStringWithFormat(LocalString._general_message, conversation.messageCount)
    }

    var simpleNavigationViewType: NavigationViewType {
        .simple(numberOfMessages: messagesTitle.apply(style: FontManager.body3RegularWeak))
    }

    var detailedNavigationViewType: NavigationViewType {
        let subjectStyle = FontManager.DefaultSmallStrong.lineBreakMode(.byTruncatingTail)
        let subject = conversation.subject.keywordHighlighting.asAttributedString(keywords: highlightedKeywords)
        subject.addAttributes(
            subjectStyle,
            range: NSRange(location: 0, length: (conversation.subject as NSString).length)
        )

        return .detailed(
            subject: subject,
            numberOfMessages: messagesTitle.apply(style: FontManager.OverlineRegularTextWeak)
        )
    }

    var shouldMoveToNextMessageAfterMove: Bool {
        dependencies.nextMessageAfterMoveStatusProvider.shouldMoveToNextMessageAfterMove
    }

    private(set) var conversation: ConversationEntity
    let labelId: LabelID
    let user: UserManager
    let messageService: MessageDataService
    /// MessageID that want to expand at the beginning
    var targetID: MessageID?
    /// The messageID of a draft that should be opened at the beginning
    var draftID: MessageID?
    private let conversationMessagesProvider: ConversationMessagesProvider
    private let conversationUpdateProvider: ConversationUpdateProvider
    private let conversationService: ConversationProvider
    private let eventsService: EventsFetching
    private let contactService: ContactDataService
    private let sharedReplacingEmailsMap: [String: EmailEntity]
    private let sharedContactGroups: [ContactGroupVO]
    let coordinator: ConversationCoordinatorProtocol
    private(set) weak var tableView: UITableView?
    var selectedLabelAsLabels: Set<LabelLocation> = Set()
    var isTrashFolder: Bool { self.labelId == LabelLocation.trash.labelID }
    weak var conversationViewController: ConversationViewController?
    private(set) var tableViewIsUpdating = false

    /// Used to decide if there is any new messages coming
    private var recordNumOfMessages = 0

    /// Focused mode means that the messages above the first expanded one are hidden from view.
    private(set) var focusedMode = true {
        didSet {
            if oldValue && !focusedMode {
                leaveFocusedMode?()
            }
        }
    }

    var firstExpandedMessageIndex: Int? {
        messagesDataSource.firstIndex(where: { $0.messageViewModel?.state.isExpanded ?? false })
    }

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    var areAllMessagesInThreadInTheTrash: Bool {
        guard !messagesDataSource.isEmpty else { return false }
        return messagesDataSource
            .compactMap(\.messageViewModel)
            .allSatisfy(\.isTrashed)
    }

    var areAllMessagesInThreadInSpam: Bool {
        guard !messagesDataSource.isEmpty else { return false }
        return messagesDataSource
            .compactMap(\.messageViewModel)
            .allSatisfy(\.isSpam)
    }

    var areAllMessagesInThreadInTheArchive: Bool {
        guard !messagesDataSource.isEmpty else { return false }
        return messagesDataSource
            .compactMap(\.messageViewModel)
            .allSatisfy { $0.message.contains(location: .archive) }
    }

    var isInitialDataFetchCalled = false
    private let conversationStateProvider: ConversationStateProviderProtocol
    /// This is used to restore the message status when the view mode is changed.
    var messageIDsOfMarkedAsRead: [MessageID] = []
    private let goToDraft: (MessageID, Date?) -> Void

    // Fetched by each cell in the view, use lazy to avoid fetching too much times
    lazy private(set) var customFolders: [LabelEntity] = {
        labelProvider.getCustomFolders()
    }()
    let labelProvider: LabelProviderProtocol
    private let toolbarActionProvider: ToolbarActionProvider
    private let saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase
    let highlightedKeywords: [String]
    private let dependencies: Dependencies
    private var isApplicationActive: (() -> Bool)?
    private var reloadWhenAppIsActive: (() -> Void)?
    private var blockMarkReadIfNeeded = false
    private(set) var messagesAreLoaded = false

    init(labelId: LabelID,
         conversation: ConversationEntity,
         coordinator: ConversationCoordinatorProtocol,
         conversationStateProvider: ConversationStateProviderProtocol,
         labelProvider: LabelProviderProtocol,
         targetID: MessageID?,
         toolbarActionProvider: ToolbarActionProvider,
         saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase,
         highlightedKeywords: [String],
         goToDraft: @escaping (MessageID, Date?) -> Void,
         dependencies: Dependencies) {
        self.labelId = labelId
        self.conversation = conversation
        user = dependencies.user
        self.messageService = user.messageService
        self.conversationService = user.conversationService
        self.contactService = user.contactService
        self.eventsService = user.eventsService
        let contextProvider = dependencies.contextProvider
        self.highlightedKeywords = highlightedKeywords
        self.conversationMessagesProvider = ConversationMessagesProvider(conversation: conversation,
                                                                         contextProvider: contextProvider)
        self.conversationUpdateProvider = ConversationUpdateProvider(conversationID: conversation.conversationID,
                                                                     contextProvider: contextProvider)
        self.sharedReplacingEmailsMap = contactService.allAccountEmails()
            .reduce(into: [:]) { partialResult, email in
                partialResult[email.email] = email
            }
        self.sharedContactGroups = user.contactGroupService.getAllContactGroupVOs()
        self.targetID = targetID
        self.conversationStateProvider = conversationStateProvider
        self.goToDraft = goToDraft
        self.labelProvider = labelProvider
        self.dependencies = dependencies
        headerSectionDataSource = []

        recordNumOfMessages = conversation.messageCount
        self.toolbarActionProvider = toolbarActionProvider
        self.saveToolbarActionUseCase = saveToolbarActionUseCase
        self.coordinator = coordinator
        self.displayRule = self.isTrashFolder ? .showTrashedOnly : .showNonTrashedOnly
        self.conversationStateProvider.add(delegate: self)
    }

    func scrollViewDidScroll() {
        focusedMode = false
    }

    func fetchConversationDetails(completion: (() -> Void)?) {
        guard dependencies.internetConnectionStatusProvider.status.isConnected else {
            completion?()
            return
        }
        conversationService.fetchConversation(
            with: conversation.conversationID,
            includeBodyOf: nil,
            callOrigin: "ConversationViewModel"
        ) { [weak self] _ in
            if let self {
                let ids = self.messagesDataSource
                    .filter { source in
                        guard let id = source.message?.messageID else { return false }
                        return self.messageIDsOfMarkedAsRead.contains(id)
                    }
                    .compactMap{ $0.message?.objectID.rawValue }
                self.messageService.markLocally(messageObjectIDs: ids, labelID: self.labelId, unRead: false)
            }

            if let completion = completion {
                DispatchQueue.main.async(execute: completion)
            }
        }
    }

    func message(by objectID: NSManagedObjectID) -> MessageEntity? {
        if let msg = conversationMessagesProvider.message(by: objectID) {
            return MessageEntity(msg)
        }
        return nil
    }

    func observeConversationUpdate() {
        conversationUpdateProvider.observe { [weak self] conversationEntity in
            if let entity = conversationEntity {
                self?.conversation = entity
            }
            self?.refreshView?()
        }
    }

    func observeConversationMessages(tableView: UITableView) {
        self.tableView = tableView
        if conversationMessagesProvider.hasStartedObservingConversation {
            conversationMessagesProvider.listenToCoreDataUpdates()
            return
        }

        conversationMessagesProvider.observe { [weak self] update in
            if case .willUpdate = update {
                self?.isShowingSkeletonView = false
                self?.reloadTableView?()
            }
            self?.perform(update: update, on: tableView)
            if case .didUpdate = update {
                self?.checkTrashedHintBanner(insertRowManually: true)
                self?.reloadRowsIfNeeded()
                self?.markMessagesReadIfNeeded()
            }
        } storedMessages: { [weak self] messages in
            self?.updateMessageDataSource(messages: messages)
            self?.markMessagesReadIfNeeded()
            self?.checkTrashedHintBanner(insertRowManually: false)
            self?.reloadTableView?()
            self?.messagesAreLoaded = true
        }
    }

    private func updateMessageDataSource(messages: [MessageEntity]) {
        var messageDataModels = messages.compactMap { messageType(with: $0) }

        if messages.count == conversation.messageCount {
            _ = expandSpecificMessage(dataModels: &messageDataModels)
        }
        if !messageDataModels.allSatisfy({ $0.message?.body.isEmpty == true }) {
            isShowingSkeletonView = false
        }
        messagesDataSource = messageDataModels
    }

    func stopObserveConversationAndMessages() {
        conversationUpdateProvider.stopObserve()
        conversationMessagesProvider.stopObserve()
    }

    func messageType(with message: MessageEntity) -> ConversationViewItemType {
        let viewModel = ConversationMessageViewModel(
            labelId: labelId,
            message: message,
            replacingEmailsMap: sharedReplacingEmailsMap,
            contactGroups: sharedContactGroups,
            dependencies: dependencies,
            highlightedKeywords: highlightedKeywords,
            goToDraft: goToDraft
        )
        return .message(viewModel: viewModel)
    }

    func getMessageHeaderUrl(message: MessageEntity) -> URL? {
        let time = dateFormatter.string(from: message.time ?? Date())
        let title = message.title.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let filename = "headers-" + time + "-" + title.joined(separator: "-")
        guard let header = message.rawHeader else {
            assert(false, "No header in message")
            return nil
        }
        return try? self.writeToTemporaryUrl(header, filename: filename)
    }

    func getMessageBodyUrl(message: MessageEntity) -> URL? {
        let time = dateFormatter.string(from: message.time ?? Date())
        let title = message.title.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let filename = "body-" + time + "-" + title.joined(separator: "-")
        guard let body = try? messageService.messageDecrypter.decrypt(message: message).0 else {
            return nil
        }
        return try? self.writeToTemporaryUrl(body, filename: filename)
    }

    func shouldTrashedHintBannerUseShowButton() -> Bool {
        if self.isTrashFolder {
            return self.displayRule == .showTrashedOnly
        } else {
            return self.displayRule == .showNonTrashedOnly
        }
    }

    func startMonitorConnectionStatus(
        isApplicationActive: @escaping () -> Bool,
        reloadWhenAppIsActive: @escaping () -> Void
    ) {
        self.isApplicationActive = isApplicationActive
        self.reloadWhenAppIsActive = reloadWhenAppIsActive
        dependencies.internetConnectionStatusProvider.register(receiver: self, fireWhenRegister: true)
    }

    func areAllMessagesIn(location: LabelLocation) -> Bool {
        let numMessagesInLocation = conversation.getNumMessages(labelID: location.labelID)
        return numMessagesInLocation == conversation.messageCount
    }

    func hasMessageEnqueuedTasks(_ messageID: MessageID) -> Bool {
        dependencies.queueManager.queuedMessageIds().contains(messageID.rawValue)
    }

    func fetchMessageDetail(message: MessageEntity,
                            callback: @escaping FetchMessageDetailUseCase.Callback) {
        let params: FetchMessageDetail.Params = .init(
            message: message
        )
        dependencies.fetchMessageDetail
            .callbackOn(.main)
            .execute(params: params, callback: callback)
    }

	func shouldShowToolbarCustomizeSpotlight() -> Bool {
        guard !ProcessInfo.hasLaunchArgument(.disableToolbarSpotlight) else {
            return false
        }

        if dependencies.userIntroductionProgressProvider.shouldShowSpotlight(for: .toolbarCustomization, toUserWith: user.userID) {
            return true
        }

        //  If 1 of the logged accounts has a non-standard set of actions, Accounts with
        //  standard actions will see the feature spotlight once when
        //  first opening message details.
        let toolbarCustomizeSpotlightShownUserIds = dependencies.userDefaults[.toolbarCustomizeSpotlightShownUserIds]
        let ifCurrentUserAlreadySeenTheSpotlight = toolbarCustomizeSpotlightShownUserIds.contains(user.userID.rawValue)
        if user.hasAtLeastOneNonStandardToolbarAction,
           user.toolbarActionsIsStandard,
           !ifCurrentUserAlreadySeenTheSpotlight {
            return true
        }
        return false
    }

    func setToolbarCustomizeSpotlightViewIsShown() {
        dependencies.userIntroductionProgressProvider.markSpotlight(
            for: .toolbarCustomization,
            asSeen: true,
            byUserWith: user.userID
        )
        dependencies.userDefaults[.toolbarCustomizeSpotlightShownUserIds].append(user.userID.rawValue)
    }

    func headerCellVisibility(at index: Int) -> CellVisibility {
        guard focusedMode else {
            return .full
        }

        switch headerSectionDataSource[index] {
        case .trashedHint:
            // in focused mode, the trashed hint should only be partially visible if there's no previous message to partially show
            let numberOfNonTrashedMessages = messagesDataSource
                .filter { $0.messageViewModel?.isTrashed == false }
                .count

            return numberOfNonTrashedMessages == 1 ? .partial : .hidden
        case .message:
            assertionFailure("headerSectionDataSource should not contain ConversationViewItemType.message")
            return .full
        }
    }

    func messageCellVisibility(at index: Int) -> CellVisibility {
        guard focusedMode else {
            return .full
        }

        // if we're in focused mode, but no message is expanded, it means that messages are still loading
        guard let firstExpandedMessageIndex = firstExpandedMessageIndex else {
            return .hidden
        }

        if index > firstExpandedMessageIndex {
            return .full
        } else {
            let messagesBeforeAndIncludingExpandedOne = messagesDataSource[0...firstExpandedMessageIndex]

            let indexesOfDisplayMessages: [Int] = messagesBeforeAndIncludingExpandedOne
                .enumerated()
                .compactMap { index, item in
                    if displayRule == .showAll {
                        return index
                    } else if item.messageViewModel?.isTrashed == true && displayRule == .showTrashedOnly {
                        return index
                    } else if item.messageViewModel?.isTrashed == false && displayRule == .showNonTrashedOnly {
                        return index
                    }
                    return nil
                }

            switch index {
            case indexesOfDisplayMessages.last:
                return .full
            case indexesOfDisplayMessages.dropLast().last:
                return .partial
            default:
                return .hidden
            }
        }
    }

    func cellTapped() {
        focusedMode = false
    }

    func fetchSenderImageIfNeeded(
        message: MessageEntity,
        isDarkMode: Bool,
        scale: CGFloat,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let senderImageRequestInfo = message.getSenderImageRequestInfo(isDarkMode: isDarkMode) else {
            completion(nil)
            return
        }

        dependencies.fetchSenderImage
            .callbackOn(.main)
            .execute(
                params: .init(
                    senderImageRequestInfo: senderImageRequestInfo,
                    scale: scale,
                    userID: user.userID
                )) { result in
                    switch result {
                    case let .success(image):
                        completion(image)
                    case .failure:
                        completion(nil)
                    }
            }
    }

    private func markMessagesReadIfNeeded() {
        messagesDataSource
            .compactMap { $0.messageViewModel?.state.expandedViewModel?.messageContent }
            .forEach { model in
                if messageIDsOfMarkedAsRead.contains(model.message.messageID) { return }
                if model.message.unRead {
                    messageIDsOfMarkedAsRead.append(model.message.messageID)
                }
                if !blockMarkReadIfNeeded {
                    model.markReadIfNeeded()
                }
            }
    }

    /// Add trashed hint banner if the messages contain trashed message
    private func checkTrashedHintBanner(insertRowManually: Bool) {
        let hasMessages = !self.messagesDataSource.isEmpty
        guard hasMessages else { return }
        let trashed = self.messagesDataSource
            .filter { $0.messageViewModel?.isTrashed ?? false }
        let hasTrashed = !trashed.isEmpty
        let isAllTrashed = trashed.count == self.messagesDataSource.count
        if self.isTrashFolder {
            checkTrashedHintBannerForTrashFolder(
                hasTrashed: hasTrashed,
                isAllTrashed: isAllTrashed,
                insertRowManually: insertRowManually
            )
        } else {
            checkTrashedHintBannerForNonTrashFolder(
                hasTrashed: hasTrashed,
                isAllTrashed: isAllTrashed,
                insertRowManually: insertRowManually
            )
        }
    }

    private func checkTrashedHintBannerForTrashFolder(hasTrashed: Bool, isAllTrashed: Bool, insertRowManually: Bool) {
        guard hasTrashed else {
            self.removeTrashedHintBanner()
            // In trash folder, without trashed message
            // Should show non trashed messages
            self.displayRule = .showNonTrashedOnly
            self.removeTrashedHintBanner()
            return
        }

        if self.displayRule == .showNonTrashedOnly {
            self.displayRule = .showTrashedOnly
        }

        if isAllTrashed {
            self.removeTrashedHintBanner()
        } else {
            self.showTrashedHintBanner(insertRowManually: insertRowManually)
        }
    }

    private func checkTrashedHintBannerForNonTrashFolder(hasTrashed: Bool, isAllTrashed: Bool, insertRowManually: Bool) {
        if isAllTrashed {
            // In non trash folder, without trashed message
            // Should show trashed messages
            self.displayRule = .showTrashedOnly
            self.removeTrashedHintBanner()
            return
        }

        if self.displayRule == .showTrashedOnly {
            self.displayRule = .showNonTrashedOnly
        }

        if hasTrashed {
            self.showTrashedHintBanner(insertRowManually: insertRowManually)
        } else {
            self.removeTrashedHintBanner()
        }
    }

    private func removeTrashedHintBanner() {
        guard let index = self.headerSectionDataSource.firstIndex(of: .trashedHint) else { return }
        self.headerSectionDataSource.remove(at: index)
        let headerIndexSet = IndexSet(integer: 0)
        self.tableView?.reloadSections(headerIndexSet, with: .automatic)
    }

    private func showTrashedHintBanner(insertRowManually: Bool) {
        if self.headerSectionDataSource.contains(.trashedHint) { return }
        self.headerSectionDataSource.append(.trashedHint)

        guard insertRowManually else {
            return
        }

        let visible = self.tableView?.visibleCells.count ?? 0
        if visible > 0 {
            let row = IndexPath(row: 0, section: 0)
            do {
                try ObjC.catchException {
                    self.tableView?.insertRows(at: [row], with: .automatic)
                }
            } catch {
                PMAssertionFailure(error)
            }
        }
    }

    private func writeToTemporaryUrl(_ content: String, filename: String) throws -> URL {
        let tempFileUri = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename, isDirectory: false).appendingPathExtension("txt")
        try? FileManager.default.removeItem(at: tempFileUri)
        try content.write(to: tempFileUri, atomically: true, encoding: .utf8)
        return tempFileUri
    }

    private func observeNewMessages() {
        if messagesDataSource.count > recordNumOfMessages && messagesDataSource.last?.message?.isDraft == false {
            showNewMessageArrivedFloaty?(messagesDataSource.newestMessage?.messageID ?? "")
        }
        recordNumOfMessages = messagesDataSource.count
    }

    private func updateDataSource(with messages: [MessageEntity]) {
        messagesDataSource = messages.map { newMessage -> ConversationViewItemType in
            if let viewModel = messagesDataSource.first(where: { $0.message?.messageID == newMessage.messageID }) {
                return viewModel
            }
            return messageType(with: newMessage)
        }
        if self.messagesDataSource.isEmpty {
            dependencies.contextProvider.performOnRootSavingContext { [weak self] context in
                guard let self = self,
                      let object = try? context.existingObject(with: self.conversation.objectID.rawValue) else {
                          self?.dismissView?()
                    return
                }
                context.delete(object)
                self.dismissView?()
            }
        }
    }

    func searchForScheduled(conversation: ConversationEntity? = nil,
                            displayAlert: @escaping (Int) -> Void,
                            continueAction: @escaping () -> Void) {
        let conversationToCheck = conversation ?? self.conversation
        guard conversationToCheck.contains(of: .scheduled) else {
            continueAction()
            return
        }
        let scheduledNum = messagesDataSource
            .compactMap { $0.message }
            .filter { $0.contains(location: .scheduled) }
            .count
        displayAlert(scheduledNum)
    }

    // MARK: - Actions

    private func perform(update: ConversationUpdateType, on tableView: UITableView) {
        guard !isShowingSkeletonView else { return }
        switch update {
        case .willUpdate:
            tableViewIsUpdating = true
            tableView.beginUpdates()
        case let .didUpdate(messages):
            updateDataSource(with: messages)
            do {
                try ObjC.catchException {
                    tableView.endUpdates()
                    self.tableViewIsUpdating = false
                }
            } catch {
                // unfortunately the error doesn't contain anything useful
                PMAssertionFailure(error)

                // this call will sync the data again at the expense of no animation
                tableView.reloadData()

                /// It's necessary to call this again for the changes made by `reloadData` to be visible,
                /// because we're in the middle of an update after the `beginUpdates` call above.
                /// Now it's safe, so we don't need to catch again.
                tableView.endUpdates()
                tableViewIsUpdating = false
            }

            observeNewMessages()

            if recordNumOfMessages == messagesDataSource.count {
                if let path = self.expandSpecificMessage(dataModels: &self.messagesDataSource) {
                    tableView.reloadRows(at: [path], with: .automatic)
                    self.conversationViewController?.attemptAutoScroll(to: path, position: .top)
                }

                self.conversationIsReadyToBeDisplayed?()
            }

            refreshView?()
        case let .insert(row):
            tableView.insertRows(at: [.init(row: row, section: 1)], with: .automatic)
        case let .update(message):
            let messageId = message.messageID
            guard let index = messagesDataSource.firstIndex(where: { $0.message?.messageID == messageId }),
                  let viewModel = messagesDataSource[index].messageViewModel else {
                return
            }
            viewModel.messageHasChanged(message: message)
        case let .delete(row, messageID):
            tableView.deleteRows(at: [.init(row: row, section: 1)], with: .automatic)
            dismissDeletedMessageActionSheet?(messageID)
        case let .move(fromRow, toRow):
            guard fromRow != toRow else { return }
            tableView.moveRow(at: .init(row: fromRow, section: 1), to: .init(row: toRow, section: 1))
        }
    }

    func starTapped(completion: @escaping (Result<Bool, Error>) -> Void) {
        if conversation.starred {
            conversationService.unlabel(conversationIDs: [conversation.conversationID],
                                        as: Message.Location.starred.labelID) { [weak self] result in
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
                                      as: Message.Location.starred.labelID) { [weak self] result in
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

    func handleActionSheetAction(_ action: MessageViewActionSheetAction, completion: @escaping () -> Void) {
        guard messagesAreLoaded else { return }

        let fetchEvents = { [weak self] (result: Result<Void, Error>) in
            guard let self = self else { return }
            if (try? result.get()) != nil { self.eventsService.fetchEvents(labelID: self.labelId) }
        }
        let moveAction = { [weak self] (destination: Message.Location) in
            guard let self = self else { return }
            self.conversationService.move(conversationIDs: [self.conversation.conversationID],
                                          from: self.labelId,
                                          to: destination.labelID,
                                          callOrigin: "ConversationViewModel - handleActionSheet",
                                          completion: fetchEvents)
        }
        switch action {
        case .markUnread:
            blockMarkReadIfNeeded = true
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
        case .print, .viewHeaders, .viewHTML, .reportPhishing, .viewInDarkMode,
             .viewInLightMode, .replyOrReplyAll, .saveAsPDF, .dismiss, .forward,
             .labelAs, .moveTo, .reply, .replyAll, .star, .unstar, .toolbarCustomization,
             .more, .replyInConversation, .forwardInConversation, .replyOrReplyAllInConversation, .replyAllInConversation:
            break
        case .snooze:
            PMAssertionFailure("Shouldn't be triggered")
            break
        }
        completion()
    }

    func findLatestMessageForAction() -> MessageEntity? {
        let messageNotDraftAndTrash = messagesDataSource
            .compactMap(\.message)
            .last { msg in
                !msg.isDraft && !msg.isTrash
            }
        guard messageNotDraftAndTrash == nil else {
            return messageNotDraftAndTrash
        }
        // If message are all in trash or draft, return the latest message that is not draft.
        return messagesDataSource
            .last(where: { $0.message?.isDraft == false })?
            .message
    }

    func isCellExpanded(messageID: MessageID) -> Bool {
        let targetSource = messagesDataSource.first(where: { $0.message?.messageID == messageID })
        return targetSource?.messageViewModel?.state.isExpanded ?? false
    }

    func expandHistoryIfNeeded(messageID: MessageID, completion: @escaping () -> Void) {
        let targetSource = messagesDataSource.first(where: { $0.message?.messageID == messageID })
        let singleMessageContentViewModel = targetSource?.messageViewModel?.state.expandedViewModel?
            .messageContent
        let targetMessageInfoProvider = singleMessageContentViewModel?.messageInfoProvider
        guard targetMessageInfoProvider?.displayMode == .collapsed else {
            completion()
            return
        }
        singleMessageContentViewModel?.webContentIsUpdated = { [weak singleMessageContentViewModel] in
            completion()
            singleMessageContentViewModel?.webContentIsUpdated = nil
        }
        targetMessageInfoProvider?.displayMode = .expanded
    }

    func getMessageBodyBy(messageID: MessageID) -> String? {
        let viewModel = messagesDataSource
            .first(where: { $0.message?.messageID == messageID })
        let singleMessageVM = viewModel?.messageViewModel?.state.expandedViewModel?.messageContent
        let infoProvider = singleMessageVM?.messageInfoProvider
        return infoProvider?.bodyParts?.originalBody
    }
}

// MARK: - Toolbar action functions
extension ConversationViewModel: ToolbarCustomizationActionHandler {

    func toolbarActionTypes() -> [MessageViewActionSheetAction] {
        let locationIsInSpam = labelId == Message.Location.spam.labelID
        let locationIsInTrash = labelId == Message.Location.trash.labelID
        let locationIsInArchive = labelId == Message.Location.archive.labelID
        let isConversationRead = !conversation.isUnread(labelID: labelId)
        let isConversationStarred = conversation.starred
        let isInArchive = areAllMessagesInThreadInTheArchive
        let isInTrash = areAllMessagesInThreadInTheTrash
        let isInSpam = areAllMessagesInThreadInSpam

        let foldersSupportingSnooze = [
            Message.Location.inbox.labelID,
            Message.Location.snooze.labelID
        ]
        let isSupportSnooze = foldersSupportingSnooze.contains(labelId)

        var actions = toolbarActionProvider.messageToolbarActions
            .addMoreActionToTheLastLocation()
            .replaceReplyAndReplyAllWithConversationVersion()
            .replaceForwardWithConversationVersion()
        if !isSupportSnooze {
            actions.removeAll(where: { $0 == .snooze })
        }

        let messageForAction = findLatestMessageForAction()
        let hasMultipleRecipients = (messageForAction?.allRecipients.count ?? 0) > 1
        if messageForAction?.isScheduledSend == true {
            let forbidActions: [MessageViewActionSheetAction] = [
                .replyInConversation,
                .replyOrReplyAllInConversation,
                .replyAllInConversation,
                .reply,
                .forward,
                .forwardInConversation,
                .replyAll,
                .replyOrReplyAll
            ]
            actions = actions.filter { !forbidActions.contains($0) }
        }

        return replaceActionsLocally(actions: actions,
                                     isInSpam: isInSpam || locationIsInSpam,
                                     isInTrash: isInTrash || locationIsInTrash,
                                     isInArchive: isInArchive || locationIsInArchive,
                                     isRead: isConversationRead,
                                     isStarred: isConversationStarred,
                                     hasMultipleRecipients: hasMultipleRecipients)
    }

    func toolbarCustomizationAllAvailableActions() -> [MessageViewActionSheetAction] {
        let foldersSupportingSnooze = [
            Message.Location.snooze.labelID,
            Message.Location.inbox.labelID
        ]

        let actionSheetViewModel = MessageViewActionSheetViewModel(
            title: "",
            labelID: labelId,
            isStarred: true,
            isBodyDecryptable: true,
            messageRenderStyle: .lightOnly,
            shouldShowRenderModeOption: false,
            isScheduledSend: false,
            shouldShowSnooze: foldersSupportingSnooze.contains(labelId)
        )
        let isInSpam = conversation.contains(of: .spam)
        let isInArchive = conversation.contains(of: .archive)
        let isInTrash = areAllMessagesInThreadInTheTrash || conversation.contains(of: .trash)
        let isConversationRead = !conversation.isUnread(labelID: labelId)
        let isConversationStarred = conversation.starred
        let messageForAction = findLatestMessageForAction()
        let hasMultipleRecipients = (messageForAction?.allRecipients.count ?? 0) > 1

        let actions = actionSheetViewModel.items
            .replaceReplyAndReplyAllWithConversationVersion()
            .replaceForwardWithConversationVersion()
        return replaceActionsLocally(
            actions: actions,
            isInSpam: isInSpam,
            isInTrash: isInTrash,
            isInArchive: isInArchive,
            isRead: isConversationRead,
            isStarred: isConversationStarred,
            hasMultipleRecipients: hasMultipleRecipients
        )
    }

    func saveToolbarAction(actions: [MessageViewActionSheetAction],
                           completion: ((NSError?) -> Void)?) {
        let preference: ToolbarActionPreference = .init(
            messageActions: actions,
            listViewActions: nil
        )
        saveToolbarActionUseCase
            .callbackOn(.main)
            .execute(params: .init(preference: preference)) { result in
                switch result {
                case .success:
                    completion?(nil)
                case let .failure(error):
                    completion?(error as NSError)
                }
            }
    }

    func handleNavigationAction(_ action: ConversationNavigationAction) {
        coordinator.handle(navigationAction: action)
    }

    func sendSwipeNotificationIfNeeded(isInPageView: Bool) {
        guard
            isInPageView,
            dependencies.nextMessageAfterMoveStatusProvider.shouldMoveToNextMessageAfterMove
        else { return }
        let userInfo: [String: Any] = ["expectation": PagesSwipeAction.forward, "reload": true]
        dependencies.notificationCenter.post(name: .pagesSwipeExpectation, object: nil, userInfo: userInfo)
    }
}

// MARK: - Label As Action Sheet Implementation
extension ConversationViewModel: LabelAsActionSheetProtocol {
    func handleLabelAsAction(messages: [MessageEntity],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetItem.MarkType]) {
        guard let message = messages.first else { return }
        for (label, status) in currentOptionsStatus {
            guard status != .dash else { continue } // Ignore the option in dash
            if selectedLabelAsLabels
                .contains(where: { $0.rawLabelID == label.location.rawLabelID }) {
                // Add to message which does not have this label
                if !message.contains(location: label.location) {
                    messageService.label(messages: messages,
                                         label: label.location.labelID,
                                         apply: true)
                }
            } else {
                if message.contains(location: label.location) {
                    messageService.label(messages: messages,
                                         label: label.location.labelID,
                                         apply: false)
                }
            }
        }

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            if let fLabel = message.getFirstValidFolder() {
                messageService.move(messages: messages,
                                    from: [fLabel],
                                    to: Message.Location.archive.labelID)
            }
        }
    }

    func handleLabelAsAction(conversations: [ConversationEntity],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetItem.MarkType],
                             completion: (() -> Void)?) {
        let group = DispatchGroup()
        let fetchEvents = { [weak self] (result: Result<Void, Error>) in
            defer {
                group.leave()
            }
            guard let self = self else { return }
            if (try? result.get()) != nil {
                self.eventsService.fetchEvents(labelID: self.labelId)
            }
        }
        for (label, status) in currentOptionsStatus {
            guard status != .dash else { continue } // Ignore the option in dash
            if selectedLabelAsLabels
                .contains(where: { $0.rawLabelID == label.location.rawLabelID }) {
				group.enter()
                let conversationIDsToApply = conversationService
                    .findConversationIDsToApplyLabels(conversations: conversations, labelID: label.location.labelID)
                conversationService.label(conversationIDs: conversationIDsToApply,
                                          as: label.location.labelID,
                                          completion: fetchEvents)
            } else {
                let conversationIDsToRemove = conversationService
                    .findConversationIDSToRemoveLabels(conversations: conversations,
                                                       labelID: label.location.labelID)
				group.enter()
                conversationService.unlabel(conversationIDs: conversationIDsToRemove,
                                            as: label.location.labelID,
                                            completion: fetchEvents)
            }
        }

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            if let fLabel = conversation.getFirstValidFolder() {
                group.enter()
                let ids = conversations.map(\.conversationID)
                conversationService.move(conversationIDs: ids,
                                         from: fLabel,
                                         to: Message.Location.archive.labelID,
                                         callOrigin: "ConversationViewModel - labelAs",
                                         completion: fetchEvents)
            }
        }
        group.notify(queue: .main) {
            completion?()
        }
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
            defer {
                self.targetID = nil
            }
            if dataModels[index].messageViewModel?.isDraft ?? false {
                draftID = targetID
                // The draft can't expand
                return nil
            }
            dataModels[index].messageViewModel?.toggleState()
            return IndexPath(row: index, section: 1)
        }

        // open the latest message if it contains all_sent label and is read.
        if let latestMessageIndex = dataModels.lastIndex(where: { $0.message?.isDraft == false }),
           let latestMessage = dataModels[safe: latestMessageIndex]?.message,
           latestMessage.contains(location: .hiddenSent),
           latestMessage.unRead == false {
            dataModels[latestMessageIndex].messageViewModel?.toggleState()
            return IndexPath(row: latestMessageIndex, section: 1)
        }

        let isLatestMessageUnread = dataModels.isLatestMessageUnread(location: labelId)

        switch labelId {
        case Message.Location.allmail.labelID, Message.Location.spam.labelID:
            indexToOpen = getIndexOfMessageToExpandInSpamOrAllMail(dataModels: dataModels,
                                                                   isLatestMessageUnread: isLatestMessageUnread)
        case Message.Location.trash.labelID:
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

    private func getLatestMessageIndex(of labelID: LabelID?,
                                       dataModels: [ConversationViewItemType],
                                       excludeDraft: Bool = true,
                                       excludeTrash: Bool = true) -> Int? {
        let shouldCheckLabelId = labelID != nil
        if let latestMessageModelIndex = dataModels.lastIndex(where: {
            ($0.message?.contains(labelID: labelId) == true || !shouldCheckLabelId) &&
            ($0.message?.isDraft == false || !excludeDraft) &&
            ($0.message?.contains(location: .trash) == false || !excludeTrash)
        }) {
            return latestMessageModelIndex
        } else {
            return nil
        }
    }

    private func getTheOldestIndexOfTheLatestChunckOfUnreadMessages(dataModels: [ConversationViewItemType],
                                                                    targetLabelID: LabelID? = nil,
                                                                    shouldExcludeTrash: Bool = false) -> Int? {
        // find the oldeset message of latest chunk of unread messages
        if let latestIndex = getLatestMessageIndex(of: targetLabelID,
                                                   dataModels: dataModels,
                                                   excludeTrash: shouldExcludeTrash) {
            var indexOfOldestUnreadMessage: Int?
            for index in (0...latestIndex).reversed() {
                if dataModels[index].message?.unRead != true || dataModels[index].message?.isDraft == true {
                    break
                }
                if shouldExcludeTrash && (dataModels[index].message?.contains(location: .trash) == true) {
                    break
                }
                if let labelToCheck = targetLabelID,
                   dataModels[index].message?.contains(labelID: labelToCheck) == false {
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

    func handleMoveToAction(messages: [MessageEntity], to folder: MenuLabel) {
        user.messageService.move(messages: messages, to: folder.location.labelID)
    }

    func handleMoveToAction(
        conversations: [ConversationEntity],
        to folder: MenuLabel
    ) {
        let ids = conversations.map(\.conversationID)
        conversationService.move(
            conversationIDs: ids,
            from: "",
            to: folder.location.labelID,
            callOrigin: "ConversationViewModel - moveTo"
        ) { [weak self] result in
            guard let self = self else { return }
            if (try? result.get()) != nil {
                self.eventsService.fetchEvents(labelID: self.labelId)
            }
        }
    }
}

extension ConversationViewModel: ConversationViewTrashedHintDelegate {
    func clickTrashedMessageSettingButton() {
        // If we're in the focused mode, the trash banner is only partially visible (if at all).
        guard !focusedMode else {
            return
        }

        switch self.displayRule {
        case .showTrashedOnly:
            self.displayRule = .showAll
        case .showNonTrashedOnly:
            self.displayRule = .showAll
        case .showAll:
            self.displayRule = self.isTrashFolder ? .showTrashedOnly : .showNonTrashedOnly
        }
        let row = IndexPath(row: 0, section: 0)
        self.reloadRowsIfNeeded(additional: row)
    }

    private func reloadRowsIfNeeded(additional: IndexPath? = nil) {
        guard self.messagesDataSource.isEmpty == false else {
            if let additional = additional {
                self.reloadRows?([additional])
            }
            return
        }
        let messagePaths = Array([Int](0..<self.messagesDataSource.count)).map { IndexPath(row: $0, section: 1) }

        var indexPaths: [IndexPath] = messagePaths.filter { [weak self] indexPath in
            guard let self = self,
                  indexPath.section == 1 else { return false }
            let row = indexPath.row
            guard let cell = self.tableView?.cellForRow(at: indexPath),
                  let item = self.messagesDataSource[safe: row],
                  let viewModel = item.messageViewModel else {
                      return false
                  }
            let cellClass = String(describing: cell.classForCoder)
            let defaultClass = String(describing: UITableViewCell.self)
            switch self.displayRule {
            case .showAll:
                return cell.bounds.height == 0
            case .showTrashedOnly:
                if viewModel.isTrashed && cellClass == defaultClass {
                    return true
                } else if !viewModel.isTrashed && cellClass != defaultClass {
                    return true
                }
                return false
            case .showNonTrashedOnly:
                if viewModel.isTrashed && cellClass != defaultClass {
                    return true
                } else if !viewModel.isTrashed && cellClass == defaultClass {
                    return true
                }
                return false
            }
        }
        if let additional = additional {
            indexPaths.append(additional)
        }
        if indexPaths.isEmpty { return }
        self.reloadRows?(indexPaths)
    }
}

extension ConversationViewModel: ConversationStateServiceDelegate {
    func viewModeHasChanged(viewMode: ViewMode) {
        viewModeIsChanged?(viewMode)
    }
}

extension ConversationViewModel {
    enum CellVisibility {
        /// The cell is fully visible.
        case full
        /// Only a few pixels are visible, used for showing a part of the previous message in focused mode.
        case partial
        /// The cell is not visible.
        case hidden
    }
}

// MARK: - ConnectionStatusReceiver
extension ConversationViewModel: ConnectionStatusReceiver {
    func connectionStatusHasChanged(newStatus: ConnectionStatus) {
        guard isInitialDataFetchCalled == true else {
            return
        }
        guard let isApplicationActiveClosure = isApplicationActive,
              let reloadWhenAppIsActiveClosure = reloadWhenAppIsActive else {
            return
        }
        let isApplicationActive = isApplicationActiveClosure()
        switch isApplicationActive {
        case true where newStatus == .notConnected:
            break
        case true:
            fetchConversationDetails(completion: nil)
        default:
            reloadWhenAppIsActiveClosure()
        }
    }
}
