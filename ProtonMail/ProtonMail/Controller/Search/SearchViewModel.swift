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
    var messages: [MessageEntity] { get }
    var selectedIDs: Set<String> { get }
    var selectedMessages: [MessageEntity] { get }
    var labelID: LabelID { get }
    var viewMode: ViewMode { get }

    func viewDidLoad()
    func cleanLocalIndex()
    func fetchRemoteData(query: String, fromStart: Bool)
    func loadMoreDataIfNeeded(currentRow: Int)
    func fetchMessageDetail(message: MessageEntity,
                            completeHandler: @escaping ((NSError?) -> Void))
    func getComposeViewModel(message: MessageEntity) -> ContainableComposeViewModel?
    func getMessageCellViewModel(message: MessageEntity) -> NewMailboxMessageViewModel

    // Select / action bar / action sheet related
    // TODO: The logic is quite similar what we did in mailBoxVC, try to share the logic
    func isSelected(messageID: String) -> Bool
    func addSelected(messageID: String)
    func removeSelected(messageID: String)
    func removeAllSelectedIDs()
    func getActionBarActions() -> [MailboxViewModel.ActionTypes]
    func getActionSheetViewModel() -> MailListActionSheetViewModel
    func handleBarActions(_ action: MailboxViewModel.ActionTypes)
    func deleteSelectedMessage()
    func handleActionSheetAction(_ action: MailListSheetAction)
    func getFolderMenuItems() -> [MenuLabel]
    func getConversation(conversationID: ConversationID,
                         messageID: MessageID,
                         completion: @escaping (Result<ConversationEntity, Error>) -> Void)
}

final class SearchViewModel: NSObject {
    typealias LocalObjectsIndexRow = [String: Any]

    let user: UserManager
    let coreDataContextProvider: CoreDataContextProviderProtocol

    weak var uiDelegate: SearchViewUIProtocol?
    private(set) var messages: [MessageEntity] = [] {
        didSet {
            DispatchQueue.main.async {
                self.uiDelegate?.reloadTable()
            }
        }
    }
    private var groupContacts: [ContactGroupVO] {
        self.user.contactGroupService.getAllContactGroupVOs()
    }
    private(set) var selectedIDs: Set<String> = []
    private var fetchController: NSFetchedResultsController<Message>?
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
    private var dbContents: [LocalObjectsIndexRow] = []
    private var currentPage = 0
    private var query = ""

    var selectedMoveToFolder: MenuLabel?
    var selectedLabelAsLabels: Set<LabelLocation> = Set()
    var labelID: LabelID { Message.Location.allmail.labelID }
    var viewMode: ViewMode { self.user.getCurrentViewMode() }
    var selectedMessages: [MessageEntity] {
        self.messages.filter { selectedIDs.contains($0.messageID.rawValue) }
    }

    init(user: UserManager,
         coreDataContextProvider: CoreDataContextProviderProtocol) {
        self.user = user
        self.coreDataContextProvider = coreDataContextProvider
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
        self.fetchController?.delegate = nil
        self.fetchController = nil
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

            let context = self.coreDataContextProvider.mainContext
            context.perform { [weak self] in
                let messagesInContext = messageBoxes
                    .compactMap { context.object(with: $0.objectID.rawValue) as? Message }
                    .filter { $0.managedObjectContext != nil }
                    .map(MessageEntity.init)
                if pageToLoad > 0 {
                    self?.messages.append(contentsOf: messagesInContext)
                } else {
                    self?.messages = messagesInContext
                }
                let ids = self?.messages.map { $0.messageID } ?? []
                self?.updateFetchController(messageIDs: ids)
            }
        }
    }

    func loadMoreDataIfNeeded(currentRow: Int) {
        if self.messages.count - 1 <= currentRow {
            self.fetchRemoteData(query: self.query, fromStart: false)
        }
    }

    func fetchMessageDetail(message: MessageEntity, completeHandler: @escaping ((NSError?) -> Void)) {
        let service = self.user.messageService
        service.ForcefetchDetailForMessage(message) { _, _, _, error in
            completeHandler(error)
        }
    }

    func getComposeViewModel(message: MessageEntity) -> ContainableComposeViewModel? {
        guard let msgObject = coreDataContextProvider.mainContext
                .object(with: message.objectID.rawValue) as? Message else {
            return nil
        }
        return ContainableComposeViewModel(msg: msgObject,
                                           action: .openDraft,
                                           msgService: user.messageService,
                                           user: user,
                                           coreDataContextProvider: coreDataContextProvider)
    }

    func getMessageCellViewModel(message: MessageEntity) -> NewMailboxMessageViewModel {
        let replacingEmails = self.user.contactService.allEmails()
        let initial = message.getInitial(replacingEmails: replacingEmails,
                                         groupContacts: groupContacts)
        let sender = message.getSender(replacingEmails: replacingEmails,
                                       groupContacts: groupContacts)
        let weekStart = user.userInfo.weekStartValue
        let customFolderLabels = user.labelService.getAllLabels(
            of: .folder,
            context: CoreDataService.shared.mainContext
        ).compactMap { LabelEntity(label: $0) }
        let isSelected = self.selectedMessages.contains(message)
        let isEditing = self.uiDelegate?.listEditing ?? false
        return .init(
            location: nil,
            isLabelLocation: true, // to show origin location icons
            style: isEditing ? .selection(isSelected: isSelected) : .normal,
            initial: initial.apply(style: FontManager.body3RegularNorm),
            isRead: !message.unRead,
            sender: sender,
            time: date(of: message, weekStart: weekStart),
            isForwarded: message.isForwarded,
            isReply: message.isReplied,
            isReplyAll: message.isRepliedAll,
            topic: message.title,
            isStarred: message.isStarred,
            hasAttachment: message.numAttachments > 0,
            tags: message.createTags(),
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

    func getActionBarActions() -> [MailboxViewModel.ActionTypes] {
        // Follow all mail folder
        let isAnyMessageRead = containsReadMessages(messageIDs: NSMutableSet(set: selectedIDs), labelID: labelID.rawValue)
        return [isAnyMessageRead ? .markAsUnread : .markAsRead, .trash, .moveTo, .labelAs, .more]
    }

    func getActionSheetViewModel() -> MailListActionSheetViewModel {
        return .init(labelId: labelID.rawValue,
                     title: .actionSheetTitle(selectedCount: selectedIDs.count,
                                              viewMode: .singleMessage))
    }

    func handleBarActions(_ action: MailboxViewModel.ActionTypes) {
        let ids = NSMutableSet(set: self.selectedIDs)
        switch action {
        case .markAsRead:
            self.mark(IDs: ids, unread: false)
        case .markAsUnread:
            self.mark(IDs: ids, unread: true)
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
        let folders = (foldersController?.fetchedObjects as? [Label])?.compactMap({ LabelEntity(label: $0) }) ?? []
        let datas: [MenuLabel] = Array(labels: folders, previousRawData: [])
        let (_, folderItems) = datas.sortoutData()
        return defaultItems + folderItems
    }

    func getConversation(conversationID: ConversationID,
                         messageID: MessageID,
                         completion: @escaping (Result<ConversationEntity, Error>) -> Void) {
        self.user.conversationService.fetchConversation(
            with: conversationID,
            includeBodyOf: messageID,
            callOrigin: "SearchViewModel"
        )  { result in
            switch result {
            case .success(let conversation):
                completion(.success(ConversationEntity(conversation)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: Action bar / sheet related
// TODO: This is quite overlap what we did in MailboxVC, try to share the logic
extension SearchViewModel: MoveToActionSheetProtocol {
    var labelId: LabelID {
        self.labelID
    }

    func handleMoveToAction(messages: [MessageEntity], isFromSwipeAction: Bool) {
        guard let destination = selectedMoveToFolder else { return }
        messageService.move(messages: messages, to: destination.location.labelID, queue: true)
        selectedMoveToFolder = nil
    }

    func handleMoveToAction(conversations: [ConversationEntity],
                            isFromSwipeAction: Bool,
                            completion: (() -> Void)? = nil) {
        // search view doesn't support conversation mode
    }
}

// MARK: Action bar / sheet related
// TODO: This is quite overlap what we did in MailboxVC, try to share the logic
extension SearchViewModel: LabelAsActionSheetProtocol {
    func handleLabelAsAction(messages: [MessageEntity],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) {
        for (label, markType) in currentOptionsStatus {
            if selectedLabelAsLabels
                .contains(where: { $0.rawLabelID == label.location.rawLabelID }) {
                // Add to message which does not have this label
                let messageToApply = messages.filter({ !$0.contains(location: label.location) })
                messageService.label(messages: messageToApply,
                                     label: label.location.labelID,
                                     apply: true,
                                     shouldFetchEvent: false)
            } else if markType != .dash { // Ignore the option in dash
                let messageToRemove = messages.filter({ $0.contains(location: label.location) })
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
                                to: Message.Location.archive.labelID,
                                queue: true)
        }
    }

    func handleLabelAsAction(conversations: [ConversationEntity],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType],
                             completion: (() -> Void)?) {
        // search view doesn't support conversation mode
        fatalError("not implemented")
    }
}

// MARK: Action bar / sheet related
extension SearchViewModel {
    private func containsReadMessages(messageIDs: NSMutableSet, labelID: String) -> Bool {
        var readCount = 0
        coreDataContextProvider.mainContext.performAndWait {
            let messages = self.messageService.fetchMessages(withIDs: messageIDs,
                                                             in: coreDataContextProvider.mainContext)
            readCount = messages.reduce(0) { result, next -> Int in
                if next.unRead == false {
                    return result + 1
                } else {
                    return result
                }
            }
        }
        return readCount > 0
    }

    private func mark(IDs messageIDs: NSMutableSet, unread: Bool) {
        let messages = self.messageService.fetchMessages(withIDs: messageIDs, in: coreDataContextProvider.mainContext)
        messageService.mark(messages: messages.map(MessageEntity.init), labelID: self.labelID, unRead: unread)
    }

    private func move(toLabel: Message.Location) {
        let messageIDs = NSMutableSet(set: selectedIDs)
        let messages = self.messageService.fetchMessages(withIDs: messageIDs, in: coreDataContextProvider.mainContext)
        var fLabels: [LabelID] = []
        for msg in messages {
            // the label that is not draft, sent, starred, allmail
            fLabels.append(LabelID(msg.firstValidFolder() ?? self.labelID.rawValue))
        }
        messageService.move(messages: messages.map(MessageEntity.init), from: fLabels, to: toLabel.labelID)
    }

    private func delete(IDs: NSMutableSet) {
        let messages = self.messageService.fetchMessages(withIDs: IDs, in: coreDataContextProvider.mainContext)
        for msg in messages {
            self.delete(message: msg)
        }
    }

    private func delete(message: Message) {
        messageService.move(messages: [message].map(MessageEntity.init),
                            from: [self.labelID],
                            to: Message.Location.trash.labelID)
    }

    private func label(IDs messageIDs: NSMutableSet, with labelID: LabelID, apply: Bool) {
        let messages = self.messageService.fetchMessages(withIDs: messageIDs,
                                                         in: coreDataContextProvider.mainContext)
            .map(MessageEntity.init)
        messageService.label(messages: messages, label: labelID, apply: apply)
    }

    private func handleUnstarAction() {
        let starredItemsIds = selectedMessages
            .filter { $0.isStarred }
            .map(\.messageID)
            .map(\.rawValue)
        label(IDs: NSMutableSet(array: starredItemsIds), with: Message.Location.starred.labelID, apply: false)
    }

    private func handleStarAction() {
        let unstarredItemsIds = selectedMessages
            .filter { !$0.isStarred }
            .map(\.messageID)
            .map(\.rawValue)
        label(IDs: NSMutableSet(array: unstarredItemsIds), with: Message.Location.starred.labelID, apply: true)
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
    // swiftlint:disable function_body_length
    private func indexLocalObjects(_ completion: @escaping () -> Void) {
        let context = coreDataContextProvider.rootSavingContext
        var count = 0
        context.performAndWait {
            let overallCountRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            overallCountRequest.resultType = .countResultType
            overallCountRequest.predicate = NSPredicate(format: "%K == %@",
                                                        Message.Attributes.userID,
                                                        self.user.userinfo.userId)
            do {
                let result = try context.fetch(overallCountRequest)
                count = (result.first as? Int) ?? 1
            } catch {
                assert(false, "Failed to fetch message dicts")
            }
        }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.userID, self.user.userinfo.userId)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: Message.Attributes.time, ascending: false),
            NSSortDescriptor(key: #keyPath(Message.order), ascending: true)
        ]
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
            self?.dbContents = result.finalResult as? [LocalObjectsIndexRow] ?? []
            self?.localObjectsIndexingObserver = nil
            completion()
        })

        context.perform {
            self.localObjectIndexing.becomeCurrent(withPendingUnitCount: 1)
            guard let indexRaw = try? context.execute(async),
                let index = indexRaw as? NSPersistentStoreAsynchronousResult else {
                self.localObjectIndexing.resignCurrent()
                return
            }

            self.localObjectIndexing.resignCurrent()
            self.localObjectsIndexingObserver = index.progress?.observe(
                \Progress.completedUnitCount,
                options: NSKeyValueObservingOptions.new) { [weak self] progress, _ in
                    DispatchQueue.main.async {
                        let completionRate = Float(progress.completedUnitCount) / Float(count)
                        self?.uiDelegate?.update(progress: completionRate)
                    }
            }
        }
    }

    private func fetchLocalObjects() {
        let fieldsToMatchQueryAgainst: [String] = [
            "title",
            "senderName",
            "sender",
            "toList"
        ]

        let messageIds: [NSManagedObjectID] = self.dbContents.compactMap {
            for field in fieldsToMatchQueryAgainst {
                if let value = $0[field] as? String,
                    value.range(of: self.query, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                    return $0["objectID"] as? NSManagedObjectID
                }
            }
            return nil
        }

        let context = coreDataContextProvider.mainContext
        context.performAndWait {
            let messages = messageIds.compactMap { oldId -> Message? in
                let uri = oldId.uriRepresentation() // cuz contexts have different persistent store coordinators
                guard let newId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                    return nil
                }
                return context.object(with: newId) as? Message
            }.map(MessageEntity.init)
            self.messages = messages
        }
    }

    private func updateFetchController(messageIDs: [MessageID]) {
        if let previous = self.fetchController {
            previous.delegate = nil
            self.fetchController = nil
        }

        let context = coreDataContextProvider.mainContext
        let fetchRequest = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
        let ids = messageIDs.map { $0.rawValue }
        fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, ids)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Message.time), ascending: false),
            NSSortDescriptor(key: #keyPath(Message.order), ascending: false)
        ]
        fetchRequest.includesPropertyValues = true
        self.fetchController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                          managedObjectContext: context,
                                                          sectionNameKeyPath: nil,
                                                          cacheName: nil)
        self.fetchController?.delegate = self
        do {
            try self.fetchController?.performFetch()
        } catch {
        }
    }

    private func date(of message: MessageEntity, weekStart: WeekStart) -> String {
        guard let date = message.time else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }
}

extension SearchViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let dbObjects = self.fetchController?.fetchedObjects {
            self.messages = dbObjects.map(MessageEntity.init)
        }
        self.uiDelegate?.reloadTable()
    }
}
