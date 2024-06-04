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

import Combine
import CoreData
import Foundation
import ProtonCoreDataModel
import ProtonCoreUIFoundations
import UIKit

final class SearchViewModel: NSObject, AttachmentPreviewViewModelProtocol {
    typealias Dependencies = HasSearchUseCase
    & HasFetchMessageDetailUseCase
    & HasFetchSenderImage
    & HasMailboxMessageCellHelper
    & HasUserManager
    & HasCoreDataContextProviderProtocol
    & HasFeatureFlagCache
    & HasFetchAttachmentMetadataUseCase
    & HasFetchAttachmentUseCase

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
    private var messagesPublisher: MessagesPublisher?
    private var cancellable: AnyCancellable?
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
    private var keyword = ""
    private let sharedReplacingEmailsMap: [String: EmailEntity]

    var selectedLabelAsLabels: Set<LabelLocation> = Set()
    var labelID: LabelID { Message.Location.allmail.labelID }
    var viewMode: ViewMode { self.user.conversationStateService.viewMode }
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
                partialResult[email.email] = email
            }
    }
}

extension SearchViewModel {
    func viewDidLoad() {
        indexLocalObjects {}
    }

    func cleanLocalIndex() {
        // switches off indexing of Messages in local db
        localObjectIndexing.cancel()
        cancellable?.cancel()
        messagesPublisher = nil
    }

    func fetchRemoteData(keyword: String, fromStart: Bool) {
        if fromStart {
            self.messages = []
        }
        self.uiDelegate?.activityIndicator(isAnimating: true)

        self.keyword = keyword

        let pageToLoad = fromStart ? 0 : self.currentFetchedSearchResultPage + 1
        if fromStart {
            searchIsDone = false
        }

        guard !searchIsDone else {
            return
        }

        let searchQuery = SearchMessageQuery(
            page: currentFetchedSearchResultPage,
            keyword: keyword
        )

        dependencies.messageSearch
            .callbackOn(.main)
            .execute(
                params: .init(query: searchQuery)
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
            self.fetchRemoteData(keyword: keyword, fromStart: false)
        }
    }

    func fetchMessageDetail(message: MessageEntity, callback: @escaping FetchMessageDetailUseCase.Callback) {
        let params: FetchMessageDetail.Params = .init(
            message: message
        )
        dependencies.fetchMessageDetail
            .callbackOn(.main)
            .execute(params: params, callback: callback)
    }

    func getMessageObject(by msgID: MessageID) -> MessageEntity? {
        let msg: MessageEntity? = dependencies.contextProvider.read { context in
            if let msg = Message.messageForMessageID(msgID.rawValue, in: context) {
                return MessageEntity(msg)
            } else {
                return nil
            }
        }
        return msg
    }

    func getMessageCellViewModel(message: MessageEntity) -> NewMailboxMessageViewModel {
        let contactGroups = user.contactGroupService.getAllContactGroupVOs()
        var senderRowComponents = dependencies.mailboxMessageCellHelper.senderRowComponents(
            for: message,
            basedOn: sharedReplacingEmailsMap,
            groupContacts: contactGroups,
            shouldReplaceSenderWithRecipients: true
        )
        if senderRowComponents.isEmpty {
            senderRowComponents = [.string("")]
        }
        let weekStart = user.userInfo.weekStartValue
        let customFolderLabels = user.labelService.getAllLabels(of: .folder)
        let isSelected = self.selectedMessages.contains(message)
        let isEditing = self.uiDelegate?.listEditing ?? false
        let style: NewMailboxMessageViewStyle = message.contains(location: .scheduled) ? .scheduled : .normal
        return .init(
            location: nil,
            isLabelLocation: true, // to show origin location icons
            style: isEditing ? .selection(isSelected: isSelected, isAbleToBeSelected: true) : style,
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
            isScheduledTimeInNext10Mins: false,
            attachmentsPreviewViewModels: attachmentsPreviews(for: .message(message)),
            numberOfAttachments: message.numAttachments,
            hasSnoozeLabel: message.contains(location: .snooze),
            snoozeTime: snoozeTime(of: message),
            hasShowReminderFlag: message.showReminder,
            reminderTime: dateOfReminder(of: message, weekStart: weekStart)
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
        return .init(
            labelId: labelID.rawValue,
            title: .actionSheetTitle(selectedCount: selectedIDs.count, viewMode: .singleMessage),
            locationViewMode: .singleMessage,
            isForSearch: true
        )
    }

    func handleActionSheetAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .delete:
            self.deleteSelectedMessages()
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
        case .dismiss, .labelAs, .moveTo:
            break
        case .inbox:
            self.move(toLabel: .inbox)
        case .toolbarCustomization:
            // TODO: Add implementation
            break
        case .reply, .replyAll, .forward, .print, .viewHeaders, .viewHTML, .reportPhishing, .spamMoveToInbox,
                .viewInDarkMode, .viewInLightMode, .more, .replyOrReplyAll, .saveAsPDF, .replyInConversation,
                .forwardInConversation, .replyOrReplyAllInConversation, .replyAllInConversation, .snooze:
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

    func requestPreviewOfAttachment(
        at indexPath: IndexPath,
        index: Int
    ) async throws -> SecureTemporaryFile {
        guard let message = messages[safe: indexPath.row],
              let attachmentMetadata = message.attachmentsMetadata[safe: index] else {
            throw AttachmentPreviewError.indexPathDidNotMatch
        }
        let userKeys = user.toUserKeys()

        let metadata = try await dependencies.fetchAttachmentMetadata.execution(
            params: .init(attachmentID: .init(attachmentMetadata.id))
        )
        let attachmentFile = try await dependencies.fetchAttachment.execute(
            params: .init(
                attachmentID: .init(attachmentMetadata.id),
                attachmentKeyPacket: metadata.keyPacket,
                userKeys: userKeys
            )
        )
        let fileData = attachmentFile.data
        let fileName = attachmentMetadata.name.cleaningFilename()
        let secureTempFile = SecureTemporaryFile(data: fileData, name: fileName)
        return secureTempFile
    }
}

// MARK: Action bar / sheet related

// TODO: This is quite overlap what we did in MailboxVC, try to share the logic
extension SearchViewModel: MoveToActionSheetProtocol {
    func handleMoveToAction(messages: [MessageEntity], to folder: MenuLabel) {
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
        do {
            let count = try dependencies.contextProvider.read { context in
                let overallCountRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
                overallCountRequest.resultType = .countResultType
                overallCountRequest.predicate = NSPredicate(format: "%K == %@",
                                                            Message.Attributes.userID,
                                                            self.user.userInfo.userId)
                let result = try context.fetch(overallCountRequest)
                return (result.first as? Int) ?? 1
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
            fetchRequest.propertiesToFetch = [
                objectId,
                Message.Attributes.title,
                Message.Attributes.sender,
                Message.Attributes.toList
            ]

            let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest, completionBlock: { [weak self] result in
                self?.dbContents = result.finalResult as? [LocalObjectsIndexRow] ?? []
                self?.localObjectsIndexingObserver = nil
                completion()
            })


            dependencies.contextProvider.performAndWaitOnRootSavingContext { [weak self] context in
                self?.localObjectIndexing.becomeCurrent(withPendingUnitCount: 1)
                guard let indexRaw = try? context.execute(asyncRequest),
                      let index = indexRaw as? NSPersistentStoreAsynchronousResult else {
                    self?.localObjectIndexing.resignCurrent()
                    return
                }

                self?.localObjectIndexing.resignCurrent()
                self?.localObjectsIndexingObserver = index.progress?.observe(
                    \Progress.completedUnitCount,
                    options: NSKeyValueObservingOptions.new
                ) { [weak self] progress, _ in
                    DispatchQueue.main.async {
                        let completionRate = Float(progress.completedUnitCount) / Float(count)
                        self?.uiDelegate?.update(progress: completionRate)
                    }
                }
            }
        } catch {
            PMAssertionFailure(error)
        }
    }

    private func fetchLocalObjects() {
        let fieldsToMatchQueryAgainst: [String] = [
            "title",
            "senderName",
            "sender",
            "toList"
        ]

        let messageObjectIDs: [NSManagedObjectID] = self.dbContents.compactMap {
            for field in fieldsToMatchQueryAgainst {
                guard let value = $0[field] as? String else { return nil }
                if field == "sender",
                   let sender = try? Sender.decodeDictionary(jsonString: value),
                   (sender.address.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive]) != nil ||
                    sender.name.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive]) != nil ) {
                    // For sender field, what we care is address and name
                    return $0["objectID"] as? NSManagedObjectID
                } else if value.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                    return $0["objectID"] as? NSManagedObjectID
                }
            }
            return nil
        }

        self.messages = dependencies.contextProvider.read { context in
            return messageObjectIDs.compactMap { oldId -> Message? in
                let uri = oldId.uriRepresentation()
                guard let newId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                    return nil
                }
                return context.object(with: newId) as? Message
            }.map(MessageEntity.init)
        }
    }

    private func updateFetchController(messageIDs: [MessageID]) {
        self.messagesPublisher = .init(
            messageIDs: messageIDs,
            contextProvider: dependencies.contextProvider
        )

        cancellable = messagesPublisher?.contentDidChange
            .map { $0.map(MessageEntity.init) }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] messages in
                self?.messages = messages
                self?.uiDelegate?.refreshActionBarItems()
        })
        messagesPublisher?.start()
    }

    private func date(of message: MessageEntity, weekStart: WeekStart) -> String {
        guard let date = message.time else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }

    private func snoozeTime(of message: MessageEntity) -> String? {
        guard message.contains(location: .snooze), let date = message.snoozeTime else {
            return nil
        }
        return PMDateFormatter.shared.stringForSnoozeTime(from: date)
    }

    private func dateOfReminder(of message: MessageEntity, weekStart: WeekStart) -> String? {
        guard let date = message.snoozeTime else { return nil }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }

    private func attachmentsPreviews(for mailboxItem: MailboxItem) -> [AttachmentPreviewViewModel] {
        guard dependencies.featureFlagCache.isFeatureFlag(.attachmentsPreview, enabledForUserWithID: user.userID) else {
            return []
        }
        return mailboxItem.previewableAttachments.map {
            AttachmentPreviewViewModel(
                name: $0.name,
                icon: AttachmentType(mimeType: $0.mimeType.lowercased()).icon
            )
        }
    }
}
