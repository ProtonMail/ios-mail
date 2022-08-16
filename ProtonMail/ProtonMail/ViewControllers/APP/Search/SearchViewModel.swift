// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CoreData
import Foundation
import ProtonCore_DataModel
import ProtonCore_UIFoundations

protocol SearchVMProtocol: AnyObject {
    var user: UserManager { get }
    var messages: [MessageEntity] { get }
    var selectedIDs: Set<String> { get }
    var selectedMessages: [MessageEntity] { get }
    var labelID: LabelID { get }
    var viewMode: ViewMode { get }
    var uiDelegate: SearchViewUIProtocol? { get set }

    func viewDidLoad()
    func cleanLocalIndex()
    func fetchRemoteData(query: String, fromStart: Bool, forceSearchOnServer: Bool)
    func loadMoreDataIfNeeded(currentRow: Int)
    func fetchMessageDetail(message: MessageEntity,
                            completeHandler: @escaping ((NSError?) -> Void))
    func getComposeViewModel(message: MessageEntity) -> ContainableComposeViewModel?
    func getComposeViewModel(by msgID: MessageID, isEditingScheduleMsg: Bool) -> ContainableComposeViewModel?
    func getMessageCellViewModel(message: MessageEntity) -> NewMailboxMessageViewModel
    func cleanExistingSearchResults()

    // Select / action bar / action sheet related
    func isSelected(messageID: String) -> Bool
    func addSelected(messageID: String)
    func removeSelected(messageID: String)
    func removeAllSelectedIDs()
    func getActionBarActions() -> [MailboxViewModel.ActionTypes]
    func getActionSheetViewModel() -> MailListActionSheetViewModel
    func handleBarActions(_ action: MailboxViewModel.ActionTypes)
    func deleteSelectedMessages()
    func handleActionSheetAction(_ action: MailListSheetAction)
    func getConversation(conversationID: ConversationID,
                         messageID: MessageID,
                         completion: @escaping (Result<ConversationEntity, Error>) -> Void)
    func scheduledMessagesFromSelected() -> [MessageEntity]
}

final class SearchViewModel: NSObject {
    typealias LocalObjectsIndexRow = [String: Any]

    let user: UserManager
    let coreDataContextProvider: CoreDataContextProviderProtocol

    weak var uiDelegate: SearchViewUIProtocol?
    private(set) var messages: [MessageEntity] = [] {
        didSet {
            assert(Thread.isMainThread)
            DispatchQueue.main.async {
                if self.messages.isEmpty == false {
                    self.uiDelegate?.activityIndicator(isAnimating: false)
                    // sort and uniquify messages
                    self.sortAndUniquifyMessageArray(messagesToInsert: [])
                }
                self.uiDelegate?.reloadTable()
            }
        }
    }

    private(set) var selectedIDs: Set<String> = []
    private var fetchController: NSFetchedResultsController<Message>?
    private var messageService: MessageDataService { self.user.messageService }
    private let localObjectIndexing: Progress = Progress(totalUnitCount: 1)
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

    var selectedConversations: [Conversation] { [] }

    var slowSearch: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.uiDelegate?.showSlowSearchBanner()
            }
        }
    }
    var encryptedSearchIndexingComplete: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.uiDelegate?.removeSearchInfoBanner()
            }
        }
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

    func fetchRemoteData(query: String, fromStart: Bool, forceSearchOnServer: Bool = false) {
        if fromStart {
            self.messages = []
            // Display spinner until search results are there
            DispatchQueue.main.async {
                self.uiDelegate?.activityIndicator(isAnimating: true)
            }
        }

        // Set query and page to load
        self.query = query
        let pageToLoad = fromStart ? 0: self.currentPage + 1

        // Save query for keyword highlighting
        EncryptedSearchService.shared.setSearchQueryForServerSearchKeywordHighlighting(query: query)

        // Prepare search for encrypted search
        if UserInfo.isEncryptedSearchEnabledPaidUsers || UserInfo.isEncryptedSearchEnabledFreeUsers {
            let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
            if let userID = usersManager.firstUser?.userInfo.userId {
                let expectedESStates: [EncryptedSearchService.EncryptedSearchIndexState] =
                [.complete, .partial, .lowstorage]
                if userCachedStatus.isEncryptedSearchOn &&
                    forceSearchOnServer == false &&
                    expectedESStates.contains(EncryptedSearchService.shared.getESState(userID: userID)) {
                    if fromStart {
                        EncryptedSearchService.shared.isSearching = true
                        EncryptedSearchService.shared.numberOfResultsFoundBySearch = 0
                        // Clear previous search state whenever a new search is initiated
                        EncryptedSearchService.shared.clearSearchState()
                    } else {
                        if let searchState = EncryptedSearchService.shared.searchState {
                            if searchState.isComplete {
                                let numberOfPages: Int = Int(ceil(Double(
                                    EncryptedSearchService.shared.numberOfResultsFoundBySearch / EncryptedSearchService.shared.searchResultPageSize)))
                                if pageToLoad > numberOfPages {
                                    print("ES searching complete - no need to fetch futher data.")
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }

        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        if let userID = usersManager.firstUser?.userInfo.userId {
            let expectedESStates: [EncryptedSearchService.EncryptedSearchIndexState] =
            [.complete, .partial, .lowstorage]
            if (UserInfo.isEncryptedSearchEnabledPaidUsers || UserInfo.isEncryptedSearchEnabledFreeUsers) &&
                userCachedStatus.isEncryptedSearchOn &&
                forceSearchOnServer == false &&
                expectedESStates.contains(EncryptedSearchService.shared.getESState(userID: userID)) {
                self.doContentSearch(userID: userID, query: query, pageToLoad: pageToLoad)
            } else {
                self.doServerSearch(pageToLoad: pageToLoad)
            }
        } else {
            self.doServerSearch(pageToLoad: pageToLoad)
        }
    }

    private func doContentSearch(userID: String, query: String, pageToLoad: Int) {
        EncryptedSearchService.shared.search(userID: userID,
                                             query: query,
                                             page: pageToLoad,
                                             searchViewModel: self) { [weak self] (error, numberOfResults) in
            guard error == nil else {
                print(" search error: \(String(describing: error))")
                return
            }

            // Update activity indicator and resultsnotfound label only if there are 0 results
            if EncryptedSearchService.shared.isSearching == false && numberOfResults == 0 {
                DispatchQueue.main.async {
                    self?.uiDelegate?.activityIndicator(isAnimating: false)
                    self?.uiDelegate?.reloadTable()
                }
            }
        }
    }

    private func doServerSearch(pageToLoad: Int) {
        let service = user.messageService
        service.search(query, page: pageToLoad) { [weak self] result in
            DispatchQueue.main.async {
                self?.uiDelegate?.activityIndicator(isAnimating: false)
                
                guard let self = self, let newMessages = try? result.get() else {
                    if pageToLoad == 0 {
                        self?.fetchLocalObjects()
                    }
                    return
                }
                self.currentPage = pageToLoad
                
                if newMessages.isEmpty {
                    if pageToLoad == 0 {
                        self.messages = []
                    }
                    return
                }

                self.coreDataContextProvider.performOnRootSavingContext { context in
                    let newMessageEntities = newMessages.map(MessageEntity.init)
                    DispatchQueue.main.async {
                        if pageToLoad > 0 {
                            self.messages.append(contentsOf: newMessageEntities)
                        } else {
                            self.messages = newMessageEntities
                        }
                        let ids = self.messages.map(\.messageID)
                        self.updateFetchController(messageIDs: ids)
                    }
                }
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
        service.forceFetchDetailForMessage(message) { _, _, _, error in
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

    func getComposeViewModel(by msgID: MessageID, isEditingScheduleMsg: Bool) -> ContainableComposeViewModel? {
        guard let msg = Message.messageForMessageID(msgID.rawValue,
                                                    inManagedObjectContext: coreDataContextProvider.mainContext) else {
            return nil
        }
        return ContainableComposeViewModel(msg: msg,
                                           action: .openDraft,
                                           msgService: user.messageService,
                                           user: user,
                                           coreDataContextProvider: coreDataContextProvider,
                                           isEditingScheduleMsg: isEditingScheduleMsg)
    }

    func getMessageCellViewModel(message: MessageEntity) -> NewMailboxMessageViewModel {
        let replacingEmails = self.user.contactService.allEmails()
        let contactGroups = user.contactGroupService.getAllContactGroupVOs()
        let senderName = message.getSenderName(replacingEmails: replacingEmails, groupContacts: contactGroups)
        let initial = message.getInitial(senderName: senderName)
        let sender = message.getSender(senderName: senderName)
        let weekStart = user.userInfo.weekStartValue
        let customFolderLabels = user.labelService.getAllLabels(
            of: .folder,
            context: CoreDataService.shared.mainContext
        ).compactMap { LabelEntity(label: $0) }
        let isSelected = self.selectedMessages.contains(message)
        let isEditing = self.uiDelegate?.listEditing ?? false
        let style: NewMailboxMessageViewStyle = message.contains(location: .scheduled) ? .scheduled : .normal
        return .init(
            location: nil,
            isLabelLocation: true, // to show origin location icons
            style: isEditing ? .selection(isSelected: isSelected) : style,
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
            folderIcons: message.getFolderIcons(customFolderLabels: customFolderLabels),
            scheduledTime: dateForScheduled(of: message),
            isScheduledTimeInNext10Mins: false
        )
    }

    func cleanExistingSearchResults() {
        self.messages.removeAll()
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
        let isAnyMessageRead = selectionContainsReadMessages()
        return [isAnyMessageRead ? .markAsUnread : .markAsRead, .trash, .moveTo, .labelAs, .more]
    }

    func getActionSheetViewModel() -> MailListActionSheetViewModel {
        return .init(labelId: labelID.rawValue,
                     title: .actionSheetTitle(selectedCount: selectedIDs.count,
                                              viewMode: .singleMessage))
    }

    func handleBarActions(_ action: MailboxViewModel.ActionTypes) {
        switch action {
        case .markAsRead:
            self.mark(messages: selectedMessages, unread: false)
        case .markAsUnread:
            self.mark(messages: selectedMessages, unread: true)
        case .trash:
            self.move(toLabel: .trash)
        case .delete:
            self.deleteSelectedMessages()
        case .moveTo, .labelAs, .more:
            break
        }
    }

    func deleteSelectedMessages() {
        messageService.move(messages: selectedMessages,
                            from: [self.labelID],
                            to: Message.Location.trash.labelID)
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

    func getConversation(conversationID: ConversationID,
                         messageID: MessageID,
                         completion: @escaping (Result<ConversationEntity, Error>) -> Void) {
        self.user.conversationService.fetchConversation(
            with: conversationID,
            includeBodyOf: messageID,
            callOrigin: "SearchViewModel"
        ) { result in
            assert(!Thread.isMainThread)

            // if fetch was successful, then this callback has been called inside `rootSavingContext.perform` block,
            // so the conversion inside `map` can be safely performed
            let mappedResult = result.map { ConversationEntity($0) }

            DispatchQueue.main.async {
                completion(mappedResult)
            }
        }
    }

    private func dateForScheduled(of message: MessageEntity) -> String? {
        guard message.contains(location: .scheduled),
              let date = message.time else { return nil }
        return PMDateFormatter.shared.stringForScheduledMsg(from: date, inListView: true)
    }

    func scheduledMessagesFromSelected() -> [MessageEntity] {
        let ids = Array(selectedIDs)
        return messages
            .filter { ids.contains($0.messageID.rawValue) && $0.contains(location: .scheduled) }
    }
}

// MARK: Action bar / sheet related
// TODO: This is quite overlap what we did in MailboxVC, try to share the logic
extension SearchViewModel: MoveToActionSheetProtocol {

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
    private func selectionContainsReadMessages() -> Bool {
        selectedMessages.contains { !$0.unRead }
    }

    private func mark(messages: [MessageEntity], unread: Bool) {
        messageService.mark(messages: messages, labelID: self.labelID, unRead: unread)
    }

    private func move(toLabel: Message.Location) {
        let messages = selectedMessages
        var fLabels: [LabelID] = []
        for msg in messages {
            // the label that is not draft, sent, starred, allmail
            fLabels.append(msg.firstValidFolder() ?? self.labelID)
        }
        messageService.move(messages: messages, from: fLabels, to: toLabel.labelID)
    }

    private func label(messages: [MessageEntity], with labelID: LabelID, apply: Bool) {
        messageService.label(messages: messages, label: labelID, apply: apply)
    }

    private func handleUnstarAction() {
        let selectedStarredMessages = selectedMessages
            .filter { $0.isStarred }
        label(messages: selectedStarredMessages, with: Message.Location.starred.labelID, apply: false)
    }

    private func handleStarAction() {
        let selectedUnstarredMessages = selectedMessages
            .filter { !$0.isStarred }
        label(messages: selectedUnstarredMessages, with: Message.Location.starred.labelID, apply: true)
    }

    private func handleMarkReadAction() {
        let selectedUnreadMessages = selectedMessages
            .filter { $0.unRead }
        mark(messages: selectedUnreadMessages, unread: false)
    }

    private func handleMarkUnreadAction() {
        let selectedReadMessages = selectedMessages
            .filter { !$0.unRead }
        mark(messages: selectedReadMessages, unread: true)
    }
}

extension SearchViewModel {
    // swiftlint:disable function_body_length
    private func indexLocalObjects(_ completion: @escaping () -> Void) {
        var count = 0
        coreDataContextProvider.performAndWaitOnRootSavingContext { context in
            let overallCountRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            overallCountRequest.resultType = .countResultType
            overallCountRequest.predicate = NSPredicate(format: "%K == %@",
                                                        Message.Attributes.userID,
                                                        self.user.userInfo.userId)
            do {
                let result = try context.fetch(overallCountRequest)
                count = (result.first as? Int) ?? 1
            } catch {
                assert(false, "Failed to fetch message dicts")
            }
        }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.userID, self.user.userInfo.userId)
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
            completion()
        })

        coreDataContextProvider.performOnRootSavingContext { context in
            self.localObjectIndexing.becomeCurrent(withPendingUnitCount: 1)
            guard let indexRaw = try? context.execute(async),
                  let _ = indexRaw as? NSPersistentStoreAsynchronousResult else {
                self.localObjectIndexing.resignCurrent()
                return
            }

            self.localObjectIndexing.resignCurrent()
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
            self.messages = messageIds.compactMap { oldId -> Message? in
                let uri = oldId.uriRepresentation() // cuz contexts have different persistent store coordinators
                guard let newId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                    return nil
                }
                return context.object(with: newId) as? Message
            }.map(MessageEntity.init)
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
        self.uiDelegate?.refreshActionBarItems()
    }
}

extension SearchViewModel {
    func displayIntermediateSearchResults(messageBoxes: [MessageEntity]?, currentPage: Int) {
        guard let messageBoxes = messageBoxes else {
            print("search error!")
            if currentPage == 0 {
                self.fetchLocalObjects()
            }
            return
        }
        DispatchQueue.main.async {
            self.uiDelegate?.activityIndicator(isAnimating: false)
        }

        self.currentPage = currentPage

        if messageBoxes.isEmpty {
            if currentPage == 0 {
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
            self?.sortAndUniquifyMessageArray(messagesToInsert: messagesInContext)
            let ids = self?.messages.map{ $0.messageID } ?? []
            self?.updateFetchController(messageIDs: ids)
        }
    }

    private func sortAndUniquifyMessageArray(messagesToInsert: [MessageEntity]) {
        var messagesToSort: [MessageEntity] = self.messages
        messagesToSort.append(contentsOf: messagesToInsert)
        let uniqueMessagesSet = Set(messagesToSort)
        // sort messages if new messages have been added
        if uniqueMessagesSet.count > self.messages.count {
            self.messages = uniqueMessagesSet.sorted { $0.time! > $1.time! }
        }
    }
}
