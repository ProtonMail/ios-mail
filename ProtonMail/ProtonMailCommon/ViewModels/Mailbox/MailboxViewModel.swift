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
import ProtonCore_DataModel
import ProtonCore_Services
import ProtonMailAnalytics

struct LabelInfo {
    let labelID: LabelID
    let name: String
    
    init(label: LabelEntity) {
        labelID = label.labelID
        name = label.name
    }
    
    init(labelID: LabelID, name: String) {
        self.labelID = labelID
        self.name = name
    }
}

class MailboxViewModel: StorageLimit {
    let labelID: LabelID
    let labelType: PMLabelType
    /// This field saves the label object of custom folder/label
    let label: LabelInfo?
    var messageLocation: Message.Location? {
        return Message.Location(rawValue: labelID.rawValue)
    }
    /// message service
    internal let user: UserManager
    internal let messageService: MessageDataService
    internal let eventsService: EventsFetching
    private let pushService: PushNotificationServiceProtocol
    /// fetch controller
    private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    private(set) var labelFetchedResults: NSFetchedResultsController<Label>?
    private(set) var unreadFetchedResult: NSFetchedResultsController<NSFetchRequestResult>?

    private(set) var selectedIDs: Set<String> = Set()

    var selectedMoveToFolder: MenuLabel?
    var selectedLabelAsLabels: Set<LabelLocation> = Set()

    private let lastUpdatedStore: LastUpdatedStoreProtocol
    private let humanCheckStatusProvider: HumanCheckStatusProviderProtocol
    let coreDataContextProvider: CoreDataContextProviderProtocol
    private let conversationStateProvider: ConversationStateProviderProtocol
    private let contactGroupProvider: ContactGroupsProviderProtocol
    let labelProvider: LabelProviderProtocol
    private let contactProvider: ContactProviderProtocol
    let conversationProvider: ConversationProvider
    private let welcomeCarrouselCache: WelcomeCarrouselCacheProtocol

    var viewModeIsChanged: (() -> Void)?
    var sendHapticFeedback:(() -> Void)?
    let totalUserCountClosure: () -> Int
    var isHavingUser: Bool {
        return totalUserCountClosure() > 0
    }

    private let dependencies: Dependencies

    /// `swipyCellDidSwipe` will be setting this value repeatedly during a swipe gesture.
    /// We only want to send a haptic signal one a state change.
    private var swipingTriggerActivated = false {
        didSet {
            if swipingTriggerActivated != oldValue, swipingTriggerActivated {
                sendHapticFeedback?()
            }
        }
    }
    init(labelID: LabelID,
         label: LabelInfo?,
         labelType: PMLabelType,
         userManager: UserManager,
         pushService: PushNotificationServiceProtocol,
         coreDataContextProvider: CoreDataContextProviderProtocol,
         lastUpdatedStore: LastUpdatedStoreProtocol,
         humanCheckStatusProvider: HumanCheckStatusProviderProtocol,
         conversationStateProvider: ConversationStateProviderProtocol,
         contactGroupProvider: ContactGroupsProviderProtocol,
         labelProvider: LabelProviderProtocol,
         contactProvider: ContactProviderProtocol,
         conversationProvider: ConversationProvider,
         eventsService: EventsFetching,
         dependencies: Dependencies,
         welcomeCarrouselCache: WelcomeCarrouselCacheProtocol = userCachedStatus,
         totalUserCountClosure: @escaping () -> Int
    ) {
        self.labelID = labelID
        self.label = label
        self.labelType = labelType
        self.user = userManager
        self.messageService = userManager.messageService
        self.eventsService = eventsService
        self.coreDataContextProvider = coreDataContextProvider
        self.pushService = pushService
        self.lastUpdatedStore = lastUpdatedStore
        self.humanCheckStatusProvider = humanCheckStatusProvider
        self.conversationStateProvider = conversationStateProvider
        self.contactGroupProvider = contactGroupProvider
        self.contactProvider = contactProvider
        self.totalUserCountClosure = totalUserCountClosure
        self.labelProvider = labelProvider
        self.conversationProvider = conversationProvider
        self.dependencies = dependencies
        self.welcomeCarrouselCache = welcomeCarrouselCache
        self.conversationStateProvider.add(delegate: self)
    }

    /// localized navigation title. overrride it or return label name
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
        let singleMessageOnlyLabels: [Message.Location] = [.draft, .sent]
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

    var isRequiredHumanCheck: Bool {
        get { return self.humanCheckStatusProvider.isRequiredHumanCheck }
        set { self.humanCheckStatusProvider.isRequiredHumanCheck = newValue }
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
        return .init(labelId: labelId.rawValue,
                     title: .actionSheetTitle(selectedCount: selectedIDs.count, viewMode: locationViewMode))
    }

    // Needs refactor to test

    var isInDraftFolder: Bool {
        return labelID.rawValue == Message.Location.draft.rawValue
    }

    var countOfFetchedObjects: Int {
        return fetchedResultsController?.fetchedObjects?.count ?? 0
    }

    var selectedMessages: [MessageEntity] {
        fetchedResultsController?.fetchedObjects?
            .compactMap { $0 as? Message }
            .filter { selectedIDs.contains($0.messageID) }
            .map(MessageEntity.init) ?? []
    }
    
    var selectedConversations: [ConversationEntity] {
        fetchedResultsController?.fetchedObjects?
            .compactMap { $0 as? ContextLabel }
            .filter { selectedIDs.contains($0.conversation.conversationID) }
            .map(\.conversation)
            .map(ConversationEntity.init) ?? []
    }

    // Fetched by each cell in the view, use lazy to avoid fetching too much times
    lazy var customFolders: [LabelEntity] = {
        return labelProvider.getCustomFolders().map(LabelEntity.init)
    }()

    var allEmails: [Email] {
        return contactProvider.getAllEmails()
    }

    func contactGroups() -> [ContactGroupVO] {
        contactGroupProvider.getAllContactGroupVOs()
    }

    func fetchContacts(completion: ContactFetchComplete? = nil) {
        contactProvider.fetchContacts(fromUI: true, completion: completion)
    }

    /// create a fetch controller with labelID
    ///
    /// - Returns: fetched result controller
    private func makeFetchController(isUnread: Bool) -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchedResultsController = messageService.fetchedResults(by: self.labelID, viewMode: self.locationViewMode, isUnread: isUnread)
        do {
            try fetchedResultsController.performFetch()
        } catch {
        }
        return fetchedResultsController
    }

    private func makeLabelFetchController() -> NSFetchedResultsController<Label> {
       let controller = self.user.labelService.fetchedResultsController(.all)

        do {
            try controller.performFetch()
        } catch {
        }

        return controller
    }

    private func makeUnreadFetchController() -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchController: NSFetchedResultsController<NSFetchRequestResult>

        switch locationViewMode {
        case .singleMessage:
            let moc = coreDataContextProvider.mainContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: LabelUpdate.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == %@) AND (%K == %@)",
                                                 LabelUpdate.Attributes.labelID,
                                                 self.labelID.rawValue,
                                                 LabelUpdate.Attributes.userID,
                                                 self.user.userinfo.userId)
            let strComp = NSSortDescriptor(key: LabelUpdate.Attributes.labelID,
                                           ascending: true,
                                           selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            fetchRequest.sortDescriptors = [strComp]
            fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        case .conversation:
            let moc = coreDataContextProvider.mainContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ConversationCount.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == %@) AND (%K == %@)",
                                                 ConversationCount.Attributes.userID,
                                                 self.user.userinfo.userId,
                                                 ConversationCount.Attributes.labelID,
                                                 self.labelID.rawValue)
            let strComp = NSSortDescriptor(key: ConversationCount.Attributes.labelID,
                                           ascending: true,
                                           selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            fetchRequest.sortDescriptors = [strComp]
            fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        }

        do {
            try fetchController.performFetch()
        } catch {
        }

        return fetchController
    }

    /// Setup fetch controller to fetch message of specific labelID
    ///
    /// - Parameter delegate: delegate from viewcontroller
    /// - Parameter isUnread: the flag used to filter the unread message or not
    func setupFetchController(_ delegate: NSFetchedResultsControllerDelegate?, isUnread: Bool = false) {
        self.fetchedResultsController = self.makeFetchController(isUnread: isUnread)
        self.fetchedResultsController?.delegate = delegate

        self.labelFetchedResults = self.makeLabelFetchController()
        self.labelFetchedResults?.delegate = delegate

        self.unreadFetchedResult = self.makeUnreadFetchController()
        self.unreadFetchedResult?.delegate = delegate
    }

    /// reset delegate if fetch controller is valid
    func resetFetchedController() {
        if let controller = self.fetchedResultsController {
            controller.delegate = nil
            self.fetchedResultsController = nil
        }

        if let controller = self.labelFetchedResults {
            controller.delegate = nil
            self.fetchedResultsController = nil
        }
    }

    // MARK: - table view usesage

    /// get section cound
    ///
    /// - Returns: 
    func sectionCount() -> Int {
        return fetchedResultsController?.numberOfSections() ?? 0
    }

    /// get row count of a section
    ///
    /// - Parameter section: section index
    /// - Returns: row count
    func rowCount(section: Int) -> Int {
        return fetchedResultsController?.numberOfRows(in: section) ?? 0
    }

    /// get message item from a indexpath
    ///
    /// - Parameter index: table cell indexpath
    /// - Returns: message (nil)
    func item(index: IndexPath) -> MessageEntity? {
        guard !index.isEmpty, let sections = self.fetchedResultsController?.numberOfSections() else {
            return nil
        }
        guard sections > index.section else {
            return nil
        }

        guard let rows = self.fetchedResultsController?.numberOfRows(in: index.section) else {
            return nil
        }

        guard rows > index.row else {
            return nil
        }

        guard let msg = fetchedResultsController?.object(at: index) as? Message else {
            return nil
        }
        
        return MessageEntity(msg)
    }
    
    func itemOfConversation(index: IndexPath) -> ConversationEntity? {
        guard let conversation = itemOfRawConversation(indexPath: index) else {
            return nil
        }
        return ConversationEntity(conversation)
    }

    private func itemOfRawConversation(indexPath: IndexPath) -> Conversation? {
        guard !indexPath.isEmpty, let sections = self.fetchedResultsController?.numberOfSections() else {
            return nil
        }
        guard sections > indexPath.section else {
            return nil
        }
        guard let rows = self.fetchedResultsController?.numberOfRows(in: indexPath.section) else {
            return nil
        }
        guard rows > indexPath.row else {
            return nil
        }
        let contextLabel = fetchedResultsController?.object(at: indexPath) as? ContextLabel
        guard let conversation = contextLabel?.conversation else {
            return nil
        }
        return conversation
    }

    func isObjectUpdated(objectID: ObjectID) -> Bool {
        guard let obj = try? self.fetchedResultsController?.managedObjectContext.existingObject(with: objectID.rawValue) else {
            return false
        }
        return obj.isUpdated
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
        guard let number = self.fetchedResultsController?.numberOfSections() else {
            return false
        }
        guard number > index.section else {
            return false
        }
        guard let total = self.fetchedResultsController?.numberOfRows(in: index.section) else {
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
        lastUpdatedStore.lastUpdate(by: labelID.rawValue, userID: user.userID.rawValue, type: locationViewMode)
    }

    func getLastUpdateTimeText() -> String {
        var result = LocalString._mailblox_last_update_time_more_than_1_hour

        if let updateTime = lastUpdatedStore.lastEventUpdateTime(userID: self.user.userID.rawValue) {
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
        self.fetchMessages(time: 0, forceClean: false, isUnread: false) { _, _, _ in
            group.leave()
        }

        group.notify(queue: DispatchQueue.main) {
            delay(0.2) {
                // For operation context sync with main context
                let count = self.user.labelService.lastUpdate(by: self.labelID, userID: self.user.userinfo.userId)
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

    func object(by object: NSManagedObjectID) -> Message? {
        if let obj = self.fetchedResultsController?.managedObjectContext.object(with: object) as? Message {
            return obj
        }
        return nil
    }

    func fetchConversationDetail(conversationID: ConversationID, completion: ((Result<Conversation, Error>) -> Void)?) {
        conversationProvider.fetchConversation(with: conversationID, includeBodyOf: nil, callOrigin: "MailboxViewModel", completion: completion)
    }

    func markConversationAsUnread(conversationIDs: [ConversationID], currentLabelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        conversationProvider.markAsUnread(conversationIDs: conversationIDs,
                                         labelID: currentLabelID,
                                         completion: completion)
    }
    
    func markConversationAsRead(conversationIDs: [ConversationID], currentLabelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        conversationProvider.markAsRead(conversationIDs: conversationIDs,
                                       labelID: currentLabelID,
                                       completion: completion)
    }

    func fetchConversationCount(completion: ((Result<Void, Error>) -> Void)?) {
        conversationProvider.fetchConversationCounts(addressID: nil, completion: completion)
    }
    
    func labelConversations(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        conversationProvider.label(conversationIDs: conversationIDs,
                                  as: labelID,
                                  isSwipeAction: false,
                                  completion: completion)
    }
    
    func unlabelConversations(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        conversationProvider.unlabel(conversationIDs: conversationIDs,
                                    as: labelID,
                                    isSwipeAction: false,
                                    completion: completion)
    }

    func isEventIDValid() -> Bool {
        return messageService.isEventIDValid(context: coreDataContextProvider.mainContext)
    }

    /// get the cached notification message id
    var notificationMessageID: String? {
        messageService.pushNotificationMessageID
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
    
    func mark(messages: [MessageEntity], unread: Bool = true) {
        messageService.mark(messages: messages, labelID: self.labelID, unRead: unread)
    }
    
    func label(msg message: MessageEntity, with labelID: LabelID, apply: Bool = true) {
        messageService.label(messages: [message], label: labelID, apply: apply, shouldFetchEvent: false)
    }
    
    func delete(IDs: Set<String>, completion: (() -> Void)? = nil) {
        switch locationViewMode {
        case .conversation:
            deletePermanently(conversationIDs: Array(IDs.map{ ConversationID($0) }), completion: completion)
        case .singleMessage:
            let messages = self.messageService.fetchMessages(withIDs: NSMutableSet(set: IDs), in: coreDataContextProvider.mainContext)
            self.deletePermanently(messages: messages)
        }
    }

    private func deletePermanently(messages: [Message]) {
        messageService.delete(messages: messages.map(MessageEntity.init), label: self.labelID)
    }

    private func deletePermanently(conversationIDs: [ConversationID], completion: (() -> Void)? = nil) {
        conversationProvider.deleteConversations(with: conversationIDs, labelID: self.labelID) { [weak self] result in
            defer {
                completion?()
            }
            guard let self = self else { return }
            if let _ = try? result.get() {
                self.eventsService.fetchEvents(labelID: self.labelId)
            }
        }
    }

    func checkStorageIsCloseLimit() {
        let usedStorageSpace = user.userInfo.usedSpace
        let maxStorageSpace = user.userInfo.maxSpace
        checkSpace(usedStorageSpace,
                   maxSpace: maxStorageSpace,
                   userID: user.userinfo.userId)
    }

    func handleActionSheetAction(_ action: MailListSheetAction) {
        switch action {
        case .unstar:
            handleUnstarAction()
        case .star:
            handleStarAction()
        case .markRead:
            handleMarkReadAction()
        case .markUnread:
            handleMarkUnreadAction()
        case .remove:
            handleRemoveAction()
        case .moveToArchive:
            handleMoveToArchiveAction()
        case .moveToSpam:
            handleMoveToSpamAction()
        case .dismiss, .delete:
            break
        case .labelAs:
            // TODO: add action
            break
        case .moveTo:
            // TODO: add action
            break
        case .moveToInbox:
            handleMoveToInboxAction()
            break
        }
    }

    func getTimeOfItem(at indexPath: IndexPath) -> Date? {
        switch locationViewMode {
        case .singleMessage:
            return item(index: indexPath)?.time
        case .conversation:
            let conversation = itemOfConversation(index: indexPath)
            if conversation == nil {
                Breadcrumbs.shared.add(message: "MailboxVM getTimeOfItem conv is nil", to: .malformedConversationRequest)
            }
            return conversation?.getTime(labelID: labelID)
        }
    }

    func purgeOldMessages() {
        self.dependencies.purgeOldMessages.execute(completion: { _ in })
    }

    func getOnboardingDestination() -> MailboxCoordinator.Destination? {
        guard let tourVersion = self.welcomeCarrouselCache.lastTourVersion else {
            return .onboardingForNew
        }
        if tourVersion == Constants.App.TourVersion {
            return nil
        } else {
            return .onboardingForUpdate
        }
    }

    private func handleMoveToInboxAction() {
        move(IDs: Set(selectedIDs),
             from: labelID,
             to: Message.Location.inbox.labelID)
    }

    private func handleMoveToArchiveAction() {
        move(IDs: Set(selectedIDs),
             from: labelID,
             to: Message.Location.archive.labelID)
    }

    private func handleMoveToSpamAction() {
        move(IDs: Set(selectedIDs),
             from: labelID,
             to: Message.Location.spam.labelID)
    }

    private func handleUnstarAction() {
        let starredItemsIds: [String]
        switch locationViewMode {
        case .conversation:
            starredItemsIds = selectedConversations
                .filter { $0.starred }
                .map(\.conversationID)
                .map(\.rawValue)
        case .singleMessage:
            starredItemsIds = selectedMessages
                .filter { $0.isStarred }
                .map(\.messageID)
                .map(\.rawValue)
        }
        label(IDs: Set<String>(starredItemsIds), with: Message.Location.starred.labelID, apply: false)
    }

    private func handleStarAction() {
        let unstarredItemsIds: [String]
        switch locationViewMode {
        case .conversation:
            unstarredItemsIds = selectedConversations
                .filter { !$0.starred }
                .map(\.conversationID)
                .map(\.rawValue)
        case .singleMessage:
            unstarredItemsIds = selectedMessages
                .filter { !$0.isStarred }
                .map(\.messageID)
                .map(\.rawValue)
        }
        label(IDs: Set<String>(unstarredItemsIds), with: Message.Location.starred.labelID, apply: true)
    }

    private func handleMarkReadAction() {
        let unreadItemsIds: [String]
        switch locationViewMode {
        case .conversation:
            unreadItemsIds = selectedConversations
                .filter { $0.isUnread(labelID: labelID) }
                .map(\.conversationID)
                .map(\.rawValue)
        case .singleMessage:
            unreadItemsIds = selectedMessages
                .filter { $0.unRead }
                .map(\.messageID)
                .map(\.rawValue)
        }
        mark(IDs: Set(unreadItemsIds), unread: false)
    }

    private func handleMarkUnreadAction() {
        let unreadItemsIds: [String]
        switch locationViewMode {
        case .conversation:
            unreadItemsIds = selectedConversations
                .filter { !$0.isUnread(labelID: labelID) }
                .map(\.conversationID)
                .map(\.rawValue)
        case .singleMessage:
            unreadItemsIds = selectedMessages
                .filter { !$0.unRead }
                .map(\.messageID)
                .map(\.rawValue)
        }
        mark(IDs: Set(unreadItemsIds), unread: true)
    }

    private func handleRemoveAction() {
        move(IDs: Set(selectedIDs),
             from: labelID,
             to: Message.Location.trash.labelID)
    }

    func makeFakeRawMessage() -> Message {
        let context = coreDataContextProvider.mainContext
        return Message(context: context)
    }

    func makeFakeRawConversation() -> Conversation {
        let context = coreDataContextProvider.mainContext
        return Conversation(context: context)
    }
}

// MARK: - Data fetching methods
extension MailboxViewModel {
    func fetchEvents(notificationMessageID:String?, completion: CompletionBlock?) {
        var id: MessageID? = nil
        if let msgID = notificationMessageID {
            id = MessageID(msgID)
        }
        eventsService.fetchEvents(byLabel: self.labelID,
                                   notificationMessageID: id,
                                   completion: completion)
    }

    func fetchMessages(time: Int, forceClean: Bool, isUnread: Bool, completion: CompletionBlock?) {
        switch self.locationViewMode {
        case .singleMessage:
            dependencies.fetchMessages.execute(
                endTime: time,
                isUnread: isUnread,
                hasToBeQueued: false,
                callback: { result in
                    completion?(nil, nil, result.nsError)
                },
                onMessagesRequestSuccess: nil)

        case .conversation:
            conversationProvider.fetchConversations(for: self.labelID, before: time, unreadOnly: isUnread, shouldReset: forceClean) { result in
                switch result {
                case .success:
                    completion?(nil, nil, nil)
                case .failure(let error):
                    completion?(nil, nil, error as NSError)
                }
            }
        }
    }

    func fetchDataWithReset(time: Int, cleanContact: Bool, unreadOnly: Bool, completion: @escaping CompletionBlock) {
        switch locationViewMode {
        case .singleMessage:
            dependencies
                .fetchMessagesWithReset
                .execute(
                    endTime: time,
                    isUnread: unreadOnly,
                    cleanContact: cleanContact,
                    removeAllDraft: false,
                    hasToBeQueued: false
                ) { result in
                    completion(nil, nil, result.nsError)
                }

        case .conversation:
            dependencies.fetchLatestEventIdUseCase.execute(callback: nil)
            conversationProvider.fetchConversations(for: self.labelID, before: time, unreadOnly: unreadOnly, shouldReset: true) { [weak self] result in
                guard let self = self else {
                    completion(nil, nil, result.nsError)
                    return
                }
                self.conversationProvider.fetchConversationCounts(addressID: nil) { _ in
                    completion(nil, nil, result.nsError)
                }
            }
        }
    }
}

// MARK: Message Actions
extension MailboxViewModel {

    func containsReadMessages(messageIDs: Set<String>, labelID: String) -> Bool {
        var readCount = 0
        switch self.locationViewMode {
        case .conversation:
            let conversations = self.conversationProvider.fetchLocalConversations(withIDs: NSMutableSet(set: messageIDs), in: coreDataContextProvider.mainContext)
            readCount = conversations.reduce(0) { (result, next) -> Int in
                if next.getNumUnread(labelID: labelID) == 0 {
                    return result + 1
                } else {
                    return result
                }
            }
        case .singleMessage:
            let messages = self.messageService.fetchMessages(withIDs: NSMutableSet(set: messageIDs), in: coreDataContextProvider.mainContext)
            readCount = messages.reduce(0) { (result, next) -> Int in
                if next.unRead == false {
                    return result + 1
                } else {
                    return result
                }
            }
        }
        return readCount > 0
    }

    func label(IDs messageIDs: Set<String>,
               with labelID: LabelID,
               apply: Bool,
               completion: (() -> Void)? = nil) {
        switch self.locationViewMode {
        case .singleMessage:
            let ids = Array(messageIDs.map{ MessageID($0) })
            let messages = self.messageService.fetchMessages(with: ids)
            messageService.label(messages: messages, label: labelID, apply: apply)
        case .conversation:
            if apply {
                conversationProvider.label(conversationIDs: Array(messageIDs.map{ ConversationID($0) }), as: labelID, isSwipeAction: false) { [weak self] result in
                    defer {
                        completion?()
                    }
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            } else {
                conversationProvider.unlabel(conversationIDs: Array(messageIDs.map{ ConversationID($0) }), as: labelID, isSwipeAction: false) { [weak self] result in
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

    func mark(IDs messageIDs: Set<String>,
              unread: Bool,
              completion: (() -> Void)? = nil) {
        switch self.locationViewMode {
        case .singleMessage:
            let ids = NSMutableSet(set: messageIDs)
            let messages = self.messageService.fetchMessages(withIDs: ids, in: coreDataContextProvider.mainContext)
            messageService.mark(messages: messages.map(MessageEntity.init), labelID: self.labelID, unRead: unread)
            completion?()
        case .conversation:
            if unread {
                conversationProvider.markAsUnread(conversationIDs: Array(messageIDs.map{ ConversationID($0) }), labelID: self.labelID) { [weak self] result in
                    defer {
                        completion?()
                    }
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            } else {
                conversationProvider.markAsRead(conversationIDs: Array(messageIDs.map{ ConversationID($0) }), labelID: self.labelId) { [weak self] result in
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

    func move(IDs messageIDs: Set<String>,
              from fLabel: LabelID,
              to tLabel: LabelID,
              completion: (() -> Void)? = nil) {
        switch self.locationViewMode {
        case .singleMessage:
            let ids = NSMutableSet(set: messageIDs)
            let messages = self.messageService.fetchMessages(withIDs: ids, in: coreDataContextProvider.mainContext)
            var fLabels: [LabelID] = []
            for msg in messages {
                // the label that is not draft, sent, starred, allmail
                fLabels.append(LabelID(msg.firstValidFolder() ?? fLabel.rawValue))
            }
            messageService.move(messages: messages.map(MessageEntity.init), from: fLabels, to: tLabel)
            completion?()
        case .conversation:
            conversationProvider.move(conversationIDs: Array(messageIDs.map{ ConversationID($0) }),
                                     from: fLabel,
                                     to: tLabel,
                                      isSwipeAction: false,
                                      callOrigin: "MailboxViewModel - move") { [weak self] result in
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

// Message Selection
extension MailboxViewModel {
    func select(id: String) {
        self.selectedIDs.insert(id)
    }

    func removeSelected(id: String) {
        self.selectedIDs.remove(id)
    }

    func removeAllSelectedIDs() {
        self.selectedIDs.removeAll()
    }

    func selectionContains(id: String) -> Bool {
        return self.selectedIDs.contains(id)
    }

}

// MARK: - Swipe actions
extension MailboxViewModel {
    func isSwipeActionValid(_ action: MessageSwipeAction, item: SwipeableItem) -> Bool {
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

    func conversationModeFeatureFlagHasChanged(isFeatureEnabled: Bool) {

    }
}

extension MailboxViewModel {

    struct Dependencies {
        let fetchMessages: FetchMessagesUseCase
        let fetchMessagesWithReset: FetchMessagesWithResetUseCase
        let fetchLatestEventIdUseCase: FetchLatestEventIdUseCase
        let purgeOldMessages: PurgeOldMessagesUseCase

        init(
            fetchMessages: FetchMessagesUseCase,
            fetchMessagesWithReset: FetchMessagesWithResetUseCase,
            fetchLatestEventIdUseCase: FetchLatestEventIdUseCase,
            purgeOldMessages: PurgeOldMessagesUseCase
        ) {
            self.fetchMessages = fetchMessages
            self.fetchMessagesWithReset = fetchMessagesWithReset
            self.fetchLatestEventIdUseCase = fetchLatestEventIdUseCase
            self.purgeOldMessages = purgeOldMessages
        }
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
