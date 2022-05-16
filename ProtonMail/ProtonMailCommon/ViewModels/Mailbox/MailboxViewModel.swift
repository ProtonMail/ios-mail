//
//  MailboxViewModel.swift
//  ProtonMail - Created on 8/15/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import CoreData
import ProtonCore_DataModel
import ProtonCore_Services
import ProtonMailAnalytics

struct LabelInfo {
    let labelID: String
    let name: String

    init(labelID: String, name: String) {
        self.labelID = labelID
        self.name = name
    }
}

class MailboxViewModel: StorageLimit {
    let labelID: String
    let labelType: PMLabelType
    /// This field saves the label object of custom folder/label
    let label: LabelInfo?
    var messageLocation: Message.Location? {
        return Message.Location(rawValue: labelID)
    }
    /// message service
    internal let user: UserManager
    internal let messageService: MessageDataService
    internal let eventsService: EventsFetching
    private let pushService: PushNotificationServiceProtocol
    /// fetch controller
    private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    private(set) var labelFetchedResults: NSFetchedResultsController<NSFetchRequestResult>?
    private(set) var unreadFetchedResult: NSFetchedResultsController<NSFetchRequestResult>?

    private(set) var selectedIDs: Set<String> = Set()

    var selectedMoveToFolder: MenuLabel?
    var selectedLabelAsLabels: Set<LabelLocation> = Set()

    private let lastUpdatedStore: LastUpdatedStoreProtocol
    private let humanCheckStatusProvider: HumanCheckStatusProviderProtocol
    private let coreDataContextProvider: CoreDataContextProviderProtocol
    private let conversationStateProvider: ConversationStateProviderProtocol
    private let contactGroupProvider: ContactGroupsProviderProtocol
    let labelProvider: LabelProviderProtocol
    private let contactProvider: ContactProviderProtocol
    let conversationProvider: ConversationProvider
    private let messageProvider: MessageProvider
    private let welcomeCarrouselCache: WelcomeCarrouselCacheProtocol

    var viewModeIsChanged: (() -> Void)?
    var sendHapticFeedback:(() -> Void)?
    let totalUserCountClosure: () -> Int
    var isHavingUser: Bool {
        return totalUserCountClosure() > 0
    }
    let getOtherUsersClosure: (String) -> [UserManager]

    /// `swipyCellDidSwipe` will be setting this value repeatedly during a swipe gesture.
    /// We only want to send a haptic signal one a state change.
    private var swipingTriggerActivated = false {
        didSet {
            if swipingTriggerActivated != oldValue {
                sendHapticFeedback?()
            }
        }
    }

    init(labelID: String,
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
         messageProvider: MessageProvider,
         eventsService: EventsFetching,
         welcomeCarrouselCache: WelcomeCarrouselCacheProtocol = userCachedStatus,
         totalUserCountClosure: @escaping () -> Int,
         getOtherUsersClosure: @escaping (String) -> [UserManager]
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
        self.getOtherUsersClosure = getOtherUsersClosure
        self.labelProvider = labelProvider
        self.messageProvider = messageProvider
        self.conversationProvider = conversationProvider
        self.welcomeCarrouselCache = welcomeCarrouselCache
        self.conversationStateProvider.add(delegate: self)
    }

    /// localized navigation title. overrride it or return label name
    var localizedNavigationTitle: String {
        guard let location = Message.Location(rawValue: labelID) else {
            return label?.name ?? ""
        }
        return location.localizedTitle
    }

    var currentViewMode: ViewMode {
        conversationStateProvider.viewMode
    }

    var locationViewMode: ViewMode {
        let singleMessageOnlyLabels: [Message.Location] = [.draft, .sent]
        if let location = Message.Location.init(rawValue: labelID),
           singleMessageOnlyLabels.contains(location),
           self.conversationStateProvider.viewMode == .conversation {
            return .singleMessage
        }
        return self.conversationStateProvider.viewMode
    }

    var isTrashOrSpam: Bool {
        let ids = [LabelLocation.trash.labelID, LabelLocation.spam.labelID]
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
        return .init(labelId: labelId,
                     title: .actionSheetTitle(selectedCount: selectedIDs.count, viewMode: locationViewMode))
    }

    // Needs refactor to test

    var isInDraftFolder: Bool {
        return labelID == Message.Location.draft.rawValue
    }

    var countOfFetchedObjects: Int {
        return fetchedResultsController?.fetchedObjects?.count ?? 0
    }

    var selectedMessages: [Message] {
        fetchedResultsController?.fetchedObjects?
            .compactMap { $0 as? Message }
            .filter { selectedIDs.contains($0.messageID) } ?? []
    }

    var selectedConversations: [Conversation] {
        fetchedResultsController?.fetchedObjects?
            .compactMap { $0 as? ContextLabel }
            .filter { selectedIDs.contains($0.conversation.conversationID) }
            .map(\.conversation) ?? []
    }

    // Fetched by each cell in the view, use lazy to avoid fetching too much times
    lazy var customFolders: [Label] = {
        return labelProvider.getCustomFolders()
    }()

    var groupContacts: [ContactGroupVO] {
        contactGroupProvider.getAllContactGroupVOs()
    }

    var allEmails: [Email] {
        return contactProvider.getAllEmails()
    }

    func fetchContacts(completion: ContactFetchComplete? = nil) {
        contactProvider.fetchContacts(completion: completion)
    }

    private var fetchingMessageForOhters: Bool = false

    func getLatestMessagesForOthers(isForceRefresh: Bool = false) {
        if fetchingMessageForOhters == false {
            fetchingMessageForOhters = true
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let usersToFetch = self.getOtherUsersClosure(self.user.userinfo.userId)
                let group = DispatchGroup()
                usersToFetch.forEach { user in
                    let completion: CompletionBlock = { (task, res, error) -> Void in
                        defer {
                            group.leave()
                        }
                        guard error == nil else {
                            return
                        }
                        user.messageService.updateMessageCount(completion: nil)
                    }

                    group.enter()
                    if isForceRefresh {
                        user.messageService.fetchMessagesWithReset(byLabel: self.labelID,
                                                                   time: 0,
                                                                   cleanContact: false,
                                                                   completion: completion)
                    } else if let updateTime = self.lastUpdatedStore.lastUpdate(by: self.labelID,
                                                                                userID: user.userInfo.userId,
                                                                                context: self.coreDataContextProvider.mainContext,
                                                                                type: .singleMessage),
                              updateTime.isNew == false,
                              user.messageService.isEventIDValid(context: self.coreDataContextProvider.mainContext) {
                        user.eventsService.fetchEvents(byLabel: self.labelID,
                                                       notificationMessageID: nil,
                                                       completion: completion)
                    } else {// this new
                        if !user.messageService.isEventIDValid(context: self.coreDataContextProvider.rootSavingContext) { // if event id is not valid reset
                            user.messageService.fetchMessagesWithReset(byLabel: self.labelID,
                                                                       time: 0,
                                                                       completion: completion)
                        } else {
                            user.messageService.fetchMessages(byLabel: self.labelID,
                                                              time: 0,
                                                              forceClean: false,
                                                              isUnread: false,
                                                              completion: completion)
                        }
                    }
                }

                group.notify(queue: .main) { [weak self] in
                    self?.fetchingMessageForOhters = false
                }
            }
        }
    }

    func forceRefreshMessagesForOthers() {
        getLatestMessagesForOthers(isForceRefresh: true)
    }

    /// create a fetch controller with labelID
    ///
    /// - Returns: fetched result controller
    private func makeFetchController(isUnread: Bool) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let fetchedResultsController = messageService.fetchedResults(by: self.labelID, viewMode: self.locationViewMode, isUnread: isUnread)
        if let fetchedResultsController = fetchedResultsController {
            do {
                try fetchedResultsController.performFetch()
            } catch {
            }
        }
        return fetchedResultsController
    }

    private func makeLabelFetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        guard let controller = self.user.labelService.fetchedResultsController(.all) else {
            return nil
        }

        do {
            try controller.performFetch()
        } catch {
        }

        return controller
    }

    private func makeUnreadFetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        var controller: NSFetchedResultsController<NSFetchRequestResult>?
        switch locationViewMode {
        case .singleMessage:
            let moc = coreDataContextProvider.mainContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: LabelUpdate.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == %@) AND (%K == %@)",
                                                 LabelUpdate.Attributes.labelID,
                                                 self.labelID,
                                                 LabelUpdate.Attributes.userID,
                                                 self.user.userinfo.userId)
            let strComp = NSSortDescriptor(key: LabelUpdate.Attributes.labelID,
                                           ascending: true,
                                           selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            fetchRequest.sortDescriptors = [strComp]
            controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        case .conversation:
            let moc = coreDataContextProvider.mainContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ConversationCount.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == %@) AND (%K == %@)",
                                                 ConversationCount.Attributes.userID,
                                                 self.user.userinfo.userId,
                                                 ConversationCount.Attributes.labelID,
                                                 self.labelID)
            let strComp = NSSortDescriptor(key: ConversationCount.Attributes.labelID,
                                           ascending: true,
                                           selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            fetchRequest.sortDescriptors = [strComp]
            controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        }

        guard let fetchController = controller else {
            return nil
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
    func item(index: IndexPath) -> Message? {
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

        return fetchedResultsController?.object(at: index) as? Message
    }

    func itemOfConversation(index: IndexPath) -> Conversation? {
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
        let contextLabel = fetchedResultsController?.object(at: index) as? ContextLabel
        return contextLabel?.conversation
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
    func lastUpdateTime() -> LabelCount? {
        switch currentViewMode {
        case .singleMessage:
            return lastUpdatedStore.lastUpdate(by: self.labelID, userID: self.messageService.userID, context: coreDataContextProvider.mainContext, type: .singleMessage)
        case .conversation:
            return lastUpdatedStore.lastUpdate(by: self.labelID, userID: self.messageService.userID, context: coreDataContextProvider.mainContext, type: .conversation)
        }
    }

    func getLastUpdateTimeText() -> String {
        var result = LocalString._mailblox_last_update_time_more_than_1_hour

        if let updateTime = lastUpdatedStore.lastEventUpdateTime(userID: self.messageService.userID) {
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

    func updateListAndCounter(complete: @escaping ((LabelCount?) -> Void)) {
        let group = DispatchGroup()
        group.enter()
        self.messageService.updateMessageCount {
            group.leave()
        }

        group.enter()
        self.fetchMessages(time: 0, forceClean: false, isUnread: false) { task, response, error in
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

    func fetchConversationDetail(conversationID: String, completion: ((Result<Conversation, Error>) -> Void)?) {
        conversationProvider.fetchConversation(with: conversationID, includeBodyOf: nil, callOrigin: "MailboxViewModel", completion: completion)
    }

    func markConversationAsUnread(conversationIDs: [String], currentLabelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        conversationProvider.markAsUnread(conversationIDs: conversationIDs, labelID: currentLabelID, completion: completion)
    }

    func markConversationAsRead(conversationIDs: [String], currentLabelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        conversationProvider.markAsRead(conversationIDs: conversationIDs, labelID: currentLabelID, completion: completion)
    }

    func fetchConversationCount(completion: ((Result<Void, Error>) -> Void)?) {
        conversationProvider.fetchConversationCounts(addressID: nil, completion: completion)
    }

    func labelConversations(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        conversationProvider.label(conversationIDs: conversationIDs, as: labelID, isSwipeAction: false, completion: completion)
    }

    func unlabelConversations(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        conversationProvider.unlabel(conversationIDs: conversationIDs, as: labelID, isSwipeAction: false, completion: completion)
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
        return labelID == Message.Location.draft.rawValue
    }

    func mark(messages: [Message], unread: Bool = true) {
        messageService.mark(messages: messages, labelID: self.labelID, unRead: unread)
    }

    func label(msg message: Message, with labelID: String, apply: Bool = true) {
        messageService.label(messages: [message], label: labelID, apply: apply, shouldFetchEvent: false)
    }

    final func delete(IDs: Set<String>, completion: (() -> Void)? = nil) {
        switch locationViewMode {
        case .conversation:
            deletePermanently(conversationIDs: Array(IDs), completion: completion)
        case .singleMessage:
            let messages = self.messageService.fetchMessages(withIDs: NSMutableSet(set: IDs), in: coreDataContextProvider.mainContext)
            self.deletePermanently(messages: messages)
        }
    }

    private func deletePermanently(messages: [Message]) {
        messageService.delete(messages: messages, label: self.labelID)
    }

    private func deletePermanently(conversationIDs: [String], completion: (() -> Void)? = nil) {
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
             to: Message.Location.inbox.rawValue)
    }

    private func handleMoveToArchiveAction() {
        move(IDs: Set(selectedIDs),
             from: labelID,
             to: Message.Location.archive.rawValue)
    }

    private func handleMoveToSpamAction() {
        move(IDs: Set(selectedIDs),
             from: labelID,
             to: Message.Location.spam.rawValue)
    }

    private func handleUnstarAction() {
        let starredItemsIds: [String]
        switch locationViewMode {
        case .conversation:
            starredItemsIds = selectedConversations
                .filter { $0.starred }
                .map(\.conversationID)
        case .singleMessage:
            starredItemsIds = selectedMessages
                .filter { $0.starred }
                .map(\.messageID)
        }
        label(IDs: Set<String>(starredItemsIds), with: Message.Location.starred.rawValue, apply: false)
    }

    private func handleStarAction() {
        let unstarredItemsIds: [String]
        switch locationViewMode {
        case .conversation:
            unstarredItemsIds = selectedConversations
                .filter { !$0.starred }
                .map(\.conversationID)
        case .singleMessage:
            unstarredItemsIds = selectedMessages
                .filter { !$0.starred }
                .map(\.messageID)
        }
        label(IDs: Set<String>(unstarredItemsIds), with: Message.Location.starred.rawValue, apply: true)
    }

    private func handleMarkReadAction() {
        let unreadItemsIds: [String]
        switch locationViewMode {
        case .conversation:
            unreadItemsIds = selectedConversations
                .filter { $0.isUnread(labelID: labelID) }
                .map(\.conversationID)
        case .singleMessage:
            unreadItemsIds = selectedMessages
                .filter { $0.unRead }
                .map(\.messageID)
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
        case .singleMessage:
            unreadItemsIds = selectedMessages
                .filter { !$0.unRead }
                .map(\.messageID)
        }
        mark(IDs: Set(unreadItemsIds), unread: true)
    }

    private func handleRemoveAction() {
        move(IDs: Set(selectedIDs),
             from: labelID,
             to: Message.Location.trash.rawValue)
    }
}

// MARK: - Data fetching methods
extension MailboxViewModel {
    func fetchEvents(notificationMessageID: String?, completion: CompletionBlock?) {
        eventsService.fetchEvents(byLabel: self.labelID,
                                   notificationMessageID: notificationMessageID,
                                   completion: completion)
    }

    func fetchMessages(time: Int, forceClean: Bool, isUnread: Bool, completion: CompletionBlock?) {
        switch self.locationViewMode {
        case .singleMessage:
            messageService.fetchMessages(byLabel: self.labelID, time: time, forceClean: forceClean, isUnread: isUnread, queued: false, completion: completion)
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

    func fetchDataWithReset(time: Int, cleanContact: Bool, removeAllDraft: Bool, unreadOnly: Bool, completion: CompletionBlock?) {
        switch locationViewMode {
        case .singleMessage:
            messageService.fetchMessagesWithReset(byLabel: self.labelID, time: time, cleanContact: cleanContact, removeAllDraft: removeAllDraft, queued: false, unreadOnly: unreadOnly, completion: completion)
        case .conversation:
            eventsService.fetchLatestEventID(completion: nil)
            conversationProvider.fetchConversations(for: self.labelID, before: time, unreadOnly: unreadOnly, shouldReset: true) { [weak self] result in
                guard let self = self else {
                    completion?(nil, nil, result.nsError)
                    return
                }
                self.conversationProvider.fetchConversationCounts(addressID: nil) { _ in
                    completion?(nil, nil, result.nsError)
                }
            }
        }
    }
}

// MARK: Message Actions
extension MailboxViewModel {

    func checkToUseReadOrUnreadAction(messageIDs: Set<String>, labelID: String) -> Bool {
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
               with labelID: String,
               apply: Bool,
               completion: (() -> Void)? = nil) {
        switch self.locationViewMode {
        case .singleMessage:
            let ids = NSMutableSet(set: messageIDs)
            let messages = self.messageService.fetchMessages(withIDs: ids, in: coreDataContextProvider.mainContext)
            messageService.label(messages: messages, label: labelID, apply: apply)
            completion?()
        case .conversation:
            if apply {
                conversationProvider.label(conversationIDs: Array(messageIDs), as: labelID, isSwipeAction: false) { [weak self] result in
                    defer {
                        completion?()
                    }
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            } else {
                conversationProvider.unlabel(conversationIDs: Array(messageIDs), as: labelID, isSwipeAction: false) { [weak self] result in
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
            messageService.mark(messages: messages, labelID: self.labelID, unRead: unread)
            completion?()
        case .conversation:
            if unread {
                conversationProvider.markAsUnread(conversationIDs: Array(messageIDs), labelID: self.labelID) { [weak self] result in
                    defer {
                        completion?()
                    }
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            } else {
                conversationProvider.markAsRead(conversationIDs: Array(messageIDs), labelID: self.labelId) { [weak self] result in
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
              from fLabel: String,
              to tLabel: String,
              completion: (() -> Void)? = nil) {
        switch self.locationViewMode {
        case .singleMessage:
            let ids = NSMutableSet(set: messageIDs)
            let messages = self.messageService.fetchMessages(withIDs: ids, in: coreDataContextProvider.mainContext)
            var fLabels: [String] = []
            for msg in messages {
                // the label that is not draft, sent, starred, allmail
                fLabels.append(msg.firstValidFolder() ?? fLabel)
            }
            messageService.move(messages: messages, from: fLabels, to: tLabel)
            completion?()
        case .conversation:
            conversationProvider.move(conversationIDs: Array(messageIDs),
                                     from: fLabel,
                                     to: tLabel,
                                     isSwipeAction: false) { [weak self] result in
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
                    isDraft: message.draft,
                    isUnread: message.unRead,
                    isStar: message.contains(label: .starred),
                    isInTrash: message.contains(label: .trash),
                    isInArchive: message.contains(label: .archive),
                    isInSent: message.contains(label: .sent),
                    isInSpam: message.contains(label: .spam),
                    action: action
                )
            case .conversation(let conversation):
                result = helper.checkIsSwipeActionValidOnConversation(
                    isUnread: conversation.isUnread(labelID: labelID),
                    isStar: conversation.starred,
                    isInArchive: conversation.contains(of: Message.Location.archive.rawValue),
                    isInSpam: conversation.contains(of: Message.Location.spam.rawValue),
                    isInSent: conversation.contains(of: Message.Location.sent.rawValue),
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

    func swipyCellDidFinishSwiping() {
        // the value needs to be reset, otherwise there will be a feedback upon starting another swipe
        swipingTriggerActivated = false
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

// MARK: - In-App feedback model related

extension MailboxViewModel {
    var isInAppFeedbackFeatureEnabled: Bool {
        return self.user.inAppFeedbackStateService.isEnable
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
