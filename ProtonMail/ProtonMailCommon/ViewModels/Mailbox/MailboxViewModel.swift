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

enum SwipeResponse {
    case showUndo
    case nothing
    case showGeneral
}

class UndoMessage {
    var messageID : String
    var origLabels : String
    var newLabels : String
    var origHasStar: Bool
    
    //
    required init(msgID: String, origLabels : String, origHasStar: Bool, newLabels: String) {
        self.messageID  = msgID
        self.origLabels = origLabels
        self.newLabels  = newLabels
        self.origHasStar = origHasStar
    }
}
extension MailboxViewModel {
    enum Errors: Error {
        case decoding
    }
}

class MailboxViewModel: StorageLimit {
    internal let labelID : String
    /// message service
    internal let user: UserManager
    internal let messageService : MessageDataService
    internal let conversationService : ConversationProvider
    internal let eventsService: EventsFetching
    private let pushService : PushNotificationService
    /// fetch controller
    private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    private(set) var labelFetchedResults: NSFetchedResultsController<NSFetchRequestResult>?
    private(set) var unreadFetchedResult: NSFetchedResultsController<NSFetchRequestResult>?
 
    private var contactService : ContactDataService
    
    private let coreDataService: CoreDataService
    
    private let lastUpdatedStore: LastUpdatedStoreProtocol
    
    private(set) var selectedIDs: Set<String> = Set()
    private let queueManager: QueueManager

    var selectedMoveToFolder: MenuLabel?
    var selectedLabelAsLabels: Set<LabelLocation> = Set()

    weak var users: UsersManager?

    private let conversationStateService: ConversationStateService

    var viewModeIsChanged: (() -> Void)?
    
    /// mailbox viewModel
    ///
    /// - Parameters:
    ///   - labelID: location id and labelid
    ///   - msgService: service instance
    init(labelID : String, userManager: UserManager, usersManager: UsersManager?, pushService: PushNotificationService, coreDataService: CoreDataService, lastUpdatedStore: LastUpdatedStoreProtocol, queueManager: QueueManager) {
        self.labelID = labelID
        self.user = userManager
        self.messageService = userManager.messageService
        self.conversationService = userManager.conversationService
        self.eventsService = userManager.eventsService
        self.contactService = userManager.contactService
        self.coreDataService = coreDataService
        self.pushService = pushService
        self.users = usersManager
        self.lastUpdatedStore = lastUpdatedStore
        self.queueManager = queueManager
        self.conversationStateService = userManager.conversationStateService
        self.conversationStateService.add(delegate: self)
    }
    
    /// localized navigation title. overrride it or return label name
    var localizedNavigationTitle : String {
        get {
            return ""
        }
    }
    
    var viewMode: ViewMode {
        let singleMessageOnlyLabels: [Message.Location] = [.draft, .sent]
        if let location = Message.Location.init(rawValue: labelID),
           singleMessageOnlyLabels.contains(location),
           self.conversationStateService.viewMode == .conversation {
            return .singleMessage
        }
        return self.conversationStateService.viewMode
    }
    
    var isRequiredHumanCheck: Bool {
        get { return self.queueManager.isRequiredHumanCheck }
        set { self.queueManager.isRequiredHumanCheck = newValue }
    }

    var isCurrentUserSelectedUnreadFilterInInbox: Bool {
        get {
            return self.user.isUserSelectedUnreadFilterInInbox
        }
        set {
            self.user.isUserSelectedUnreadFilterInInbox = newValue
        }
    }

    var countOfFetchedObjects: Int {
        return fetchedResultsController?.fetchedObjects?.count ?? 0
    }

    var actionSheetViewModel: MailListActionSheetViewModel {
        return .init(labelId: labelId,
                     title: .actionSheetTitle(selectedCount: selectedIDs.count, viewMode: viewMode))
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

    var customFolders: [Label] {
        return user.labelService.getAllLabels(of: .folder, context: coreDataService.mainContext)
    }

    func allEmails() -> [Email] {
        return self.contactService.allEmails()
    }
        
    func fetchContacts() {
        self.contactService.fetchContacts { (_, _) in
            
        }
    }

    private var fetchingMessageForOhters : Bool = false
    
    func getLatestMessagesForOthers() {
        if fetchingMessageForOhters == false {
            fetchingMessageForOhters = true
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                guard let users = self.users else { return }
                guard let secondUser = users.get(not: self.user.userInfo.userId) else { return }
                let secondComplete : CompletionBlock = { (task, res, error) -> Void in
                    var loadMore: Int = 0
                    if error == nil {
                        if let more = res?["More"] as? Int {
                            loadMore = more
                        }
                        if loadMore <= 0 {
                            secondUser.messageService.updateMessageCount()
                        }
                    }
                    
                    if loadMore > 0 {
                        //self.retry()
                    } else {
                        self.fetchingMessageForOhters = false
                    }
                }
                
                if let updateTime = self.lastUpdatedStore.lastUpdate(by: self.labelID, userID: secondUser.userInfo.userId, context: self.coreDataService.mainContext, type: .singleMessage),
                   updateTime.isNew == false, secondUser.messageService.isEventIDValid(context: self.coreDataService.mainContext) {
                    secondUser.eventsService.fetchEvents(byLabel: self.labelID,
                                                          notificationMessageID: nil,
                                                          completion: secondComplete)
                } else {// this new
                    if !secondUser.messageService.isEventIDValid(context: self.coreDataService.operationContext) { //if event id is not valid reset
                        secondUser.messageService.fetchMessagesWithReset(byLabel: self.labelID, time: 0, completion: secondComplete)
                    }
                    else {
                        secondUser.messageService.fetchMessages(byLabel: self.labelID,
                                                                time: 0,
                                                                forceClean: false,
                                                                isUnread: false,
                                                                completion: secondComplete)
                    }
                }
            }
        }
    }
    
    func forceRefreshMessagesForOthers() {
        if fetchingMessageForOhters == false {
            fetchingMessageForOhters = true
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard let users = self.users else { return }
                guard let secondUser = users.get(not: self.user.userInfo.userId) else { return }
                let secondComplete : CompletionBlock = { (task, res, error) -> Void in
                    var loadMore: Int = 0
                    if error == nil {
                        if let more = res?["More"] as? Int {
                            loadMore = more
                        }
                        if loadMore <= 0 {
                            secondUser.messageService.updateMessageCount()
                        }
                    }
                    
                    if loadMore > 0 {
                        //self.retry()
                    } else {
                        self.fetchingMessageForOhters = false
                    }
                }
                secondUser.messageService.fetchMessagesWithReset(byLabel: self.labelID, time: 0, cleanContact: false, completion: secondComplete)
            }
        }
    }
    
    /// create a fetch controller with labelID
    ///
    /// - Returns: fetched result controller
    private func makeFetchController(isUnread: Bool) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let fetchedResultsController = messageService.fetchedResults(by: self.labelID, viewMode: self.viewMode, isUnread: isUnread)
        if let fetchedResultsController = fetchedResultsController {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D(" error: \(ex)")
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
        } catch let ex as NSError {
            PMLog.D(" error: \(ex)")
        }
        
        return controller
    }
    
    private func makeUnreadFetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        var controller: NSFetchedResultsController<NSFetchRequestResult>?
        switch viewMode {
        case .singleMessage:
            let moc = self.coreDataService.mainContext
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
            let moc = self.coreDataService.mainContext
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
        } catch let ex as NSError {
            PMLog.D(" error: \(ex)")
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
        switch self.viewMode {
        case .singleMessage:
            return lastUpdatedStore.lastUpdate(by: self.labelID, userID: self.messageService.userID, context: self.coreDataService.mainContext, type: .singleMessage)
        case .conversation:
            return lastUpdatedStore.lastUpdate(by: self.labelID, userID: self.messageService.userID, context: self.coreDataService.mainContext, type: .conversation)
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
    
    
    /// process push
    func processCachedPush() {
        self.pushService.processCachedLaunchOptions()
    }
    
    func getSearchViewModel(uiDelegate: SearchViewUIProtocol) -> SearchVMProtocol {
        SearchViewModel(user: self.user,
                        coreDataService: self.coreDataService,
                        uiDelegate: uiDelegate)
    }

    func message(by messageID: String) -> Message? {
        if let context = self.fetchedResultsController?.managedObjectContext {
            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                return message
            }
        }
        return nil
    }

    func object(by object: NSManagedObjectID) -> Message? {
        if let obj = self.fetchedResultsController?.managedObjectContext.object(with: object) as? Message {
            return obj
        }
        return nil
    }
    
    func indexPath(by messageID: String) -> IndexPath? {
        guard let object = self.message(by: messageID),
            let index = self.fetchedResultsController?.indexPath(forObject: object) else
        {
            return nil
        }
        return index
    }
    
    func isDrafts() -> Bool {
        return false
    }
    
    func isArchive() -> Bool {
        return false
    }
    
    func isDelete () -> Bool {
        return false
    }
    
    func showLocation () -> Bool {
        return false
    }
    
    func ignoredLocationTitle() -> String {
        return ""
    }
    
    func isCurrentLocation(_ l : Message.Location) -> Bool {
        return self.labelID == l.rawValue
    }
    
    func isSwipeActionValid(_ action: MessageSwipeAction, message: Message) -> Bool {
        return true
    }

    func isSwipeActionValid(_ action: MessageSwipeAction, conversation: Conversation) -> Bool {
        true
    }
    
    func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
        return false
    }
    
    func isShowEmptyFolder() -> Bool {
        return false
    }
    
    func emptyFolder() {
        
    }
    
    func fetchConversationDetail(conversationID: String, completion: ((Result<Void, Error>) -> Void)?) {
        conversationService.fetchConversation(with: conversationID, includeBodyOf: nil, completion: completion)
    }
    
    func markConversationAsUnread(conversationIDs: [String], currentLabelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        conversationService.markAsUnread(conversationIDs: conversationIDs, labelID: currentLabelID, completion: completion)
    }
    
    func markConversationAsRead(conversationIDs: [String], currentLabelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        conversationService.markAsRead(conversationIDs: conversationIDs, labelID: currentLabelID, completion: completion)
    }
    
    func fetchConversationCount(completion: ((Result<Void, Error>) -> Void)?) {
        conversationService.fetchConversationCounts(addressID: nil, completion: completion)
    }
    
    func labelConversations(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        conversationService.label(conversationIDs: conversationIDs, as: labelID, completion: completion)
    }
    
    func unlabelConversations(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        conversationService.unlabel(conversationIDs: conversationIDs, as: labelID, completion: completion)
    }
    
    func deleteConversations(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        conversationService.deleteConversations(with: conversationIDs, labelID: labelID, completion: completion)
    }
    
    func isEventIDValid() -> Bool {
        return messageService.isEventIDValid(context: self.coreDataService.mainContext)
    }
    
    /// get the cached notification message id
    var notificationMessageID: String? {
        messageService.pushNotificationMessageID
    }
    
    var notificationMessage: Message? {
        messageService.messageFromPush()
    }
    
    final func resetNotificationMessage() -> Void {
        messageService.pushNotificationMessageID = nil
    }
    
    /// this is a workaground for draft. somehow back from the background the fetch controller can't get the latest data. remove this when fix this issue
    ///
    /// - Returns: bool
    func reloadTable() -> Bool {
        return false
    }
    
    func getSwipeTitle(_ action: MessageSwipeAction) -> String {
        fatalError("This method must be overridden")
    }
    
    func mark(messages: [Message], unread: Bool = true) {
        messageService.mark(messages: messages, labelID: self.labelID, unRead: unread)
    }
    
    func label(msg message : Message, with labelID: String, apply: Bool = true) {
        messageService.label(messages: [message], label: labelID, apply: apply, shouldFetchEvent: false)
    }
    
    func undo(_ undo: UndoMessage) {
        switch viewMode {
        case .conversation:
            conversationService.move(conversationIDs: [undo.messageID],
                                     from: undo.newLabels,
                                     to: undo.origLabels) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
            if undo.origHasStar {
                conversationService.label(conversationIDs: [undo.messageID],
                                          as: Message.Location.starred.rawValue,
                                          completion: nil)
            }
        case .singleMessage:
            let messages = self.messageService.fetchMessages(withIDs: [undo.messageID], in: self.coreDataService.mainContext)
            let fLabels: [String] = .init(repeating: undo.newLabels, count: messages.count)
            messageService.move(messages: messages, from: fLabels, to: undo.origLabels)
            if undo.origHasStar {
                messageService.label(messages: messages,
                                     label: Message.Location.starred.rawValue,
                                     apply: true)
            }
        }
    }
    
    final func delete(IDs: NSMutableSet) {
        switch viewMode {
        case .conversation:
            deletePermanently(conversationIDs: IDs.asArrayOfStrings)
        case .singleMessage:
            let messages = self.messageService.fetchMessages(withIDs: IDs, in: coreDataService.mainContext)
            for msg in messages {
                deletePermanently(message: msg)
            }
        }
    }
    
    final func delete(index: IndexPath) -> (SwipeResponse, UndoMessage?, Bool) {
        if let message = self.item(index: index) {
            return self.delete(message: message)
        } else if let conversation = self.itemOfConversation(index: index) {
            return self.delete(conversationIDs: [conversation.conversationID])
        }
        return (.nothing, nil, false)
    }

    func delete(message: Message) -> (SwipeResponse, UndoMessage?, Bool) {
        if self.labelID == Message.Location.trash.rawValue {
            return (.nothing, nil, false)
        } else {
            if messageService.move(messages: [message], from: [self.labelID], to: Message.Location.trash.rawValue) {
                return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: self.labelID, origHasStar: message.starred, newLabels: Message.Location.trash.rawValue), true)
            } else {
                return (.nothing, nil, true)
            }
        }
    }

    private func deletePermanently(message: Message) {
        messageService.delete(messages: [message], label: self.labelID)
    }

    func delete(conversationIDs: [String]) -> (SwipeResponse, UndoMessage?, Bool) {
        if self.labelID == Message.Location.trash.rawValue {
            return (.nothing, nil, false)
        } else {
            let localConvos = conversationService.fetchLocalConversations(withIDs: NSMutableSet(array: conversationIDs),
                                                                          in: coreDataService.mainContext)
            let allTrashed = localConvos.allSatisfy { convo in
                if let labels = convo.labels as? Set<ContextLabel>,
                   labels.contains(where: { $0.labelID == Message.Location.trash.rawValue }) {
                    return true
                } else {
                    return false
                }
            }
            if allTrashed {
                return (.nothing, nil, false)
            } else {
                conversationService.move(conversationIDs: conversationIDs,
                                         from: self.labelID,
                                         to: Message.Location.trash.rawValue) { [weak self] result in
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
                return (.nothing, nil, true)
            }
        }
    }

    private func deletePermanently(conversationIDs: [String]) {
        conversationService.deleteConversations(with: conversationIDs, labelID: self.labelID) { [weak self] result in
            guard let self = self else { return }
            if let _ = try? result.get() {
                self.eventsService.fetchEvents(labelID: self.labelId)
            }
        }
    }

    func archive(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            if messageService.move(messages: [message], from: [self.labelID], to: Message.Location.archive.rawValue) {
                return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: self.labelID, origHasStar: message.starred, newLabels: Message.Location.archive.rawValue))
            }
        } else if let conversation = self.itemOfConversation(index: index) {
            conversationService.move(conversationIDs: [conversation.conversationID],
                                     from: self.labelID,
                                     to: Message.Location.archive.rawValue) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
            return (.showUndo, UndoMessage(msgID: conversation.conversationID, origLabels: self.labelID, origHasStar: conversation.starred, newLabels: Message.Location.archive.rawValue))
        }
        return (.nothing, nil)
    }
    
    func spam(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            if messageService.move(messages: [message], from: [self.labelID], to: Message.Location.spam.rawValue) {
                return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: self.labelID, origHasStar: message.starred, newLabels: Message.Location.spam.rawValue))
            }
        } else if let conversation = self.itemOfConversation(index: index) {
            conversationService.move(conversationIDs: [conversation.conversationID],
                                     from: self.labelID,
                                     to: Message.Location.spam.rawValue) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
            return (.showUndo, UndoMessage(msgID: conversation.conversationID, origLabels: self.labelID, origHasStar: conversation.starred, newLabels: Message.Location.archive.rawValue))
        }
        return (.nothing, nil)
    }
    
    func checkStorageIsCloseLimit() {
        let usedStorageSpace = self.user.userInfo.usedSpace
        let maxStorageSpace = self.user.userInfo.maxSpace
        checkSpace(usedStorageSpace, maxSpace: maxStorageSpace, user: self.user)
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
        switch viewMode {
        case .singleMessage:
            return item(index: indexPath)?.time
        case .conversation:
            return itemOfConversation(index: indexPath)?.getTime(labelID: labelID)
        }
    }

    private func handleMoveToInboxAction() {
        move(IDs: NSMutableSet(set: selectedIDs),
             from: labelID,
             to: Message.Location.inbox.rawValue)
    }

    private func handleMoveToArchiveAction() {
        move(IDs: NSMutableSet(set: selectedIDs),
             from: labelID,
             to: Message.Location.archive.rawValue)
    }

    private func handleMoveToSpamAction() {
        move(IDs: NSMutableSet(set: selectedIDs),
             from: labelID,
             to: Message.Location.spam.rawValue)
    }

    private func handleUnstarAction() {
        let starredItemsIds: [String]
        switch viewMode {
        case .conversation:
            starredItemsIds = selectedConversations
                .filter { $0.starred }
                .map(\.conversationID)
        case .singleMessage:
            starredItemsIds = selectedMessages
                .filter { $0.starred }
                .map(\.messageID)
        }
        label(IDs: NSMutableSet(array: starredItemsIds), with: Message.Location.starred.rawValue, apply: false)
    }

    private func handleStarAction() {
        let unstarredItemsIds: [String]
        switch viewMode {
        case .conversation:
            unstarredItemsIds = selectedConversations
                .filter { !$0.starred }
                .map(\.conversationID)
        case .singleMessage:
            unstarredItemsIds = selectedMessages
                .filter { !$0.starred }
                .map(\.messageID)
        }
        label(IDs: NSMutableSet(array: unstarredItemsIds), with: Message.Location.starred.rawValue, apply: true)
    }

    private func handleMarkReadAction() {
        let unreadItemsIds: [String]
        switch viewMode {
        case .conversation:
            unreadItemsIds = selectedConversations
                .filter { $0.isUnread(labelID: labelID) }
                .map(\.conversationID)
        case .singleMessage:
            unreadItemsIds = selectedMessages
                .filter { $0.unRead }
                .map(\.messageID)
        }
        mark(IDs: NSMutableSet(array: unreadItemsIds), unread: false)
    }

    private func handleMarkUnreadAction() {
        let unreadItemsIds: [String]
        switch viewMode {
        case .conversation:
            unreadItemsIds = selectedConversations
                .filter { !$0.isUnread(labelID: labelID) }
                .map(\.conversationID)
        case .singleMessage:
            unreadItemsIds = selectedMessages
                .filter { !$0.unRead }
                .map(\.messageID)
        }
        mark(IDs: NSMutableSet(array: unreadItemsIds), unread: true)
    }

    private func handleRemoveAction() {
        move(IDs: NSMutableSet(set: selectedIDs),
             from: labelID,
             to: Message.Location.trash.rawValue)
    }

    private var shouldDisplayRemoveAction: Bool {
        let actionUnavailableLocations: [Message.Location] = [.spam, .trash, .draft]
        return !actionUnavailableLocations.map(\.rawValue).contains(labelID)
    }

    private var shouldDisplayDeleteAction: Bool {
        let actionAvailableLocations: [Message.Location] = [.trash, .spam, .draft]
        return actionAvailableLocations.map(\.rawValue).contains(labelID)
    }

    private var shouldDisplayMoveToArchiveAction: Bool {
        let actionUnavailableLocations: [Message.Location] = [.archive, .draft]
        return !actionUnavailableLocations.map(\.rawValue).contains(labelID)
    }

    private var shouldDisplayMoveToSpamAction: Bool {
        let actionUnavailableLocations: [Message.Location] = [.sent, .draft, .spam]
        return !actionUnavailableLocations.map(\.rawValue).contains(labelID)
    }

}

// MARK: - Data fetching methods
extension MailboxViewModel {
    func fetchEvents(time: Int, notificationMessageID:String?, completion: CompletionBlock?) {
        eventsService.fetchEvents(byLabel: self.labelID,
                                   notificationMessageID: notificationMessageID,
                                   completion: completion)
    }

    func fetchMessages(time: Int, forceClean: Bool, isUnread: Bool, completion: CompletionBlock?) {
        switch self.viewMode {
        case .singleMessage:
            messageService.fetchMessages(byLabel: self.labelID, time: time, forceClean: forceClean, isUnread: isUnread, queued: false, completion: completion)
        case .conversation:
            conversationService.fetchConversations(for: self.labelID, before: time, unreadOnly: isUnread, shouldReset: forceClean) { result in
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
        switch viewMode {
        case .singleMessage:
            messageService.fetchMessagesWithReset(byLabel: self.labelID, time: time, cleanContact: cleanContact, removeAllDraft: removeAllDraft, queued: false, unreadOnly: unreadOnly, completion: completion)
        case .conversation:
            messageService.fetchLatestEventID(completion: nil)
            conversationService.fetchConversationCounts(addressID: nil, completion: nil)
            conversationService.fetchConversations(for: self.labelID, before: time, unreadOnly: unreadOnly, shouldReset: true) { result in
                completion?(nil, nil, result.nsError)
            }
        }
    }
}

// MARK: Message Actions
extension MailboxViewModel {

    func checkToUseReadOrUnreadAction(messageIDs: NSMutableSet, labelID: String) -> Bool {
        var readCount = 0
        coreDataService.mainContext.performAndWait {
            switch self.viewMode {
            case .conversation:
                let conversations = self.conversationService.fetchLocalConversations(withIDs: messageIDs, in: coreDataService.mainContext)
                readCount = conversations.reduce(0) { (result, next) -> Int in
                    if next.getNumUnread(labelID: labelID) == 0 {
                        return result + 1
                    } else {
                        return result
                    }
                }
            case .singleMessage:
                let messages = self.messageService.fetchMessages(withIDs: messageIDs, in: coreDataService.mainContext)
                readCount = messages.reduce(0) { (result, next) -> Int in
                    if next.unRead == false {
                        return result + 1
                    } else {
                        return result
                    }
                }
            }
        }
        return readCount > 0
    }
    
    func label(IDs messageIDs : NSMutableSet, with labelID: String, apply: Bool) {
        switch self.viewMode {
        case .singleMessage:
            let messages = self.messageService.fetchMessages(withIDs: messageIDs, in: coreDataService.mainContext)
            messageService.label(messages: messages, label: labelID, apply: apply)
        case .conversation:
            if apply {
                conversationService.label(conversationIDs: messageIDs.asArrayOfStrings, as: labelID) { [weak self] result in
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            } else {
                conversationService.unlabel(conversationIDs: messageIDs.asArrayOfStrings, as: labelID) { [weak self] result in
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            }
        }
    }
    
    func mark(IDs messageIDs : NSMutableSet, unread: Bool) {
        switch self.viewMode {
        case .singleMessage:
            let messages = self.messageService.fetchMessages(withIDs: messageIDs, in: coreDataService.mainContext)
            messageService.mark(messages: messages, labelID: self.labelID, unRead: unread)
        case .conversation:
            if unread {
                conversationService.markAsUnread(conversationIDs: messageIDs.asArrayOfStrings, labelID: self.labelID) { [weak self] result in
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            } else {
                conversationService.markAsRead(conversationIDs: messageIDs.asArrayOfStrings, labelID: self.labelId) { [weak self] result in
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
            }
        }
    }
    
    func move(IDs messageIDs : NSMutableSet, from fLabel: String, to tLabel: String) {
        switch self.viewMode {
        case .singleMessage:
            let messages = self.messageService.fetchMessages(withIDs: messageIDs, in: coreDataService.mainContext)
            var fLabels: [String] = []
            for msg in messages {
                // the label that is not draft, sent, starred, allmail
                fLabels.append(msg.firstValidFolder() ?? fLabel)
            }
            messageService.move(messages: messages, from: fLabels, to: tLabel)
        case .conversation:
            conversationService.move(conversationIDs: messageIDs.asArrayOfStrings,
                                     from: fLabel,
                                     to: tLabel) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
        }
    }
}

//Message Selection
extension MailboxViewModel {
    func select(at index: IndexPath) -> Bool {
        guard !index.isEmpty, let sections = self.fetchedResultsController?.numberOfSections() else {
            return false
        }
        guard sections > index.section else {
            return false
        }
        
        guard let rows = self.fetchedResultsController?.numberOfRows(in: index.section) else {
            return false
        }
        
        guard rows > index.row else {
            return false
        }
        let object = fetchedResultsController?.object(at: index)
        switch self.viewMode {
        case .conversation:
            if let conversation = object as? Conversation {
                self.selectedIDs.insert(conversation.conversationID)
                return true
            }
        case .singleMessage:
            if let msg = object as? Message {
                self.selectedIDs.insert(msg.messageID)
                return true
            }
        }
        return false
    }
    
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
    func convertSwipeActionTypeToMessageSwipeAction(_ type: SwipeActionSettingType,
                                                      message: Message) -> MessageSwipeAction {
        switch type {
        case .none:
            return .none
        case .trash:
            return .trash
        case .spam:
            return .spam
        case .starAndUnstar:
            return message.contains(label: .starred) ? .unstar : .star
        case .archive:
            return .archive
        case .readAndUnread:
            return message.unRead ? .read : .unread
        case .labelAs:
            return .labelAs
        case .moveTo:
            return .moveTo
        }
    }

    func convertSwipeActionTypeToMessageSwipeAction(_ type: SwipeActionSettingType,
                                                      conversation: Conversation) -> MessageSwipeAction {
        switch type {
        case .none:
            return .none
        case .trash:
            return .trash
        case .spam:
            return .spam
        case .starAndUnstar:
            return conversation.starred ? .unstar : .star
        case .archive:
            return .archive
        case .readAndUnread:
            return conversation.isUnread(labelID: labelId) ? .read : .unread
        case .labelAs:
            return .labelAs
        case .moveTo:
            return .moveTo
        }
    }
}

extension MailboxViewModel: ConversationStateServiceDelegate {
    func viewModeHasChanged(viewMode: ViewMode) {
        viewModeIsChanged?()
    }

    func conversationModeFeatureFlagHasChanged(isFeatureEnabled: Bool) {

    }
}

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
