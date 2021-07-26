// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import CoreData
import Foundation
import ProtonCore_UIFoundations

protocol SearchVMProtocol {
    var user: UserManager { get }
    var messages: [Message] { get }
    var selectedIDs: Set<String> { get }
    var selectedMessages: [Message] { get }
    var labelID: String { get }

    func viewDidLoad()
    func cleanLocalIndex()
    func fetchRemoteData(query: String, fromStart: Bool)
    func loadMoreDataIfNeeded(currentRow: Int)
    func fetchMessageDetail(message: Message,
                            completeHandler: @escaping ((NSError?) -> Void))
    func getComposeViewModel(message: Message) -> ContainableComposeViewModel
    func getMessageCellViewModel(message: Message) -> NewMailboxMessageViewModel

    // Select / action bar / action sheet related
    // TODO: The logic is quite similar what we did in mailBoxVC, try to share the logic
    func isSelected(messageID: String) -> Bool
    func addSelected(messageID: String)
    func removeSelected(messageID: String)
    func removeAllSelectedIDs()
    func getActionTypes() -> [MailboxViewModel.ActionTypes]
    func getActionSheetViewModel() -> MailListActionSheetViewModel
    func handleBarActions(_ action: MailboxViewModel.ActionTypes)
    func deleteSelectedMessage()
    func handleActionSheetAction(_ action: MailListSheetAction)
    func getFolderMenuItems() -> [MenuLabel]
}

final class SearchViewModel {
    typealias LocalObjectsIndexRow = Dictionary<String, Any>
    let user: UserManager
    let coreDataService: CoreDataService

    private weak var uiDelegate: SearchViewUIProtocol?
    private(set) var messages: [Message] = [] {
        didSet {
            DispatchQueue.main.async {
                self.uiDelegate?.reloadTable()
            }
        }
    }
    private(set) var selectedIDs: Set<String> = []
    private var messageService: MessageDataService { self.user.messageService }
    private let localObjectIndexing: Progress = Progress(totalUnitCount: 1)
    private var localObjectsIndexingObserver: NSKeyValueObservation? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                let isHidden = self?.localObjectsIndexingObserver == nil
                self?.uiDelegate?.setupProgressBar(isHidden: isHidden)
            }
        }
    }
    private var dbContents: Array<LocalObjectsIndexRow> = []
    private var currentPage = 0
    private var query = ""

    var selectedMoveToFolder: MenuLabel?
    var selectedLabelAsLabels: Set<LabelLocation> = Set()
    var labelID: String { Message.Location.allmail.rawValue }
    var selectedMessages: [Message] {
        self.messages.filter { selectedIDs.contains($0.messageID) }
    }
    var selectedConversations: [Conversation] { [] }
    
    init(user: UserManager, coreDataService: CoreDataService, uiDelegate: SearchViewUIProtocol) {
        self.user = user
        self.coreDataService = coreDataService
        self.uiDelegate = uiDelegate
    }
}

extension SearchViewModel: SearchVMProtocol {
    func viewDidLoad() {
        self.indexLocalObjects { [weak self] in
            guard let self = self,
                  self.messages.isEmpty ,
                  !self.query.isEmpty else { return }
            self.fetchLocalObjects()
        }
    }
    
    func cleanLocalIndex() {
        // switches off indexing of Messages in local db
        self.localObjectIndexing.cancel()
    }
    
    func fetchRemoteData(query: String, fromStart: Bool) {
        if fromStart {
            self.messages = []
        }
        self.uiDelegate?.activityIndicator(isAnimating: true)
        
        self.query = query
        let pageToLoad = fromStart ? 0: self.currentPage + 1
        let service = user.messageService
        service.search(query, page: pageToLoad) { [weak self] messageBoxes, error in
            DispatchQueue.main.async {
                self?.uiDelegate?.activityIndicator(isAnimating: false)
            }
            guard error == nil,
                  let self = self,
                  let messageBoxes = messageBoxes else {
                PMLog.D(" search error: \(String(describing: error))")

                if pageToLoad == 0 {
                    self?.fetchLocalObjects()
                }
                return
            }
            self.currentPage = pageToLoad

            if messageBoxes.isEmpty {
                if pageToLoad == 0 {
                    self.messages = []
                }
                return
            }
            
            let context = self.coreDataService.mainContext
            context.perform { [weak self] in
                let messagesInContext = messageBoxes
                    .compactMap { context.object(with: $0.objectID) as? Message }
                    .filter { $0.managedObjectContext != nil }
                if pageToLoad > 0 {
                    self?.messages.append(contentsOf: messagesInContext)
                } else {
                    self?.messages = messagesInContext
                }
            }
        }
    }

    func loadMoreDataIfNeeded(currentRow: Int) {
        if self.messages.count - 1 <= currentRow {
            self.fetchRemoteData(query: self.query, fromStart: false)
        }
    }

    func fetchMessageDetail(message: Message, completeHandler: @escaping ((NSError?) -> Void)) {
        let service = self.user.messageService
        service.ForcefetchDetailForMessage(message) { _, _, _, error in
            completeHandler(error)
        }
    }
    
    func getComposeViewModel(message: Message) -> ContainableComposeViewModel {
        ContainableComposeViewModel(msg: message,
                                    action: .openDraft,
                                    msgService: user.messageService,
                                    user: user,
                                    coreDataService: self.coreDataService)
    }
    
    func getMessageCellViewModel(message: Message) -> NewMailboxMessageViewModel {
        let replacingEmails = self.user.contactService.allEmails()
        let initial = message.initial(replacingEmails: replacingEmails)
        let sender = message.sender(replacingEmails: replacingEmails)
        let weekStart = user.userInfo.weekStartValue
        let customFolderLabels = user.labelService.getAllLabels(
            of: .folder,
            context: CoreDataService.shared.mainContext
        )
        return .init(
            location: nil,
            isLabelLocation: true, // to show origin location icons
            style: .normal,
            initial: initial.apply(style: FontManager.body3RegularNorm),
            isRead: !message.unRead,
            sender: sender,
            time: date(of: message, weekStart: weekStart),
            isForwarded: message.forwarded,
            isReply: message.replied,
            isReplyAll: message.repliedAll,
            topic: message.subject,
            isStarred: message.starred,
            hasAttachment: message.numAttachments.intValue > 0,
            tags: message.createTags,
            messageCount: 0,
            folderIcons: message.getFolderIcons(customFolderLabels: customFolderLabels)
        )
    }

    // MARK: Action bar / sheet related
    // TODO: This is quite overlap what we did in MailboxVC, try to share the logic
    func isSelected(messageID: String) -> Bool {
        self.selectedIDs.contains(messageID)
    }

    func addSelected(messageID: String) {
        self.selectedIDs.insert(messageID)
    }

    func removeSelected(messageID: String) {
        self.selectedIDs.remove(messageID)
    }

    func removeAllSelectedIDs() {
        self.selectedIDs.removeAll()
    }

    func getActionTypes() -> [MailboxViewModel.ActionTypes] {
        // Follow all mail folder
        return [.trash, .readUnread, .moveTo, .labelAs, .more]
    }
    
    func getActionSheetViewModel() -> MailListActionSheetViewModel {
        return .init(labelId: labelID,
                     title: .actionSheetTitle(selectedCount: selectedIDs.count,
                                              viewMode: .singleMessage))
    }
    
    func handleBarActions(_ action: MailboxViewModel.ActionTypes) {
        let ids = NSMutableSet(set: self.selectedIDs)
        switch action {
        case .readUnread:
            //if all unread -> read
            //if all read -> unread
            //if mixed read and unread -> unread
            let isAnyReadMessage = checkToUseReadOrUnreadAction(messageIDs: ids, labelID: labelID)
            self.mark(IDs: ids, unread: isAnyReadMessage)
        case .trash:
            self.move(toLabel: .trash)
        case .delete:
            self.delete(IDs: ids)
        case .moveTo, .labelAs, .more, .reply, .replyAll:
            break
        }
    }

    func deleteSelectedMessage() {
        guard let ids = self.selectedIDs as? NSMutableSet else { return }
        self.delete(IDs: ids)
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
            self.move(toLabel: .trash)
        case .moveToArchive:
            self.move(toLabel: .archive)
        case .moveToSpam:
            self.move(toLabel: .spam)
        case .dismiss, .delete, .labelAs, .moveTo:
            break
        case .moveToInbox:
            self.move(toLabel: .inbox)
        }
    }

    func getFolderMenuItems() -> [MenuLabel] {
        let defaultItems = [
            MenuLabel(location: .inbox),
            MenuLabel(location: .archive),
            MenuLabel(location: .spam),
            MenuLabel(location: .trash)
        ]

        let foldersController = user.labelService.fetchedResultsController(.folderWithInbox)
        try? foldersController?.performFetch()
        let folders = (foldersController?.fetchedObjects as? [Label]) ?? []
        let datas: [MenuLabel] = Array(labels: folders, previousRawData: [])
        let (_, folderItems) = datas.sortoutData()
        return defaultItems + folderItems
    }
}

// MARK: Action bar / sheet related
// TODO: This is quite overlap what we did in MailboxVC, try to share the logic
extension SearchViewModel: MoveToActionSheetProtocol {
    var labelId: String {
        self.labelID
    }
    
    func handleMoveToAction(messages: [Message]) {
        guard let destination = selectedMoveToFolder else { return }
        messageService.move(messages: messages, to: destination.location.labelID, queue: true)
        selectedMoveToFolder = nil
    }

    func handleMoveToAction(conversations: [Conversation]) {
        // search view doesn't support conversation mode
    }
}

// MARK: Action bar / sheet related
// TODO: This is quite overlap what we did in MailboxVC, try to share the logic
extension SearchViewModel: LabelAsActionSheetProtocol {
    func handleLabelAsAction(messages: [Message], shouldArchive: Bool, currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) {
        for (label, markType) in currentOptionsStatus {
            if selectedLabelAsLabels
                .contains(where: { $0.labelID == label.location.labelID}) {
                // Add to message which does not have this label
                let messageToApply = messages.filter({ !$0.contains(label: label.location.labelID )})
                messageService.label(messages: messageToApply,
                                     label: label.location.labelID,
                                     apply: true,
                                     shouldFetchEvent: false)
            } else if markType != .dash { // Ignore the option in dash
                let messageToRemove = messages.filter({ $0.contains(label: label.location.labelID )})
                messageService.label(messages: messageToRemove,
                                     label: label.location.labelID,
                                     apply: false,
                                     shouldFetchEvent: false)
            }
        }

        user.eventsService.fetchEvents(labelID: labelID)

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            messageService.move(messages: messages,
                                to: Message.Location.archive.rawValue,
                                queue: true)
        }
    }
    
    func handleLabelAsAction(conversations: [Conversation], shouldArchive: Bool, currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) {
        // search view doesn't support conversation mode
    }
}

// MARK: Action bar / sheet related
// TODO: This is quite overlap what we did in MailboxVC, try to share the logic
extension SearchViewModel {
    private func reloadSelectedCells() {
        let rows = self.selectedIDs
            .compactMap { [weak self] messageID -> Int? in
                guard let index = self?.messages
                        .firstIndex(where: { $0.messageID == messageID }) else {
                    return nil
                }
                return index
            }
        // anson todo the context
        let context = self.coreDataService.operationContext
        context.performAndWait { [weak self] in
            for index in rows {
                guard let selectedMessage = self?.messages[safe: index],
                      let dbMessage = try? context.existingObject(with: selectedMessage.objectID) as? Message else {
                    continue
                }
                self?.messages[index] = dbMessage
            }
        }
    }

    private func checkToUseReadOrUnreadAction(messageIDs: NSMutableSet, labelID: String) -> Bool {
        var readCount = 0
        coreDataService.mainContext.performAndWait {
            let messages = self.messageService.fetchMessages(withIDs: messageIDs, in: coreDataService.mainContext)
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

    private func mark(IDs messageIDs : NSMutableSet, unread: Bool) {
        let messages = self.messageService.fetchMessages(withIDs: messageIDs, in: coreDataService.mainContext)
        messageService.mark(messages: messages, labelID: self.labelID, unRead: unread)
        self.reloadSelectedCells()
    }
    
    private func move(toLabel: Message.Location) {
        let messageIDs = NSMutableSet(set: selectedIDs)
        let messages = self.messageService.fetchMessages(withIDs: messageIDs, in: coreDataService.mainContext)
        var fLabels: [String] = []
        for msg in messages {
            // the label that is not draft, sent, starred, allmail
            fLabels.append(msg.firstValidFolder() ?? self.labelID)
        }
        messageService.move(messages: messages, from: fLabels, to: toLabel.rawValue)
        self.reloadSelectedCells()
    }
    
    private func delete(IDs: NSMutableSet) {
        let messages = self.messageService.fetchMessages(withIDs: IDs, in: coreDataService.mainContext)
        for msg in messages {
            let _ = self.delete(message: msg)
        }
    }

    private func delete(message: Message) -> (SwipeResponse, UndoMessage?) {
        if messageService.move(messages: [message], from: [self.labelID], to: Message.Location.trash.rawValue) {
            return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: self.labelID, origHasStar: message.starred, newLabels: Message.Location.trash.rawValue))
        }
        return (.nothing, nil)
    }

    private func label(IDs messageIDs : NSMutableSet, with labelID: String, apply: Bool) {
        let messages = self.messageService.fetchMessages(withIDs: messageIDs, in: coreDataService.mainContext)
        messageService.label(messages: messages, label: labelID, apply: apply)
        self.reloadSelectedCells()
    }

    private func handleUnstarAction() {
        let starredItemsIds = selectedMessages
            .filter { $0.starred }
            .map(\.messageID)
        label(IDs: NSMutableSet(array: starredItemsIds), with: Message.Location.starred.rawValue, apply: false)
    }

    private func handleStarAction() {
        let unstarredItemsIds = selectedMessages
            .filter { !$0.starred }
            .map(\.messageID)
        label(IDs: NSMutableSet(array: unstarredItemsIds), with: Message.Location.starred.rawValue, apply: true)
    }

    private func handleMarkReadAction() {
        let unreadItemsIds = selectedMessages
            .filter { $0.unRead }
            .map(\.messageID)
        mark(IDs: NSMutableSet(array: unreadItemsIds), unread: false)
    }

    private func handleMarkUnreadAction() {
        let unreadItemsIds = selectedMessages
            .filter { !$0.unRead }
            .map(\.messageID)
        mark(IDs: NSMutableSet(array: unreadItemsIds), unread: true)
    }
}

extension SearchViewModel {
    private func indexLocalObjects(_ completion: @escaping ()->Void) {
        let context = self.coreDataService.operationContext
        var count = 0
        context.performAndWait {
            do {
                let overallCountRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: Message.Attributes.entityName)
                overallCountRequest.resultType = .countResultType
                overallCountRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.userID, self.user.userinfo.userId)
                let result = try context.fetch(overallCountRequest)
                count = (result.first as? Int) ?? 1
            } catch let error {
                PMLog.D(" performFetch error: \(error)")
                assert(false, "Failed to fetch message dicts")
            }
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.userID, self.user.userinfo.userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false), NSSortDescriptor(key: #keyPath(Message.order), ascending: true)]
        fetchRequest.resultType = .dictionaryResultType

        let objectId = NSExpressionDescription()
        objectId.name = "objectID"
        objectId.expression = NSExpression.expressionForEvaluatedObject()
        objectId.expressionResultType = NSAttributeType.objectIDAttributeType
        
        fetchRequest.propertiesToFetch = [objectId,
                                          Message.Attributes.title,
                                          Message.Attributes.sender,
                                          Message.Attributes.toList]
        let async = NSAsynchronousFetchRequest(fetchRequest: fetchRequest, completionBlock: { [weak self] result in
            self?.dbContents = result.finalResult as? Array<LocalObjectsIndexRow> ?? []
            self?.localObjectsIndexingObserver = nil
            completion()
        })
        
        context.perform {
            self.localObjectIndexing.becomeCurrent(withPendingUnitCount: 1)
            guard let indexRaw = try? context.execute(async),
                let index = indexRaw as? NSPersistentStoreAsynchronousResult else
            {
                self.localObjectIndexing.resignCurrent()
                return
            }
            
            self.localObjectIndexing.resignCurrent()
            self.localObjectsIndexingObserver = index.progress?.observe(\Progress.completedUnitCount, options: NSKeyValueObservingOptions.new, changeHandler: { [weak self] (progress, change) in
                DispatchQueue.main.async {
                    let completionRate = Float(progress.completedUnitCount) / Float(count)
                    self?.uiDelegate?.update(progress: completionRate)
                }
            })
        }
    }
    
    private func fetchLocalObjects() {
        // TODO: this filter can be better. Can we lowercase and glue together all the strings via NSExpression during fetch?
        let messageIds: [NSManagedObjectID] = self.dbContents.compactMap {
            if let title = $0["title"] as? String,
                let _ = title.range(of: self.query, options: [.caseInsensitive, .diacriticInsensitive])
            {
                return $0["objectID"] as? NSManagedObjectID
            }
            if let senderName = $0["senderName"]  as? String,
                let _ = senderName.range(of: self.query, options: [.caseInsensitive, .diacriticInsensitive])
            {
                return $0["objectID"] as? NSManagedObjectID
            }
            if let sender = $0["sender"]  as? String,
                let _ = sender.range(of: self.query, options: [.caseInsensitive, .diacriticInsensitive])
            {
                return $0["objectID"] as? NSManagedObjectID
            }
            if let toList = $0["toList"]  as? String,
                let _ = toList.range(of: self.query, options: [.caseInsensitive, .diacriticInsensitive])
            {
                return $0["objectID"] as? NSManagedObjectID
            }
            return nil
        }
        
        let context = self.coreDataService.mainContext
        context.performAndWait {
            let messages = messageIds.compactMap { oldId -> Message? in
                let uri = oldId.uriRepresentation() // cuz contexts have different persistent store coordinators
                guard let newId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                    return nil
                }
                return context.object(with: newId) as? Message
            }
            self.messages = messages
        }
    }

    private func date(of message: Message, weekStart: WeekStart) -> String {
        guard let date = message.time else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }
}
