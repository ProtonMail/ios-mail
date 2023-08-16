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
    func fetchRemoteData(query: String, fromStart: Bool)
    func loadMoreDataIfNeeded(currentRow: Int)
    func fetchMessageDetail(message: MessageEntity, callback: @escaping FetchMessageDetailUseCase.Callback)
    func getMessageObject(message: MessageEntity) -> Message?
    func getMessageObject(by msgID: MessageID) -> Message?
    func getMessageCellViewModel(message: MessageEntity) -> NewMailboxMessageViewModel

    // Select / action bar / action sheet related
    func isSelected(messageID: String) -> Bool
    func addSelected(messageID: String)
    func removeSelected(messageID: String)
    func removeAllSelectedIDs()
    func getActionBarActions() -> [MessageViewActionSheetAction]
    func getActionSheetViewModel() -> MailListActionSheetViewModel
    func handleBarActions(_ action: MessageViewActionSheetAction)
    func deleteSelectedMessages()
    func handleActionSheetAction(_ action: MessageViewActionSheetAction)
    func getConversation(conversationID: ConversationID,
                         messageID: MessageID,
                         completion: @escaping (Result<ConversationEntity, Error>) -> Void)
    func scheduledMessagesFromSelected() -> [MessageEntity]
    func fetchSenderImageIfNeeded(
        item: MailboxItem,
        isDarkMode: Bool,
        scale: CGFloat,
        completion: @escaping (UIImage?) -> Void
    )
}

final class SearchViewModel: NSObject {
    typealias Dependencies = HasSearchUseCase
    & HasFetchMessageDetail
    & HasFetchSenderImage
    & HasUserManager
    & HasCoreDataContextProviderProtocol

    typealias LocalObjectsIndexRow = [String: Any]

    private let dependencies: Dependencies
    let user: UserManager

    weak var uiDelegate: SearchViewUIProtocol?
    private(set) var messageIDs = Set<MessageID>()
    private(set) var messages: [MessageEntity] = [] {
        didSet {
            messageIDs = Set(messages.map(\.messageID))
            assert(Thread.isMainThread)
            uiDelegate?.reloadTable()
        }
    }

    private(set) var selectedIDs: Set<String> = []
    private var fetchController: NSFetchedResultsController<Message>?
    private var messageService: MessageDataService { self.user.messageService }
    private let localObjectIndexing: Progress = .init(totalUnitCount: 1)
    private var localObjectsIndexingObserver: NSKeyValueObservation? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                let isHidden = self?.localObjectsIndexingObserver == nil
                self?.uiDelegate?.setupProgressBar(isHidden: isHidden)
            }
        }
    }

    private var dbContents: [LocalObjectsIndexRow] = []
    private var query = ""
    private let sharedReplacingEmailsMap: [String: EmailEntity]

    var selectedLabelAsLabels: Set<LabelLocation> = Set()
    var labelID: LabelID { Message.Location.allmail.labelID }
    var viewMode: ViewMode { self.user.getCurrentViewMode() }
    var selectedMessages: [MessageEntity] {
        self.messages.filter { selectedIDs.contains($0.messageID.rawValue) }
    }

    private var currentFetchedSearchResultPage: UInt = 0
    /// use this flag to stop the search query being triggered by `loadMoreDataIfNeeded`.
    private(set) var searchIsDone = false

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        user = dependencies.user
        self.sharedReplacingEmailsMap = user.contactService.allAccountEmails()
            .reduce(into: [:]) { partialResult, email in
                partialResult[email.email] = EmailEntity(email: email)
            }
    }
}

extension SearchViewModel: SearchVMProtocol {
    func viewDidLoad() {
        self.indexLocalObjects { [weak self] in
            guard let self = self,
                  self.messages.isEmpty,
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

        let pageToLoad = fromStart ? 0 : self.currentFetchedSearchResultPage + 1
        if fromStart {
            searchIsDone = false
        }

        guard !searchIsDone else {
            return
        }

        dependencies.messageSearch
            .callbackOn(.main)
            .execute(
                params: .init(query: query, page: currentFetchedSearchResultPage)
            ) { [weak self] result in
                self?.uiDelegate?.activityIndicator(isAnimating: false)
                guard
                    let self = self,
                    let newMessages = try? result.get(),
                    !newMessages.isEmpty else {
                    if pageToLoad == 0 {
                        self?.fetchLocalObjects()
                    }
                    self?.searchIsDone = true
                    return
                }
                self.currentFetchedSearchResultPage = pageToLoad

                self.messages.append(
                    contentsOf: newMessages.filter { !self.messageIDs.contains($0.messageID) }
                )

                let ids = self.messages.map(\.messageID)
                self.updateFetchController(messageIDs: ids)
            }
    }

    func loadMoreDataIfNeeded(currentRow: Int) {
        if self.messages.count - 1 <= currentRow,
           !searchIsDone {
            self.fetchRemoteData(query: self.query, fromStart: false)
        }
    }

    func fetchMessageDetail(message: MessageEntity, callback: @escaping FetchMessageDetailUseCase.Callback) {
        let params: FetchMessageDetail.Params = .init(
            userID: user.userID,
            message: message
        )
        dependencies.fetchMessageDetail
            .callbackOn(.main)
            .execute(params: params, callback: callback)
    }

    func getMessageObject(message: MessageEntity) -> Message? {
        guard let msgObject = dependencies.contextProvider.mainContext
            .object(with: message.objectID.rawValue) as? Message else {
            return nil
        }
        return msgObject
    }

    func getMessageObject(by msgID: MessageID) -> Message? {
        guard let msg = Message.messageForMessageID(
            msgID.rawValue,
            inManagedObjectContext: dependencies.contextProvider.mainContext
        ) else {
            return nil
        }
        return msg
    }

    func getMessageCellViewModel(message: MessageEntity) -> NewMailboxMessageViewModel {
        let contactGroups = user.contactGroupService.getAllContactGroupVOs()
        let senderRowComponents = MailboxMessageCellHelper().senderRowComponents(
            for: message,
            basedOn: sharedReplacingEmailsMap,
            groupContacts: contactGroups
        )
        let weekStart = user.userInfo.weekStartValue
        let customFolderLabels = user.labelService.getAllLabels(of: .folder)
        let isSelected = self.selectedMessages.contains(message)
        let isEditing = self.uiDelegate?.listEditing ?? false
        let style: NewMailboxMessageViewStyle = message.contains(location: .scheduled) ? .scheduled : .normal
        return .init(
            location: nil,
            isLabelLocation: true, // to show origin location icons
            style: isEditing ? .selection(isSelected: isSelected) : style,
            initial: senderRowComponents.initials(),
            isRead: !message.unRead,
            sender: senderRowComponents,
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

    func getActionBarActions() -> [MessageViewActionSheetAction] {
        // Follow all mail folder
        let isAnyMessageRead = selectionContainsReadMessages()
        return [isAnyMessageRead ? .markUnread : .markRead, .trash, .moveTo, .labelAs, .more]
    }

    func getActionSheetViewModel() -> MailListActionSheetViewModel {
        return .init(labelId: labelID.rawValue,
                     title: .actionSheetTitle(selectedCount: selectedIDs.count,
                                              viewMode: .singleMessage))
    }

    func handleBarActions(_ action: MessageViewActionSheetAction) {
        switch action {
        case .markRead:
            self.mark(messages: selectedMessages, unread: false)
        case .markUnread:
            self.mark(messages: selectedMessages, unread: true)
        case .trash:
            self.move(toLabel: .trash)
        case .delete:
            self.deleteSelectedMessages()
        default:
            break
        }
    }

    func handleActionSheetAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .unstar:
            handleUnstarAction()
        case .star:
            handleStarAction()
        case .markRead:
            handleMarkReadAction()
        case .markUnread:
            handleMarkUnreadAction()
        case .trash:
            self.move(toLabel: .trash)
        case .archive:
            self.move(toLabel: .archive)
        case .spam:
            self.move(toLabel: .spam)
        case .dismiss, .delete, .labelAs, .moveTo:
            break
        case .inbox:
            self.move(toLabel: .inbox)
        case .toolbarCustomization:
            // TODO: Add implementation
            break
        case .reply, .replyAll, .forward, .print, .viewHeaders, .viewHTML, .reportPhishing, .spamMoveToInbox, .viewInDarkMode, .viewInLightMode, .more, .replyOrReplyAll, .saveAsPDF, .replyInConversation, .forwardInConversation, .replyOrReplyAllInConversation, .replyAllInConversation:
            break
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

    func deleteSelectedMessages() {
        messageService.move(messages: selectedMessages,
                            from: [self.labelID],
                            to: Message.Location.trash.labelID)
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
}

// MARK: Action bar / sheet related

// TODO: This is quite overlap what we did in MailboxVC, try to share the logic
extension SearchViewModel: MoveToActionSheetProtocol {
    func handleMoveToAction(conversations: [ConversationEntity], to folder: MenuLabel, isFromSwipeAction: Bool, completion: (() -> Void)?) {
        // search view doesn't support conversation mode
    }

    func handleMoveToAction(messages: [MessageEntity], to folder: MenuLabel, isFromSwipeAction: Bool) {
        messageService.move(messages: messages, to: folder.location.labelID, queue: true)
    }
}

// MARK: Action bar / sheet related

// TODO: This is quite overlap what we did in MailboxVC, try to share the logic
extension SearchViewModel: LabelAsActionSheetProtocol {
    func handleLabelAsAction(messages: [MessageEntity],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetItem.MarkType]) {
        for (label, markType) in currentOptionsStatus {
            if selectedLabelAsLabels
                .contains(where: { $0.rawLabelID == label.location.rawLabelID }) {
                // Add to message which does not have this label
                let messageToApply = messages.filter { !$0.contains(location: label.location) }
                messageService.label(messages: messageToApply,
                                     label: label.location.labelID,
                                     apply: true,
                                     shouldFetchEvent: false)
            } else if markType != .dash { // Ignore the option in dash
                let messageToRemove = messages.filter { $0.contains(location: label.location) }
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
                             currentOptionsStatus: [MenuLabel: PMActionSheetItem.MarkType],
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
        messageService.mark(messageObjectIDs: messages.map(\.objectID.rawValue), labelID: self.labelID, unRead: unread)
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
        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            let overallCountRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            overallCountRequest.resultType = .countResultType
            overallCountRequest.predicate = NSPredicate(format: "%K == %@",
                                                        Message.Attributes.userID,
                                                        self.user.userInfo.userId)
            do {
                let result = try context.fetch(overallCountRequest)
                count = (result.first as? Int) ?? 1
            } catch {
                assertionFailure("Failed to fetch message dicts")
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
            self?.localObjectsIndexingObserver = nil
            completion()
        })

        dependencies.contextProvider.performOnRootSavingContext { context in
            self.localObjectIndexing.becomeCurrent(withPendingUnitCount: 1)
            guard let indexRaw = try? context.execute(async),
                  let index = indexRaw as? NSPersistentStoreAsynchronousResult else {
                self.localObjectIndexing.resignCurrent()
                return
            }

            self.localObjectIndexing.resignCurrent()
            self.localObjectsIndexingObserver = index.progress?.observe(
                \Progress.completedUnitCount,
                options: NSKeyValueObservingOptions.new
            ) { [weak self] progress, _ in
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

        let context = dependencies.contextProvider.mainContext
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

        let context = dependencies.contextProvider.mainContext
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
        } catch {}
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
