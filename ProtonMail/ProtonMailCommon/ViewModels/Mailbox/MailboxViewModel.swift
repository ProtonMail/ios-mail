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
import PMCommon

enum SwipeResponse {
    case showUndo
    case nothing
    case showGeneral
}

class UndoMessage {
    var messageID : String
    var origLabels : String
    var newLabels : String
    
    //
    required init(msgID: String, origLabels : String, newLabels: String) {
        self.messageID  = msgID
        self.origLabels = origLabels
        self.newLabels  = newLabels
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
    
    /// mailbox viewModel
    ///
    /// - Parameters:
    ///   - labelID: location id and labelid
    ///   - msgService: service instance
    init(labelID : String, userManager: UserManager, usersManager: UsersManager?, pushService: PushNotificationService, coreDataService: CoreDataService, lastUpdatedStore: LastUpdatedStoreProtocol, queueManager: QueueManager) {
        self.labelID = labelID
        self.user = userManager
        self.messageService = userManager.messageService
        self.contactService = userManager.contactService
        self.coreDataService = coreDataService
        self.pushService = pushService
        self.users = usersManager
        self.lastUpdatedStore = lastUpdatedStore
        self.queueManager = queueManager
    }
    
    /// localized navigation title. overrride it or return label name
    var localizedNavigationTitle : String {
        get {
            return ""
        }
    }
    
    var viewMode: UserInfo.ViewMode {
        let singleMessageOnlyLabels: [Message.Location] = [.draft, .sent]
        if let location = Message.Location.init(rawValue: self.labelID),
           singleMessageOnlyLabels.contains(location),
           self.user.userinfo.viewMode == .conversation {
            return .singleMessage
        }
        return self.user.userInfo.viewMode
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
        let selectedMessages = self.selectedMessages

        let starredMessages = selectedMessages.filter { $0.starred }
        let unstarredMessages = selectedMessages.filter { !$0.starred }
        let readMessages = selectedMessages.filter { !$0.unRead }
        let unreadMessages = selectedMessages.filter { $0.unRead }

        var actions: [MailListActionSheetItemViewModel] = []
        actions += !starredMessages.isEmpty ? [.unstarActionViewModel(number: starredMessages.count)] : []
        actions += !unstarredMessages.isEmpty ? [.starActionViewModel(number: unstarredMessages.count)] : []
        actions += !unreadMessages.isEmpty ? [.markReadActionViewModel(number: unreadMessages.count)] : []
        actions += !readMessages.isEmpty ? [.markUnreadActionViewModel(number: readMessages.count)] : []
        actions += shouldDisplayRemoveAction ? [.removeActionViewModel(number: selectedIDs.count)] : []
        actions += shouldDisplayDeleteAction ? [.deleteActionViewModel(number: selectedIDs.count)] : []
        actions += shouldDisplayMoveToArchiveAction ? [.moveToArchive(number: selectedIDs.count)] : []
        actions += shouldDisplayMoveToSpamAction ? [.moveToSpam(number: selectedIDs.count)] : []

        return .init(title: .actionSheetTitle(selectedCount: selectedIDs.count), items: actions)
    }

    var selectedMessages: [Message] {
        fetchedResultsController?.fetchedObjects?
            .compactMap { $0 as? Message }
            .filter { selectedIDs.contains($0.messageID) } ?? []
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
                
                if let updateTime = self.lastUpdatedStore.lastUpdate(by: self.labelID, userID: secondUser.userInfo.userId, context: self.coreDataService.mainContext, type: .message),
                   updateTime.isNew == false, secondUser.messageService.isEventIDValid(context: self.coreDataService.mainContext) {
                    secondUser.messageService.fetchEvents(byLable: self.labelID,
                                                          notificationMessageID: nil,
                                                          completion: secondComplete)
                } else {// this new
                    if !secondUser.messageService.isEventIDValid(context: self.coreDataService.operationContext) { //if event id is not valid reset
                        secondUser.messageService.fetchMessagesWithReset(byLabel: self.labelID, time: 0, completion: secondComplete)
                    }
                    else {
                        secondUser.messageService.fetchMessages(byLable: self.labelID,
                                                                time: 0,
                                                                forceClean: false,
                                                                isUnread: false,
                                                                completion: secondComplete)
                    }
                }
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
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ContextLabelUpdate.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == %@) AND (%K == %@)",
                                                 ContextLabelUpdate.Attributes.userID,
                                                 self.user.userinfo.userId,
                                                 ContextLabelUpdate.Attributes.labelID,
                                                 self.labelID)
            let strComp = NSSortDescriptor(key: ContextLabelUpdate.Attributes.labelID,
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
        return fetchedResultsController?.object(at: index) as? Conversation
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
            return lastUpdatedStore.lastUpdate(by: self.labelID, userID: self.messageService.userID, context: self.coreDataService.mainContext, type: .message)
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
                result = String(format: LocalString._mailblox_last_update_time, minute)
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
    
    ///
    func selectedMessages(selected: NSMutableSet) -> [Message] {
        return messageService.fetchMessages(withIDs: selected, in: self.coreDataService.mainContext)
    }
    
    ///
    func message(by messageID: String) -> Message? {
        if let context = self.fetchedResultsController?.managedObjectContext {
            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                return message
            }
        }
        return nil
    }
    ///
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
    
    func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
        return false
    }
    
    func isShowEmptyFolder() -> Bool {
        return false
    }
    
    func emptyFolder() {
        
    }
    
    func fetchMessages(time: Int, forceClean: Bool, isUnread: Bool, completion: CompletionBlock?) {
        switch self.viewMode {
        case .singleMessage:
            messageService.fetchMessages(byLable: self.labelID, time: time, forceClean: forceClean, isUnread: isUnread, completion: completion)
        case .conversation:
            messageService.fetchConversations(by: self.labelID, time: time, forceClean: forceClean, isUnread: isUnread, completion: completion)
        }
    }
    
    func fetchConversationDetail(converstaionID: String, completion: ((Result<[String], Error>) -> Void)?) {
        messageService.fetchConversationDetail(by: converstaionID, completion: completion)
    }
    
    func markConversationAsUnread(conversationIDs: [String], currentLabelID: String, completion: ((Result<Bool, Error>) -> Void)?) {
        messageService.markConversationAsUnread(by: conversationIDs, currentLabelID: currentLabelID, completion: completion)
    }
    
    func markConversationAsRead(conversationIDs: [String], completion: ((Result<Bool, Error>) -> Void)?) {
        messageService.markConversationAsRead(by: conversationIDs, completion: completion)
    }
    
    func fetchConversationCount(completion: ((Result<[ConversationCountData], Error>) -> Void)?) {
        messageService.fetchConversationsCount(completion: completion)
    }
    
    func labelConversations(conversationIDs: [String], labelID: String, completion: ((Result<Bool, Error>) -> Void)?) {
        messageService.labelConversations(conversationIDs: conversationIDs, labelID: labelID, completion: completion)
    }
    
    func unlabelConversations(conversationIDs: [String], labelID: String, completion: ((Result<Bool, Error>) -> Void)?) {
        messageService.unlabelConversations(conversationIDs: conversationIDs, labelID: labelID, completion: completion)
    }
    
    func deleteConversations(conversationIDs: [String], labelID: String, completion: ((Result<Bool, Error>) -> Void)?) {
        messageService.deleteConversations(conversationIDs: conversationIDs, labelID: labelID, completion: completion)
    }
    
    func fetchEvents(time: Int, notificationMessageID:String?, completion: CompletionBlock?) {
        messageService.fetchEvents(byLable: self.labelID,
                                   notificationMessageID: notificationMessageID,
                                   completion: completion)
    }
    
    /// fetch messages and reset events
    ///
    /// - Parameters:
    ///   - time: the latest mailbox cached time
    ///   - completion: aync complete handler
    func fetchMessageWithReset(time: Int, completion: CompletionBlock?) {
        messageService.fetchMessagesWithReset(byLabel: self.labelID, time: time, completion: completion)
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
        messageService.label(messages: [message], label: labelID, apply: apply)
    }
    
    //TODO: - v4 need refactor
    func move(IDs messageIDs : NSMutableSet, to tLabel: String) {
        self.move(IDs: messageIDs, from: self.labelID, to: tLabel)
    }
    
    func undo(_ undo: UndoMessage) {
        let messages = self.messageService.fetchMessages(withIDs: [undo.messageID], in: self.coreDataService.mainContext)
        let fLabels: [String] = .init(repeating: undo.newLabels, count: messages.count)
        messageService.move(messages: messages, from: fLabels, to: undo.origLabels)
    }
    
    final func delete(IDs: NSMutableSet) {
        let messages = self.messageService.fetchMessages(withIDs: IDs, in: coreDataService.mainContext)
        for msg in messages {
            let _ = self.delete(message: msg)
        }
    }
    
    final func delete(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            return self.delete(message: message)
        }
        return (.nothing, nil)
    }
    
    func delete(message: Message) -> (SwipeResponse, UndoMessage?) {
        if messageService.move(messages: [message], from: [self.labelID], to: Message.Location.trash.rawValue) {
            return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: self.labelID, newLabels: Message.Location.trash.rawValue))
        }
        return (.nothing, nil)
    }
    
    func archive(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            if messageService.move(messages: [message], from: [self.labelID], to: Message.Location.archive.rawValue) {
                return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: self.labelID, newLabels: Message.Location.archive.rawValue))
            }
        }
        return (.nothing, nil)
    }
    
    func spam(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            if messageService.move(messages: [message], from: [self.labelID], to: Message.Location.spam.rawValue) {
                return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: self.labelID, newLabels: Message.Location.spam.rawValue))
            }
        }
        return (.nothing, nil)
    }
    
    func checkStorageIsCloseLimit() {
        let usedStorageSpace = self.user.userInfo.usedSpace
        let maxStorageSpace = self.user.userInfo.maxSpace
        checkSpace(usedStorageSpace, maxSpace: maxStorageSpace, user: self.user)
    }
    
    func shouldShowUpdateAlert() -> Bool {
        return false
    }
    
    func setiOS10AlertIsShown() {
        userCachedStatus.iOS10AlertIsShown = true
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
        }
    }

    private func handleMoveToArchiveAction() {
        move(IDs: NSMutableSet(set: selectedIDs), to: Message.Location.archive.rawValue)
    }

    private func handleMoveToSpamAction() {
        move(IDs: NSMutableSet(set: selectedIDs), to: Message.Location.spam.rawValue)
    }

    private func handleUnstarAction() {
        let starredMessagesIds = selectedMessages
            .filter { $0.starred }
            .map(\.messageID)
        label(IDs: NSMutableSet(array: starredMessagesIds), with: Message.Location.starred.rawValue, apply: false)
    }

    private func handleStarAction() {
        let unstaredMessagesIds = selectedMessages
            .filter { !$0.starred }
            .map(\.messageID)
        label(IDs: NSMutableSet(array: unstaredMessagesIds), with: Message.Location.starred.rawValue, apply: true)
    }

    private func handleMarkReadAction() {
        let unreadMessagesIds = selectedMessages
            .filter { $0.unRead }
            .map(\.messageID)
        mark(IDs: NSMutableSet(array: unreadMessagesIds), unread: false)
    }

    private func handleMarkUnreadAction() {
        let readMessagesIds = selectedMessages
            .filter { !$0.unRead }
            .map(\.messageID)
        mark(IDs: NSMutableSet(array: readMessagesIds), unread: true)
    }

    private func handleRemoveAction() {
        move(IDs: NSMutableSet(set: selectedIDs), to: Message.Location.trash.rawValue)
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

// MARK: Message Actions
extension MailboxViewModel {
    func checkToUseReadOrUnreadAction(messageIDs: NSMutableSet) -> Bool {
        var readCount = 0
        coreDataService.mainContext.performAndWait {
            switch self.viewMode {
            case .conversation:
                let conversations = self.messageService.fetchConversations(withIDs: messageIDs, in: coreDataService.mainContext)
                readCount = conversations.reduce(0) { (result, next) -> Int in
                    if next.numUnread.intValue == 0 {
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
            let conversations = self.messageService.fetchConversations(withIDs: messageIDs, in: coreDataService.mainContext)
            messageService.label(conversations: conversations, label: labelID, apply: apply)
        }
    }
    
    func mark(IDs messageIDs : NSMutableSet, unread: Bool) {
        switch self.viewMode {
        case .singleMessage:
            let messages = self.messageService.fetchMessages(withIDs: messageIDs, in: coreDataService.mainContext)
            messageService.mark(messages: messages, labelID: self.labelID, unRead: unread)
        case .conversation:
            let conversations = self.messageService.fetchConversations(withIDs: messageIDs, in: coreDataService.operationContext)
            messageService.mark(conversations: conversations, labelID: self.labelID, unRead: unread)
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
            let conversations = self.messageService.fetchConversations(withIDs: messageIDs, in: coreDataService.operationContext)
            #warning("TODO: - v4 Check From label is valid or not")
            messageService.move(conversations: conversations, from: fLabel, to: tLabel)
            break
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
}

private extension String {

    static func actionSheetTitle(selectedCount: Int) -> String {
        if selectedCount > 1 {
            return String(format: LocalString._title_of_multiple_messages_action_sheet, selectedCount)
        } else {
            return String(format: LocalString._title_of_single_message_action_sheet, selectedCount)
        }
    }

}
