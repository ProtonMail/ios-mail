//
//  MailboxViewModel.swift
//  Proton Mail - Created on 8/15/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import CoreData
import ProtonCoreDataModel
import ProtonCoreUtilities
import ProtonCoreServices
import ProtonCoreUIFoundations
import ProtonMailAnalytics

struct LabelInfo {
    let name: String

    init(name: String) {
        self.name = name
    }
}

protocol MailboxViewModelUIProtocol: AnyObject {
    func updateTitle()
    func updateUnreadButton(count: Int)
    func updateTheUpdateTimeLabel()
    func selectionDidChange()
}

class MailboxViewModel: NSObject, StorageLimit, UpdateMailboxSourceProtocol {
    typealias Dependencies = HasCheckProtonServerStatus
    & HasFeatureFlagCache
    & HasFetchAttachment
    & HasFetchAttachmentMetadataUseCase
    & HasFetchMessageDetailUseCase
    & HasFetchMessages
    & HasFetchSenderImage
    & HasMailEventsPeriodicScheduler
    & HasUpdateMailbox
    & HasUserDefaults
    & HasUserIntroductionProgressProvider

    let labelID: LabelID
    /// This field saves the label object of custom folder/label
    private(set) var label: LabelInfo?
    /// This field stores the latest update time of the user event.
    private var latestEventUpdateTime: Date?
    var messageLocation: Message.Location? {
        return Message.Location(rawValue: labelID.rawValue)
    }
    /// message service
    internal let user: UserManager
    internal let messageService: MessageDataService
    internal let eventsService: EventsFetching
    private let pushService: PushNotificationServiceProtocol
    /// fetch controller
    private(set) var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    private var labelPublisher: MailboxLabelPublisher?
    private var eventUpdatePublisher: EventUpdatePublisher?
    private var unreadCounterPublisher: UnreadCounterPublisher?
    var unreadCount: Int {
        unreadCounterPublisher?.unreadCount ?? 0
    }

    private(set) var selectedIDs: Set<String> = Set()

    var selectedLabelAsLabels: Set<LabelLocation> = Set()

    private let lastUpdatedStore: LastUpdatedStoreProtocol
    let coreDataContextProvider: CoreDataContextProviderProtocol
    private let conversationStateProvider: ConversationStateProviderProtocol
    private let contactGroupProvider: ContactGroupsProviderProtocol
    let labelProvider: LabelProviderProtocol
    private let contactProvider: ContactProviderProtocol
    let conversationProvider: ConversationProvider

    var viewModeIsChanged: (() -> Void)?
    var sendHapticFeedback:(() -> Void)?
    let totalUserCountClosure: () -> Int
    var isHavingUser: Bool {
        return totalUserCountClosure() > 0
    }
    var isFetchingMessage: Bool {
        dependencies.updateMailbox.isFetching
    }
    private(set) var isFirstFetch: Bool = true

    weak var uiDelegate: MailboxViewModelUIProtocol?

    private let dependencies: Dependencies

    /// `swipyCellDidSwipe` will be setting this value repeatedly during a swipe gesture.
    /// We only want to send a haptic signal one a state change.
    private var swipingTriggerActivated = false {
        didSet {
            if swipingTriggerActivated != oldValue {
                sendHapticFeedback?()
            }
        }
    }

    let toolbarActionProvider: ToolbarActionProvider
    let saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase

    var listEditing: Bool = false {
        didSet {
            if !listEditing {
                selectedIDs.removeAll()
            }
        }
    }

    var shouldAutoShowInAppFeedbackPrompt: Bool {
        !ProcessInfo.hasLaunchArgument(.disableInAppFeedbackPromptAutoShow)
    }

    var isNewEventLoopEnabled: Bool {
        user.isNewEventLoopEnabled
    }

    private var prefetchedItemsCount: Atomic<Int> = .init(0)
    private var isPrefetching: Atomic<Bool> = .init(false)

    private(set) var diffableDataSource: MailboxDiffableDataSource?

    init(labelID: LabelID,
         label: LabelInfo?,
         userManager: UserManager,
         pushService: PushNotificationServiceProtocol,
         coreDataContextProvider: CoreDataContextProviderProtocol,
         lastUpdatedStore: LastUpdatedStoreProtocol,
         conversationStateProvider: ConversationStateProviderProtocol,
         contactGroupProvider: ContactGroupsProviderProtocol,
         labelProvider: LabelProviderProtocol,
         contactProvider: ContactProviderProtocol,
         conversationProvider: ConversationProvider,
         eventsService: EventsFetching,
         dependencies: Dependencies,
         toolbarActionProvider: ToolbarActionProvider,
         saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase,
         totalUserCountClosure: @escaping () -> Int
    ) {
        self.labelID = labelID
        self.label = label
        self.user = userManager
        self.messageService = userManager.messageService
        self.eventsService = eventsService
        self.coreDataContextProvider = coreDataContextProvider
        self.pushService = pushService
        self.lastUpdatedStore = lastUpdatedStore
        self.conversationStateProvider = conversationStateProvider
        self.contactGroupProvider = contactGroupProvider
        self.contactProvider = contactProvider
        self.totalUserCountClosure = totalUserCountClosure
        self.labelProvider = labelProvider
        self.conversationProvider = conversationProvider
        self.dependencies = dependencies
        self.toolbarActionProvider = toolbarActionProvider
        self.saveToolbarActionUseCase = saveToolbarActionUseCase
        super.init()
        self.conversationStateProvider.add(delegate: self)
        dependencies.updateMailbox.setup(source: self)
    }

    /// localized navigation title. override it or return label name
    var localizedNavigationTitle: String {
        guard let location = Message.Location(labelID) else {
            return label?.name ?? ""
        }
        return location.localizedTitle
    }

    var currentViewMode: ViewMode {
        conversationStateProvider.viewMode
    }

    var locationViewMode: ViewMode {
        let singleMessageOnlyLabels: [Message.Location] = [.draft, .sent, .scheduled]
        if let location = Message.Location(labelID),
           singleMessageOnlyLabels.contains(location),
           self.conversationStateProvider.viewMode == .conversation {
            return .singleMessage
        }
        return self.conversationStateProvider.viewMode
    }

    var isTrashOrSpam: Bool {
        let ids = [
            LabelLocation.trash.labelID,
            LabelLocation.spam.labelID
        ]
        return ids.contains(self.labelID)
    }

    var isCurrentUserSelectedUnreadFilterInInbox: Bool {
        get {
            return self.user.isUserSelectedUnreadFilterInInbox
        }
        set {
            self.user.isUserSelectedUnreadFilterInInbox = newValue
        }
    }

    var actionSheetViewModel: MailListActionSheetViewModel {
        return .init(
            labelId: labelId.rawValue,
            title: .actionSheetTitle(selectedCount: selectedIDs.count, viewMode: locationViewMode),
            locationViewMode: locationViewMode
        )
    }

    // Needs refactor to test

    var isInDraftFolder: Bool {
        return labelID.rawValue == Message.Location.draft.rawValue
    }

    var countOfFetchedObjects: Int {
        diffableDataSource?.snapshot().numberOfItems ?? 0
    }

    var selectedMessages: [MessageEntity] {
        let msgs = diffableDataSource?.snapshot().itemIdentifiers
            .compactMap { row in
                if case .real(let item) = row, case .message(let msg) = item {
                    return msg
                } else {
                    return nil
                }
            }.filter { selectedIDs.contains($0.messageID.rawValue) }
        return msgs ?? []
    }

    var selectedConversations: [ConversationEntity] {
        let conversations = diffableDataSource?.snapshot().itemIdentifiers
            .compactMap { row in
                if case .real(let item) = row, case .conversation(let conversation) = item {
                    return conversation
                } else {
                    return nil
                }
            }.filter { selectedIDs.contains($0.conversationID.rawValue) }
        return conversations ?? []
    }

    var selectedItems: [MailboxItem] {
        switch locationViewMode {
        case .conversation:
            return selectedConversations.map(MailboxItem.conversation)
        case .singleMessage:
            return selectedMessages.map(MailboxItem.message)
        }
    }

    var isAllLoadedMessagesSelected: Bool {
        selectedItems.count == rowCount(section: 0)
    }

    // Fetched by each cell in the view, use lazy to avoid fetching too much times
    lazy private(set) var customFolders: [LabelEntity] = {
        labelProvider.getCustomFolders()
    }()

    var allEmails: [EmailEntity] {
        return contactProvider.getAllEmails()
    }

    func setupDiffableDataSource(
        tableView: UITableView,
        cellConfigurator: @escaping (UITableView, IndexPath, MailboxRow) -> UITableViewCell
    ) {
        diffableDataSource = .init(tableView: tableView, cellProvider: cellConfigurator)
    }

    func contactGroups() -> [ContactGroupVO] {
        contactGroupProvider.getAllContactGroupVOs()
    }

    func fetchContacts() {
        contactProvider.fetchContacts(completion: nil)
    }

    func resetTourValue() {
        dependencies.userDefaults[.lastTourVersion] = Constants.App.TourVersion
    }

    func shouldShowShowSnoozeSpotlight() -> Bool {
        guard UserInfo.isSnoozeEnable, !ProcessInfo.isRunningUITests else { return false }
        return dependencies.userIntroductionProgressProvider.shouldShowSpotlight(for: .snooze, toUserWith: user.userID)
    }

    func hasSeenSnoozeSpotlight() {
        guard UserInfo.isSnoozeEnable else { return }
        dependencies.userIntroductionProgressProvider.markSpotlight(for: .snooze, asSeen: true, byUserWith: user.userID)
    }

    func tagUIModels(for conversation: ConversationEntity) -> [TagUIModel] {
        let labelIDs = conversation.contextLabelRelations.map(\.labelID.rawValue)
        let request = NSFetchRequest<Label>(entityName: Label.Attributes.entityName)

        /// This regex means "contains more than just digits" and is used to differentiate:
        /// - system labelIDs which contains only digits
        /// - custom labelIDs which are UUIDs
        let isCustomLabelRegex = "(?!^\\d+$)^.+$"

        let predicates: [NSPredicate] = [
            NSPredicate(format: "%K IN %@", Label.Attributes.labelID, labelIDs),
            NSPredicate(format: "%K == %u", Label.Attributes.type, LabelEntity.LabelType.messageLabel.rawValue),
            NSPredicate(format: "%K == %@", Label.Attributes.userID, user.userID.rawValue),
            NSPredicate(format: "%K MATCHES %@", Label.Attributes.labelID, isCustomLabelRegex)
        ]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        request.sortDescriptors = [
            NSSortDescriptor(key: "order", ascending: true)
        ]

        var output: [TagUIModel] = []

        if let expirationTime = conversation.expirationTime {
            if conversation.isExpiring() {
                let title = expirationTime.countExpirationTime(processInfo: userCachedStatus)
                let expirationDateTag = TagUIModel(
                    title: title,
                    titleColor: ColorProvider.InteractionStrong,
                    titleWeight: .regular,
                    icon: IconProvider.hourglass,
                    tagColor: ColorProvider.InteractionWeak
                )
                output.append(expirationDateTag)
            }
        }

        do {
            let orderedCustomLabels = try coreDataContextProvider.read { context in
                try context.fetch(request).map(LabelEntity.init(label:))
            }

            let tags = orderedCustomLabels.map { label in
                TagUIModel(
                    title: label.name,
                    titleColor: .white,
                    titleWeight: .semibold,
                    icon: nil,
                    tagColor: UIColor(hexString: label.color, alpha: 1.0)
                )
            }

            output.append(contentsOf: tags)
        } catch {
            PMAssertionFailure(error)
        }

        return output
    }

    /// create a fetch controller with labelID
    ///
    /// - Returns: fetched result controller
    private func makeFetchController(isUnread: Bool) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let isAscending = self.labelID == Message.Location.scheduled.labelID ? true : false
        let fetchedResultsController = messageService.fetchedResults(
            by: self.labelID,
            viewMode: self.locationViewMode,
            isUnread: isUnread,
            isAscending: isAscending
        )
        return fetchedResultsController
    }

    private func makeLabelPublisherIfNeeded() {
        guard Message.Location(labelID) == nil else {
            return
        }
        labelPublisher = MailboxLabelPublisher(contextProvider: coreDataContextProvider)
        labelPublisher?.startObserve(
            labelID: labelID,
            userID: user.userID,
            onContentChanged: { [weak self] labels in
                if let label = labels.first {
                    self?.label = .init(name: label.name)
                    self?.uiDelegate?.updateTitle()
                }
            }
        )
    }

    private func makeUnreadCounterPublisher() {
        unreadCounterPublisher = .init(
            contextProvider: coreDataContextProvider,
            userID: user.userID
        )
        unreadCounterPublisher?.startObserve(
            labelID: labelID,
            viewMode: locationViewMode,
            onContentChanged: { [weak self] unreadCount in
                self?.uiDelegate?.updateUnreadButton(count: unreadCount)
            }
        )
    }

	private func makeEventPublisher() {
        eventUpdatePublisher = .init(contextProvider: coreDataContextProvider)
        eventUpdatePublisher?.startObserve(
            userID: user.userID,
            onContentChanged: { [weak self] events in
                self?.latestEventUpdateTime = events.first?.updateTime
                self?.uiDelegate?.updateTheUpdateTimeLabel()
            })
	}

    /// Setup fetch controller to fetch message of specific labelID
    ///
    /// - Parameter delegate: delegate from viewcontroller
    /// - Parameter isUnread: the flag used to filter the unread message or not
    func setupFetchController(_ delegate: NSFetchedResultsControllerDelegate?, isUnread: Bool = false) {
        fetchedResultsController = self.makeFetchController(isUnread: isUnread)
        fetchedResultsController?.delegate = delegate
        fetchedResultsController?.managedObjectContext.perform {
            do {
                try self.fetchedResultsController?.performFetch()
            } catch {
                PMAssertionFailure(error)
            }
        }

        makeLabelPublisherIfNeeded()
        makeEventPublisher()
        makeUnreadCounterPublisher()
    }

    /// reset delegate if fetch controller is valid
    func resetFetchedController() {
        if let controller = self.fetchedResultsController {
            controller.delegate = nil
            self.fetchedResultsController = nil
        }
    }

    // MARK: - table view usesage

    /// get section cound
    ///
    /// - Returns:
    func sectionCount() -> Int {
        return diffableDataSource?.snapshot().numberOfSections ?? 0
    }

    /// get row count of a section
    ///
    /// - Parameter section: section index
    /// - Returns: row count
    func rowCount(section: Int) -> Int {
        guard diffableDataSource?.snapshot().indexOfSection(section) != nil else { return 0 }
        return diffableDataSource?.snapshot().numberOfItems(inSection: section) ?? 0
    }

    /// get message item from a indexpath
    ///
    /// - Parameter index: table cell indexpath
    /// - Returns: message (nil)
    func item(index: IndexPath) -> MessageEntity? {
        if let item = diffableDataSource?.item(of: index),
           case .real(let mailboxItem) = item,
           case .message(let messageEntity) = mailboxItem {
            return messageEntity
        } else {
            return nil
        }
    }

    func itemOfConversation(index: IndexPath) -> ConversationEntity? {
        if let item = diffableDataSource?.item(of: index),
           case .real(let mailboxItem) = item,
           case .conversation(let conversationEntity) = mailboxItem {
            return conversationEntity
        } else {
            return nil
        }
    }

    func mailboxItem(at indexPath: IndexPath) -> MailboxItem? {
        if let message = item(index: indexPath) {
            return .message(message)
        } else if let conversation = itemOfConversation(index: indexPath) {
            return .conversation(conversation)
        } else {
            return nil
        }
    }

    // MARK: - operations

    /// clean up the rate/review items
    func cleanReviewItems() {
        self.user.cacheService.cleanReviewItems()
    }

    /// check if need to load more older messages
    ///
    /// - Parameter index: the current table index
    /// - Returns: yes or no
    func loadMore(index: IndexPath) -> Bool {
        let snapshot = diffableDataSource?.snapshot()
        guard let number = snapshot?.numberOfSections else {
            return false
        }
        guard number > index.section else {
            return false
        }
        guard let total = snapshot?.numberOfItems(inSection: index.section) else {
            return false
        }
        if total - index.row <= 2 {
            return true
        }
        return false
    }

    /// the latest cache time of current location
    ///
    /// - Returns: location cache info
    func lastUpdateTime() -> LabelCountEntity? {
        // handle the message update in the draft location since the `FetchMessage` UseCase uses the following labelID to update the time info
        var id = labelID
        if id == LabelLocation.draft.labelID {
            id = LabelLocation.hiddenDraft.labelID
        } else if id == LabelLocation.sent.labelID {
            id = LabelLocation.hiddenSent.labelID
        }

        return lastUpdatedStore.lastUpdate(by: id, userID: user.userID, type: locationViewMode)
    }

    func getLastUpdateTimeText() -> String {
        var result = LocalString._mailblox_last_update_time_more_than_1_hour

        if let updateTime = latestEventUpdateTime {
            let time = updateTime.timeIntervalSinceReferenceDate
            let differenceFromNow = Int(Date().timeIntervalSinceReferenceDate - time)

            guard differenceFromNow >= 0 else {
                return ""
            }

            let hour = differenceFromNow / 3600
            let minute = differenceFromNow / 60

            if hour >= 1 {
                result = LocalString._mailblox_last_update_time_more_than_1_hour
            } else if minute < 60 && minute >= 1 {
                result = String.localizedStringWithFormat(LocalString._mailblox_last_update_time, minute)
            } else if minute < 1 && differenceFromNow < 60 {
                result = LocalString._mailblox_last_update_time_just_now
            }
        }
        return result
    }

    func updateListAndCounter(complete: @escaping (LabelCountEntity?) -> Void) {
        let group = DispatchGroup()
        group.enter()
        self.messageService.updateMessageCount {
            group.leave()
        }

        group.enter()
        self.fetchMessages(time: 0, forceClean: false, isUnread: false) { _ in
            group.leave()
        }

        group.notify(queue: DispatchQueue.main) {
            delay(0.2) {
                // For operation context sync with main context
                let count = self.user.labelService.lastUpdate(by: self.labelID, userID: self.user.userID)
                complete(count)
            }

        }
    }

    func getEmptyFolderCheckMessage(count: Int) -> String {
        let format = self.currentViewMode == .conversation ? LocalString._clean_conversation_warning: LocalString._clean_message_warning
        let message = String(format: format, count)
        return message
    }

    func emptyFolder() {
        let isTrashFolder = self.labelID == LabelLocation.trash.labelID
        let location: Message.Location = isTrashFolder ? .trash: .spam
        self.messageService.empty(location: location)
    }

    /// process push
    func processCachedPush() {
        self.pushService.processCachedLaunchOptions()
    }

    func fetchConversationDetail(conversationID: ConversationID, completion: @escaping () -> Void) {
        conversationProvider.fetchConversation(with: conversationID, includeBodyOf: nil, callOrigin: "MailboxViewModel") { result in
            assert(result.error == nil)

            DispatchQueue.main.async {
                completion()
            }
        }
    }

    final func resetNotificationMessage() {
        messageService.pushNotificationMessageID = nil
    }

    /// this is a workaground for draft. somehow back from the background the fetch controller can't get the latest data. remove this when fix this issue
    ///
    /// - Returns: bool
    func reloadTable() -> Bool {
        return labelID.rawValue == Message.Location.draft.rawValue
    }

    func deleteSelectedIDs() {
        switch locationViewMode {
        case .conversation:
            deletePermanently(conversationIDs: selectedConversations.map(\.conversationID))
        case .singleMessage:
            messageService.delete(messages: selectedMessages, label: self.labelID)
        }
    }

    private func deletePermanently(conversationIDs: [ConversationID]) {
        conversationProvider.deleteConversations(with: conversationIDs, labelID: self.labelID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.eventsService.fetchEvents(labelID: self.labelId)
            case .failure(let error):
                assertionFailure("\(error)")
            }
        }
    }

    func checkStorageIsCloseLimit() {
        let usedStorageSpace = user.userInfo.usedSpace
        let maxStorageSpace = user.userInfo.maxSpace
        checkSpace(usedStorageSpace,
                   maxSpace: maxStorageSpace,
                   userID: user.userInfo.userId)
    }

    func handleActionSheetAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .unstar:
            handleUnstarAction(on: selectedItems)
        case .star:
            handleStarAction(on: selectedItems)
        case .markRead:
            handleMarkReadAction(on: selectedItems)
        case .markUnread:
            handleMarkUnreadAction(on: selectedItems)
        case .trash:
            handleRemoveAction(on: selectedItems)
        case .archive:
            handleMoveToArchiveAction(on: selectedItems)
        case .spam:
            handleMoveToSpamAction(on: selectedItems)
        case .labelAs, .moveTo:
            // TODO: add action
            break
        case .snooze:
            // TODO: snooze:action MAILIOS-3996
            break
        case .inbox:
            handleMoveToInboxAction(on: selectedItems)
        case .delete, .dismiss, .toolbarCustomization, .reply, .replyAll, .forward, .print, .viewHeaders, .viewHTML, .reportPhishing, .spamMoveToInbox, .viewInDarkMode, .viewInLightMode, .more, .replyOrReplyAll, .saveAsPDF, .replyInConversation, .forwardInConversation, .replyOrReplyAllInConversation, .replyAllInConversation:
            break
        }
    }

    func getTimeOfItem(at indexPath: IndexPath) -> Date? {
        mailboxItem(at: indexPath)?.time(labelID: labelID)
    }

    func getOnboardingDestination() -> MailboxCoordinator.Destination? {
        guard let tourVersion = dependencies.userDefaults[.lastTourVersion] else {
            return .onboardingForNew
        }
        if tourVersion == Constants.App.TourVersion {
            return nil
        } else {
            return .onboardingForUpdate
        }
    }

    private func handleMoveToInboxAction(on items: [MailboxItem]) {
        move(items: items, from: labelID, to: Message.Location.inbox.labelID)
    }

    private func handleMoveToArchiveAction(on items: [MailboxItem]) {
        move(items: items, from: labelID, to: Message.Location.archive.labelID)
    }

    private func handleMoveToSpamAction(on items: [MailboxItem]) {
        move(items: items, from: labelID, to: Message.Location.spam.labelID)
    }

    private func handleUnstarAction(on items: [MailboxItem]) {
        let starredItemIDs = items
            .filter(\.isStarred)
            .map(\.itemID)

        label(IDs: Set<String>(starredItemIDs), with: Message.Location.starred.labelID, apply: false)
    }

    private func handleStarAction(on items: [MailboxItem]) {
        let unstarredItemIDs = items
            .filter { !$0.isStarred }
            .map(\.itemID)

        label(IDs: Set<String>(unstarredItemIDs), with: Message.Location.starred.labelID, apply: true)
    }

    private func handleMarkReadAction(on items: [MailboxItem]) {
        let unreadItemsIDs = items
            .filter { $0.isUnread(labelID: labelID) }
            .map(\.itemID)

        mark(IDs: Set(unreadItemsIDs), unread: false)
    }

    private func handleMarkUnreadAction(on items: [MailboxItem]) {
        let readItemsIDs = items
            .filter { !$0.isUnread(labelID: labelID) }
            .map(\.itemID)

        mark(IDs: Set(readItemsIDs), unread: true)
    }

    private func handleRemoveAction(on items: [MailboxItem]) {
        move(items: items, from: labelID, to: Message.Location.trash.labelID)
    }

    func searchForScheduled(swipeSelectedID: [String],
                            displayAlert: @escaping (Int) -> Void,
                            continueAction: @escaping () -> Void) {
        swipeSelectedID.forEach { selectedIDs.insert($0) }
        let selectedNum: Int
        switch locationViewMode {
        case .conversation:
            selectedNum = selectedConversations.filter { $0.contains(of: .scheduled) }.count
        case .singleMessage:
            selectedNum = selectedMessages.filter { $0.contains(location: .scheduled) }.count
        }
        if selectedNum == 0 {
            continueAction()
        } else {
            displayAlert(selectedNum)
        }
    }

    func fetchSenderImageIfNeeded(
        item: MailboxItem,
        isDarkMode: Bool,
        scale: CGFloat,
        completion: @escaping (UIImage?) -> Void
    ) {
        let senderImageRequestInfo: SenderImageRequestInfo?
        switch item {
        case .message(let messageEntity):
            senderImageRequestInfo = messageEntity.getSenderImageRequestInfo(isDarkMode: isDarkMode)
        case .conversation(let conversationEntity):
            senderImageRequestInfo = conversationEntity.getSenderImageRequestInfo(isDarkMode: isDarkMode)
        }

        guard let info = senderImageRequestInfo else {
            completion(nil)
            return
        }

        dependencies.fetchSenderImage
            .callbackOn(.main)
            .execute(
                params: .init(
                    senderImageRequestInfo: info,
                    scale: scale,
                    userID: user.userID
                )) { result in
                    switch result {
                    case .success(let image):
                        completion(image)
                    case .failure:
                        completion(nil)
                    }
            }
    }

    func isProtonUnreachable(completion: @escaping (Bool) -> Void) {
        guard
            dependencies.featureFlagCache.isFeatureFlag(.protonUnreachableBanner, enabledForUserWithID: user.userID)
        else {
            completion(false)
            return
        }
        Task { [weak self] in
            let status = await self?.dependencies.checkProtonServerStatus.execute()
            await MainActor.run {
                completion(status == .serverDown)
            }
        }
    }

    func deleteExpiredMessages() {
        DispatchQueue.global().async {
            self.user.cacheService.deleteExpiredMessages()
        }
    }
}

// MARK: - Data fetching methods
extension MailboxViewModel {

    func fetchMessages(time: Int, forceClean: Bool, isUnread: Bool, completion: @escaping (Error?) -> Void) {
        switch self.locationViewMode {
        case .singleMessage:
            dependencies.fetchMessages
                .callbackOn(.main)
                .execute(
                    params: .init(
                        labelID: labelID,
                        endTime: time,
                        isUnread: isUnread,
                        onMessagesRequestSuccess: nil
                    ),
                    callback: { result in
                        completion(result.error)
                    }
                )
        case .conversation:
            conversationProvider.fetchConversations(for: self.labelID, before: time, unreadOnly: isUnread, shouldReset: forceClean) { result in
                switch result {
                case .success:
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
            }
        }
    }

    func updateMailbox(
        showUnreadOnly: Bool,
        isCleanFetch: Bool,
        time: Int = 0,
        errorHandler: @escaping (Error) -> Void,
        completion: @escaping () -> Void
    ) {
        guard diffableDataSource?.reloadSnapshotHasBeenCalled == true else { return }
        let isCurrentLocationEmpty = diffableDataSource?.snapshot().numberOfItems == 0
        let fetchMessagesAtTheEnd = isCurrentLocationEmpty || isFirstFetch
        isFirstFetch = false
        var queryLabel = labelID
        switch user.mailSettings.showMoved {
        case .doNotKeep:
            break
        case .keepDraft:
            if queryLabel == LabelLocation.draft.labelID {
                queryLabel = LabelLocation.hiddenDraft.labelID
            }
        case .keepSent:
            if queryLabel == LabelLocation.sent.labelID {
                queryLabel = LabelLocation.hiddenSent.labelID
            }
        case .keepBoth:
            if queryLabel == LabelLocation.draft.labelID {
                queryLabel = LabelLocation.hiddenDraft.labelID
            } else if queryLabel == LabelLocation.sent.labelID {
                queryLabel = LabelLocation.hiddenSent.labelID
            }
        }

        dependencies.updateMailbox.execute(
            params: .init(
                labelID: queryLabel,
                showUnreadOnly: showUnreadOnly,
                isCleanFetch: isCleanFetch,
                time: time,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: errorHandler
            )
        ) { _ in
            completion()
        }
    }

    func fetchMessageDetail(message: MessageEntity, callback: @escaping FetchMessageDetailUseCase.Callback) {
        let params: FetchMessageDetail.Params = .init(
            message: message,
            hasToBeQueued: false,
            ignoreDownloaded: message.isDraft
        )
        dependencies.fetchMessageDetail
            .callbackOn(.main)
            .execute(params: params, callback: callback)
    }
}

// MARK: Message Actions
extension MailboxViewModel {
    func containsStarMessages(messageIDs: Set<String>) -> Bool {
        switch self.locationViewMode {
        case .conversation:
            return coreDataContextProvider.read { context in
                let conversations = self.conversationProvider.fetchLocalConversations(withIDs: NSMutableSet(set: messageIDs), in: context)
                return conversations.contains { $0.contains(of: Message.Location.starred.labelID.rawValue) }
            }
        case .singleMessage:
            return coreDataContextProvider.read { context in
                let messages = self.messageService.fetchMessages(withIDs: NSMutableSet(set: messageIDs), in: context)
                return messages.contains { $0.contains(label: .starred) }
            }
        }
    }

    func selectionContainsReadItems() -> Bool {
        selectedItems.contains { !$0.isUnread(labelID: labelID) }
    }

    func label(IDs messageIDs: Set<String>,
               with labelID: LabelID,
               apply: Bool,
               completion: (() -> Void)? = nil) {
        switch self.locationViewMode {
        case .singleMessage:
            let messages = selectedMessages.filter { messageIDs.contains($0.messageID.rawValue) }
            messageService.label(messages: messages, label: labelID, apply: apply)
        case .conversation:
            if apply {
                conversationProvider.label(conversationIDs: Array(messageIDs.map{ ConversationID($0) }), as: labelID) { [weak self] result in
                    defer {
                        completion?()
                    }
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            } else {
                conversationProvider.unlabel(conversationIDs: Array(messageIDs.map{ ConversationID($0) }), as: labelID) { [weak self] result in
                    defer {
                        completion?()
                    }
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            }
        }
    }

    func mark(
        IDs messageIDs: Set<String>,
        unread: Bool,
        completion: (() -> Void)? = nil
    ) {
        switch self.locationViewMode {
        case .singleMessage:
            let filteredMessageIDs = selectedMessages.filter { messageIDs.contains($0.messageID.rawValue) && $0.unRead != unread
            }.map(\.objectID.rawValue)
            messageService.mark(
                messageObjectIDs: filteredMessageIDs,
                labelID: labelID,
                unRead: unread
            )
            completion?()
        case .conversation:
            let filteredConversationIDs = selectedConversations.filter {
                messageIDs.contains($0.conversationID.rawValue) && $0.isUnread(labelID: labelID) != unread
            }.map(\.conversationID)
            if unread {
                conversationProvider.markAsUnread(
                    conversationIDs: filteredConversationIDs,
                    labelID: labelID
                ) { _ in
                    completion?()
                }
            } else {
                conversationProvider.markAsRead(
                    conversationIDs: filteredConversationIDs,
                    labelID: labelId
                ) { _ in
                    completion?()
                }
            }
        }
    }

    func moveSelectedIDs(from fLabel: LabelID, to tLabel: LabelID) {
        move(items: selectedItems, from: fLabel, to: tLabel)
    }

    func move(items: [MailboxItem], from fLabel: LabelID, to tLabel: LabelID) {
        move(items: MailboxItemGroup(mailboxItems: items), from: fLabel, to: tLabel)
    }

    private func move(items: MailboxItemGroup, from fLabel: LabelID, to tLabel: LabelID) {
        switch items {
        case .messages(let messages):
            var fLabels: [LabelID] = []

            for msg in messages {
                // the label that is not draft, sent, starred, allmail
                fLabels.append(msg.getFirstValidFolder() ?? fLabel)
            }

            messageService.move(messages: messages, from: fLabels, to: tLabel)
        case .conversations(let conversations):
            conversationProvider.move(
                conversationIDs: conversations.map(\.conversationID),
                from: fLabel,
                to: tLabel,
                callOrigin: "MailboxViewModel - move"
            ) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
        case .empty:
            break
        }
    }
}

// Message Selection
extension MailboxViewModel {

    func canSelectMore() -> Bool {
        if UserInfo.enableSelectAll {
            let maximum = dependencies.featureFlagCache.featureFlags(for: user.userID)[.mailboxSelectionLimitation]
            return selectedIDs.count < maximum
        } else {
            return true
        }
    }

    /// - Returns: Does id allow to be added?
    func select(id: String) -> Bool {
        if UserInfo.enableSelectAll {
            let maximum = dependencies.featureFlagCache.featureFlags(for: user.userID)[.mailboxSelectionLimitation]
            guard selectedIDs.count < maximum else {
                uiDelegate?.selectionDidChange()
                return false
            }
            self.selectedIDs.insert(id)
            uiDelegate?.selectionDidChange()
            return true
        } else {
            selectedIDs.insert(id)
            return true
        }
    }

    func removeSelected(id: String) {
        self.selectedIDs.remove(id)
        uiDelegate?.selectionDidChange()
    }

    func removeAllSelectedIDs() {
        self.selectedIDs.removeAll()
        uiDelegate?.selectionDidChange()
    }

    func selectionContains(id: String) -> Bool {
        return self.selectedIDs.contains(id)
    }

    func removeDeletedIDFromSelectedItem(existingIDs: Set<String>) {
        let intersection = selectedIDs.intersection(existingIDs)
        selectedIDs = intersection
    }
}

// MARK: - Swipe actions
extension MailboxViewModel {
    func isSwipeActionValid(_ action: MessageSwipeAction, item: MailboxItem) -> Bool {
        guard let location = messageLocation else {
            return true
        }

        let helper = MailBoxSwipeActionHelper()

        let result: Bool
        if location == .allmail {
            switch item {
            case .message(let message):
                result = helper.checkIsSwipeActionValidOnMessage(
                    isDraft: message.isDraft,
                    isUnread: message.unRead,
                    isStar: message.contains(location: .starred),
                    isInTrash: message.contains(location: .trash),
                    isInArchive: message.contains(location: .archive),
                    isInSent: message.contains(location: .sent),
                    isInSpam: message.contains(location: .spam),
                    action: action
                )
            case .conversation(let conversation):
                result = helper.checkIsSwipeActionValidOnConversation(
                    isUnread: conversation.isUnread(labelID: labelID),
                    isStar: conversation.starred,
                    isInArchive: conversation.contains(of: Message.Location.archive.labelID),
                    isInSpam: conversation.contains(of: Message.Location.spam.labelID),
                    isInSent: conversation.contains(of: Message.Location.sent.labelID),
                    action: action
                )
            }
        } else {
            result = helper.checkIsSwipeActionValidOn(location: location, action: action)
        }
        return result
    }

    func convertSwipeActionTypeToMessageSwipeAction(_ type: SwipeActionSettingType,
                                                    isStarred: Bool,
                                                    isUnread: Bool) -> MessageSwipeAction {
        switch type {
        case .none:
            return .none
        case .trash:
            return .trash
        case .spam:
            return .spam
        case .starAndUnstar:
            return isStarred ? .unstar : .star
        case .archive:
            return .archive
        case .readAndUnread:
            return isUnread ? .read : .unread
        case .labelAs:
            return .labelAs
        case .moveTo:
            return .moveTo
        }
    }

    func handleSwipeAction(_ action: MessageSwipeAction, on item: MailboxItem) {
        switch action {
        case .unstar:
            handleUnstarAction(on: [item])
        case .star:
            handleStarAction(on: [item])
        case .read:
            handleMarkReadAction(on: [item])
        case .unread:
            handleMarkUnreadAction(on: [item])
        case .trash:
            handleRemoveAction(on: [item])
        case .archive:
            handleMoveToArchiveAction(on: [item])
        case .spam:
            handleMoveToSpamAction(on: [item])
        case .labelAs, .moveTo, .none:
            break
        }
    }

    func swipyCellDidSwipe(triggerActivated: Bool) {
        /*
         This method is called continuously during a swipe.
         If the trigger has been activated, the `triggerActivated` value is `true` on every  subsequent call, so it's
         impossible to intercept the exact moment of activation without storing this value to a property and checking
         against `oldValue`.
         */
        swipingTriggerActivated = triggerActivated
    }
}

extension MailboxViewModel: ConversationStateServiceDelegate {
    func viewModeHasChanged(viewMode: ViewMode) {
        viewModeIsChanged?()
    }
}

// MARK: - Auto-Delete Spam & Trash Banners

extension MailboxViewModel {
    enum InfoBannerType {
        case spam
        case trash
    }

    enum BannerToDisplay {
        case upsellBanner
        case promptBanner
        case infoBanner(InfoBannerType)
    }

    var headerBanner: BannerToDisplay? {
        let infoBannerType: InfoBannerType
        if self.labelID == LabelLocation.spam.labelID {
            infoBannerType = .spam
        } else if self.labelID == LabelLocation.trash.labelID {
            infoBannerType = .trash
        } else {
            return nil
        }

        if !user.hasPaidMailPlan {
            return .upsellBanner
        } else if user.isAutoDeleteImplicitlyDisabled {
            return .promptBanner
        } else if user.isAutoDeleteEnabled {
            return .infoBanner(infoBannerType)
        } else {
            return nil
        }
    }

    func updateAutoDeleteSetting(to newStatus: Bool, for user: UserManager, completion: @escaping ((Error?) -> Void)) {
        let request = UpdateAutoDeleteSpamAndTrashDaysRequest(shouldEnable: newStatus)
        user.apiService.perform(
            request: request,
            response: VoidResponse()
        ) { _, response in
            DispatchQueue.main.async {
                if let error = response.error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
    }

    func alertToConfirmEnabling(completion: @escaping ((Error?) -> Void)) -> UIAlertController {
        let alert = L11n.AutoDeleteSettings.enableAlertMessage.alertController()
        alert.title = L11n.AutoDeleteSettings.enableAlertTitle
        let cancelTitle = LocalString._general_cancel_button
        let confirm = UIAlertAction(title: L11n.AutoDeleteSettings.enableAlertButton, style: .default) { [weak self] _ in
            guard let self else { return }
            self.updateAutoDeleteSetting(to: true, for: self.user, completion: { error in
                completion(error)
            })
        }
        let cancel = UIAlertAction(title: cancelTitle, style: .cancel) { _ in }
        [confirm, cancel].forEach(alert.addAction)
        return alert
    }
}

// MARK: - Prefetch
extension MailboxViewModel {
    func itemsToPrefetch() -> [MailboxItem] {
        switch self.locationViewMode {
        case .conversation:
            let allConversations: [ConversationEntity] = diffableDataSource?.snapshot()
                .itemIdentifiers
                .compactMap { row in
                    if case .real(let item) = row,
                       case .conversation(let conversation) = item {
                        return conversation
                    } else {
                        return nil
                    }
                } ?? []
            let unreadConversations = allConversations.filter { $0.isUnread(labelID: labelID) == true }
            let readConversations = allConversations.filter { $0.isUnread(labelID: labelID) == false }
            let orderedConversations = unreadConversations.appending(readConversations)
            return orderedConversations.map { MailboxItem.conversation($0) }
        case .singleMessage:
            let allMessages: [MessageEntity] = diffableDataSource?.snapshot()
                .itemIdentifiers
                .compactMap { row in
                    if case .real(let item) = row,
                       case .message(let message) = item {
                        return message
                    } else {
                        return nil
                    }
                } ?? []
            let unreadMessages = allMessages.filter { $0.unRead == true }
            let readMessages = allMessages.filter { $0.unRead == false }
            let orderedMessages = unreadMessages.appending(readMessages)
            return orderedMessages.map { MailboxItem.message($0) }
        }
    }

    func prefetchIfNeeded() {
        guard isPrefetching.value == false else {
            return
        }

        let prefetchSize = userCachedStatus.featureFlags(for: user.userID)[.mailboxPrefetchSize]
        let itemsToPrefetch = itemsToPrefetch().prefix(prefetchSize)

        guard itemsToPrefetch.count > 0, prefetchedItemsCount.value < prefetchSize else {
            return
        }

        isPrefetching.mutate { $0 = true }

        for item in itemsToPrefetch {
            switch item {
            case .message(let messageEntity):
                if messageEntity.body.isEmpty || !messageEntity.isDetailDownloaded {
                    self.fetchMessageDetail(message: messageEntity) { [weak self] _ in
                        self?.prefetchedItemsCount.mutate { $0 += 1 }
                        if itemsToPrefetch.last == item {
                            self?.isPrefetching.mutate { $0 = false }
                        }
                    }
                }
            case .conversation(let conversationEntity):
                self.fetchConversationDetail(conversationID: conversationEntity.conversationID) { [weak self] in
                    self?.prefetchedItemsCount.mutate { $0 += 1 }
                    if itemsToPrefetch.last == item {
                        self?.isPrefetching.mutate { $0 = false }
                    }
                }
            }
        }
    }
}

// MARK: - Attachment Preview
extension MailboxViewModel {
    func previewableAttachments(for mailboxItem: MailboxItem) -> [AttachmentsMetadata] {
        let isSpam = switch mailboxItem {
            case .message(let message):
                message.isSpam
            case .conversation(let conversation):
                conversation.contextLabelRelations.contains(where: { $0.labelID == Message.Location.spam.labelID })
        }
        guard dependencies.featureFlagCache.isFeatureFlag(.attachmentsPreview, enabledForUserWithID: user.userID),
              !isSpam else {
            return []
        }
        return mailboxItem.previewableAttachments
    }

    func requestPreviewOfAttachment(
        at indexPath: IndexPath,
        index: Int,
        completion: @escaping ((Result<SecureTemporaryFile, Error>) -> Void)
    ) {
        guard let mailboxItem = mailboxItem(at: indexPath),
              let attachmentMetadata = mailboxItem.attachmentsMetadata[safe: index] else {
            PMAssertionFailure("IndexPath should match MailboxItem")
            completion(.failure(AttachmentPreviewError.indexPathDidNotMatch))
            return
        }

        let attId = AttachmentID(attachmentMetadata.id)
        let userKeys = user.toUserKeys()

        Task  {
            do {
                let metadata = try await dependencies.fetchAttachmentMetadata.execution(
                    params: .init(attachmentID: attId)
                )
                self.dependencies.fetchAttachment
                    .execute(params: .init(
                        attachmentID: attId,
                        attachmentKeyPacket:  metadata.keyPacket,
                        userKeys: userKeys
                    )) { result in
                    switch result {
                    case .success(let attFile):
                        do {
                            let fileData = attFile.data
                            let fileName = attachmentMetadata.name.cleaningFilename()
                            let secureTempFile = SecureTemporaryFile(data: fileData, name: fileName)
                            completion(.success(secureTempFile))
                        } catch {
                            completion(.failure(error))
                        }
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
                SystemLogger.log(error: error)
            }
        }
    }

    private func isSpecialLoopEnabledInNewEventLoop() -> Bool {
        dependencies.mailEventsPeriodicScheduler.currentlyEnabled().specialLoopIDs.contains(user.userID.rawValue)
    }

    func fetchEventsWithNewEventLoop() {
        dependencies.mailEventsPeriodicScheduler.triggerSpecialLoop(forSpecialLoopID: user.userID.rawValue)
    }

    func stopNewEventLoop() {
        dependencies.mailEventsPeriodicScheduler.didStopSpecialLoop(withSpecialLoopID: user.userID.rawValue)
    }

    func startNewEventLoop() {
        guard !isSpecialLoopEnabledInNewEventLoop() else {
            fetchEventsWithNewEventLoop()
            return
        }
        dependencies.mailEventsPeriodicScheduler.enableSpecialLoop(forSpecialLoopID: user.userID.rawValue)
    }
}

// MARK: - Misc

extension String {
    static func actionSheetTitle(selectedCount: Int, viewMode: ViewMode) -> String {
        switch viewMode {
        case .singleMessage:
            return .localizedStringWithFormat(LocalString._general_message, selectedCount)
        case .conversation:
            return .localizedStringWithFormat(LocalString._general_conversation, selectedCount)
        }
    }
}
