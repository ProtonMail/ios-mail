// Copyright (c) 2024 Proton Technologies AG
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

import proton_app_uniffi
import InboxCore
import InboxCoreUI
import SwiftUI

@MainActor
final class ConversationDetailModel: Sendable, ObservableObject {
    @Published private(set) var state: State = .initial
    @Published private(set) var seed: ConversationDetailSeed
    @Published private(set) var scrollToMessage: String? = nil
    @Published private(set) var mailbox: Mailbox?
    @Published private(set) var isStarred: Bool
    @Published private(set) var conversationToolbarActions: ConversationToolbarActions?
    @Published var actionSheets: MailboxActionSheetsState = .initial()
    @Published var editScheduledMessageConfirmationAlert: AlertModel?
    @Published var actionAlert: AlertModel?
    @Published var attachmentIDToOpen: ID?

    private var conversationItem: ConversationItem?

    let messageAppearanceOverrideStore: MessageAppearanceOverrideStore
    let messagePrinter: MessagePrinter
    private var colorScheme: ColorScheme = .light

    enum InitialConversationItem {
        case message(ID)
        case conversation(ID)
        case pushNotification(messageID: ID, conversationID: ID)
        case searchResultItem(messageID: ID, conversationID: ID)
    }

    struct ConversationItemMetadata {
        let item: InitialConversationItem
        let selectedMailbox: SelectedMailbox
    }

    func configure(colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }

    var isBottomBarHidden: Bool {
        if let conversationToolbarActions {
            seed.isOutbox || conversationToolbarActions.isEmpty
        } else {
            true
        }
    }

    var areActionsHidden: Bool {
        seed.isOutbox
    }

    var isSingleMessageMode: Bool {
        conversationItem?.itemType == .message
    }

    private var messagesLiveQuery: WatchedConversation?
    private var singleMessageLiveQuery: WatchedMessage?

    private var expandedMessages: Set<ID>
    private let draftPresenter: DraftPresenter
    private let dependencies: Dependencies
    private let backOnlineActionExecutor: BackOnlineActionExecutor
    private let snoozeService: SnoozeServiceProtocol

    private lazy var conversationMessageListCallback = LiveQueryCallbackWrapper { [weak self] in
        guard let self else { return }
        Task { @MainActor in
            let liveQueryValues = await self.readConversationLiveQueryValues()
            self.isStarred = liveQueryValues.isStarred
            self.updateStateToMessagesReady(with: liveQueryValues.messages)
            await self.reloadBottomBarActions()
        }
    }

    private lazy var singleMessageCallback = LiveQueryCallbackWrapper { [weak self] in
        guard let self else { return }
        Task { @MainActor in
            let liveQueryValues = await self.readMessageLiveQueryValues()
            self.isStarred = liveQueryValues.isStarred
            self.updateStateToMessagesReady(with: liveQueryValues.messages)
            await self.reloadBottomBarActions()
        }
    }

    private lazy var starActionPerformer = StarActionPerformer(mailUserSession: userSession)

    private var userSession: MailUserSession {
        dependencies.appContext.userSession
    }

    init(
        seed: ConversationDetailSeed,
        draftPresenter: DraftPresenter,
        dependencies: Dependencies = .init(),
        backOnlineActionExecutor: BackOnlineActionExecutor,
        snoozeService: SnoozeServiceProtocol,
        messageAppearanceOverrideStore: MessageAppearanceOverrideStore
    ) {
        self.seed = seed
        self.isStarred = seed.isStarred
        self.expandedMessages = .init()
        self.draftPresenter = draftPresenter
        self.dependencies = dependencies
        self.backOnlineActionExecutor = backOnlineActionExecutor
        self.snoozeService = snoozeService
        self.messageAppearanceOverrideStore = messageAppearanceOverrideStore
        messagePrinter = .init(userSession: { dependencies.appContext.userSession })
    }

    func fetchInitialData() async {
        updateState(.fetchingMessages)
        do {
            let metadata = try await establishConversationItemMetadata()
            let mailbox = try await initialiseMailbox(basedOn: metadata.selectedMailbox)
            self.mailbox = mailbox

            switch metadata.item {
            case .message(let id):
                try await setUpSingleMessageObservation(messageID: id)
            case .conversation(let id):
                try await setUpConversationMessagesObservation(conversationID: id, origin: .default, mailbox: mailbox)
            case .pushNotification(let messageID, let conversationID), .searchResultItem(let messageID, let conversationID):
                switch mailbox.viewMode() {
                case .messages:
                    try await setUpSingleMessageObservation(messageID: messageID)
                case .conversations:
                    try await setUpConversationMessagesObservation(
                        conversationID: conversationID,
                        origin: .pushNotification,
                        mailbox: mailbox
                    )
                }
            }
            await reloadBottomBarActions()
        } catch ActionError.other(.network) {
            updateState(.noConnection)
            reloadContentWhenBackOnline()
        } catch {
            let msg = "Failed fetching initial data. Error: \(String(describing: error))"
            AppLogger.log(message: msg, category: .conversationDetail, isError: true)
        }
    }

    private func setUpSingleMessageObservation(messageID: ID) async throws {
        conversationItem = .init(id: messageID, itemType: .message)
        let liveQueryValues = try await createSingleMessageLiveQuerry(for: messageID)
        isStarred = liveQueryValues.isStarred
        updateStateToMessagesReady(with: liveQueryValues.messages)
    }

    private func setUpConversationMessagesObservation(
        conversationID: ID,
        origin: OpenConversationOrigin,
        mailbox: Mailbox
    ) async throws {
        conversationItem = .init(id: conversationID, itemType: .conversation)
        let liveQueryValues = try await createLiveQueryAndPrepareMessages(
            forConversationID: conversationID,
            origin: origin,
            mailbox: mailbox
        )

        isStarred = liveQueryValues.isStarred
        updateStateToMessagesReady(with: liveQueryValues.messages)
        try await scrollToRelevantMessage(messages: liveQueryValues.messages)
    }

    func onMessageTap(messageId: ID, isDraft: Bool) {
        guard !isDraft else {
            openDraft(with: messageId)
            return
        }
        Task {
            if expandedMessages.contains(messageId) {
                expandedMessages.remove(messageId)
            } else {
                expandedMessages.insert(messageId)
            }
            let liveQueryValues = await readLiveQueryValues()
            updateStateToMessagesReady(with: liveQueryValues.messages)
        }
    }

    func onReplyMessage(withId messageId: ID, toastStateStore: ToastStateStore) {
        onReplyAction(messageId: messageId, action: .reply, toastStateStore: toastStateStore)
    }

    func onReplyAllMessage(withId messageId: ID, toastStateStore: ToastStateStore) {
        onReplyAction(messageId: messageId, action: .replyAll, toastStateStore: toastStateStore)
    }

    func onForwardMessage(withId messageId: ID, toastStateStore: ToastStateStore) {
        onReplyAction(messageId: messageId, action: .forward, toastStateStore: toastStateStore)
    }

    func onEditScheduledMessage(withId messageId: ID, goBack: @escaping () -> Void, toastStateStore: ToastStateStore) {
        let alert: AlertModel = .editScheduleConfirmation(action: { [weak self] action in
            await self?.handle(action: action, messageId: messageId, toastStateStore: toastStateStore, goBack: goBack)
        })
        editScheduledMessageConfirmationAlert = alert
    }

    func unsnoozeConversation(toastStateStore: ToastStateStore) {
        guard let conversationItem, conversationItem.itemType == .conversation, let labelID = mailbox?.labelId() else { return }
        Task { @MainActor in
            do {
                try await self.snoozeService.unsnooze(conversation: [conversationItem.id], labelId: labelID).get()
                toastStateStore.present(toast: .unsnooze)
            } catch {
                AppLogger.log(error: error, category: .snooze)
                if let error = error as? SnoozeError {
                    SnoozeErrorPresenter.presentIfNeeded(error: error, toastStateStore: toastStateStore)
                }
            }
        }
    }

    func markMessageAsReadIfNeeded(metadata: MarkMessageAsReadMetadata) {
        guard let mailbox, metadata.unread else { return }
        Task {
            _ = await markMessagesRead(mailbox: mailbox, messageIds: [metadata.messageID])
        }
    }

    func toggleStarState() {
        guard let conversationItem else { return }
        isStarred
            ? starActionPerformer.unstar(itemsWithIDs: [conversationItem.id], itemType: conversationItem.itemType)
            : starActionPerformer.star(itemsWithIDs: [conversationItem.id], itemType: conversationItem.itemType)
    }

    func isForcingLightMode(forMessageWithId messageId: ID) -> Bool {
        messageAppearanceOverrideStore.isForcingLightMode(forMessageWithId: messageId)
    }

    @MainActor
    func handle(
        action: MessageAction,
        messageID: ID,
        toastStateStore: ToastStateStore,
        goBack: @MainActor @escaping () -> Void
    ) async {
        switch action {
        case .markRead:
            await markAsRead(id: messageID, itemType: .message)
            actionSheets = .allSheetsDismissed
        case .markUnread:
            await markAsUnread(id: messageID, itemType: .message)
            actionSheets = .allSheetsDismissed
            goBack()
        case .star:
            await starActionPerformer.star(itemsWithIDs: [messageID], itemType: .message)
            actionSheets = .allSheetsDismissed
        case .unstar:
            await starActionPerformer.unstar(itemsWithIDs: [messageID], itemType: .message)
            actionSheets = .allSheetsDismissed
        case .labelAs:
            actionSheets = .allSheetsDismissed.copy(
                \.labelAs,
                to: .init(
                    sheetType: .labelAs,
                    ids: [messageID],
                    mailboxItem: .message(
                        isLastMessageInCurrentLocation: state.hasAtMostOneMessage(withSameLocationAs: messageID)
                    )
                )
            )
        case .moveTo:
            actionSheets = .allSheetsDismissed.copy(
                \.moveTo,
                to: .init(
                    sheetType: .moveTo,
                    ids: [messageID],
                    mailboxItem: .message(
                        isLastMessageInCurrentLocation: state.hasAtMostOneMessage(withSameLocationAs: messageID)
                    )
                )
            )
        case .moveToSystemFolder(let systemFolder), .notSpam(let systemFolder):
            actionSheets = .allSheetsDismissed
            await move(
                id: messageID,
                mailboxItem: .message(
                    isLastMessageInCurrentLocation: state.hasAtMostOneMessage(withSameLocationAs: messageID)
                ),
                destination: systemFolder,
                toastStateStore: toastStateStore,
                goBack: goBack
            )
        case .permanentDelete:
            let alert: AlertModel = .deleteConfirmation(
                itemsCount: 1,
                action: { [weak self] action in
                    guard let self else { return }
                    await self.handle(
                        id: messageID,
                        mailboxItem: .message(
                            isLastMessageInCurrentLocation: state.hasAtMostOneMessage(withSameLocationAs: messageID)
                        ),
                        action: action,
                        toastStateStore: toastStateStore, goBack: goBack
                    )
                }
            )
            actionAlert = alert
        case .reply:
            actionSheets = .allSheetsDismissed
            onReplyMessage(withId: messageID, toastStateStore: toastStateStore)
        case .replyAll:
            actionSheets = .allSheetsDismissed
            onReplyAllMessage(withId: messageID, toastStateStore: toastStateStore)
        case .forward:
            actionSheets = .allSheetsDismissed
            onForwardMessage(withId: messageID, toastStateStore: toastStateStore)
        case .viewHeaders, .viewHtml:
            toastStateStore.present(toast: .comingSoon)
        case .print:
            do {
                try await messagePrinter.printMessage(messageID: messageID)
            } catch {
                AppLogger.log(error: error)
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        case .viewInLightMode:
            messageAppearanceOverrideStore.forceLightMode(forMessageWithId: messageID)
            actionSheets = .allSheetsDismissed
        case .viewInDarkMode:
            messageAppearanceOverrideStore.stopForcingLightMode(forMessageWithId: messageID)
            actionSheets = .allSheetsDismissed
        case .reportPhishing:
            let alert: AlertModel = .phishingConfirmation(action: { [weak self] action in
                guard let self else { return }
                await self.handle(
                    action: action,
                    messageID: messageID,
                    mailboxItem: .message(
                        isLastMessageInCurrentLocation: state.hasAtMostOneMessage(withSameLocationAs: messageID)
                    ),
                    goBack: goBack
                )
            })
            actionAlert = alert
        case .more:
            break
        }
    }

    @MainActor
    func handle(
        action: ConversationAction,
        toastStateStore: ToastStateStore,
        goBack: @MainActor @escaping () -> Void
    ) async {
        guard let conversationItem, conversationItem.itemType == .conversation else { return }
        let conversationID = conversationItem.id
        switch action {
        case .markRead:
            await markAsRead(id: conversationID, itemType: .conversation)
            actionSheets = .allSheetsDismissed
        case .markUnread:
            await markAsUnread(id: conversationID, itemType: .conversation)
            actionSheets = .allSheetsDismissed
            goBack()
        case .labelAs:
            actionSheets = .allSheetsDismissed
                .copy(\.labelAs, to: .init(sheetType: .labelAs, ids: [conversationID], mailboxItem: .conversation))
        case .moveTo:
            actionSheets = .allSheetsDismissed
                .copy(\.moveTo, to: .init(sheetType: .moveTo, ids: [conversationID], mailboxItem: .conversation))
        case .moveToSystemFolder(let systemFolder), .notSpam(let systemFolder):
            actionSheets = .allSheetsDismissed
            await move(
                id: conversationID,
                mailboxItem: .conversation,
                destination: systemFolder,
                toastStateStore: toastStateStore,
                goBack: goBack
            )
        case .permanentDelete:
            let alert: AlertModel = .deleteConfirmation(
                itemsCount: 1,
                action: { [weak self] action in
                    await self?.handle(
                        id: conversationID,
                        mailboxItem: .conversation,
                        action: action,
                        toastStateStore: toastStateStore, goBack: goBack
                    )
                }
            )
            actionAlert = alert
        case .star:
            await starActionPerformer.star(itemsWithIDs: [conversationID], itemType: .conversation)
            actionSheets = .allSheetsDismissed
        case .unstar:
            await starActionPerformer.unstar(itemsWithIDs: [conversationID], itemType: .conversation)
            actionSheets = .allSheetsDismissed
        case .snooze:
            actionSheets = .allSheetsDismissed.copy(\.snooze, to: conversationID)
        case .more:
            break
        }
    }

    @MainActor
    private func handle(
        action: PhishingConfirmationAlertAction,
        messageID: ID,
        mailboxItem: MailboxItem,
        goBack: @escaping () -> Void
    ) async {
        hideAlert()
        guard action == .confirm, let mailbox else {
            return
        }
        let actionPerformer = GeneralActionsPerformer(mailbox: mailbox, generalActions: .productionInstance)

        if case .ok = await actionPerformer.markMessagePhishing(messageID: messageID) {
            actionSheets = .allSheetsDismissed
            if mailboxItem.shouldGoBack {
                goBack()
            }
        }
    }

    private func markAsRead(id: ID, itemType: MailboxItemType) async {
        guard let mailbox else { return }
        await ReadActionPerformer(mailbox: mailbox, readActionPerformerActions: .productionInstance)
            .markAsRead(itemsWithIDs: [id], itemType: itemType)
    }

    private func markAsUnread(id: ID, itemType: MailboxItemType) async {
        guard let mailbox else { return }
        await ReadActionPerformer(mailbox: mailbox, readActionPerformerActions: .productionInstance)
            .markAsUnread(itemsWithIDs: [id], itemType: itemType)
    }

    @MainActor
    private func hideAlert() {
        actionAlert = nil
    }

    @MainActor
    private func handle(
        id: ID,
        mailboxItem: MailboxItem,
        action: DeleteConfirmationAlertAction,
        toastStateStore: ToastStateStore,
        goBack: @escaping () -> Void
    ) async {
        hideAlert()
        if action == .delete, let mailbox {
            await DeleteActionPerformer(mailbox: mailbox, deleteActions: .productionInstance)
                .delete(itemsWithIDs: [id], itemType: mailboxItem.itemType)
            toastStateStore.present(toast: .deleted())

            actionSheets = .allSheetsDismissed

            if mailboxItem.shouldGoBack {
                goBack()
            }
        }
    }
}

extension ConversationDetailModel {

    private func reloadContentWhenBackOnline() {
        backOnlineActionExecutor.execute { [weak self] in
            await self?.fetchInitialData()
        }
    }

    private func openDraft(with id: ID) {
        draftPresenter.openDraft(withId: id)
    }

    @MainActor
    private func move(
        id: ID,
        mailboxItem: MailboxItem,
        destination: MovableSystemFolderAction,
        toastStateStore: ToastStateStore,
        goBack: @escaping () -> Void
    ) async {
        guard let mailbox else { return }
        let moveToActionPerformer = MoveToActionPerformer(mailbox: mailbox, moveToActions: .productionInstance)

        let toast: Toast
        do {
            let undo = try await moveToActionPerformer.moveTo(
                destinationID: destination.localId,
                itemsIDs: [id],
                itemType: mailboxItem.itemType
            )
            let toastID = UUID()
            let undoAction = undo.undoAction(userSession: userSession) {
                Dispatcher.dispatchOnMain(
                    .init(block: {
                        toastStateStore.dismiss(withID: toastID)
                    }))
            }

            toast = .moveTo(
                id: toastID,
                destinationName: destination.name.displayData.title.string,
                undoAction: undoAction
            )
        } catch {
            toast = .error(message: error.localizedDescription)
        }

        toastStateStore.present(toast: toast)

        if mailboxItem.shouldGoBack {
            goBack()
        }
    }

    private func initialiseMailbox(basedOn selectedMailbox: SelectedMailbox) async throws -> Mailbox {
        guard let userSession = dependencies.appContext.sessionState.userSession else {
            throw ConversationModelError.noActiveSessionFound
        }

        switch selectedMailbox {
        case .inbox:
            return try newInboxMailbox(ctx: userSession).get()
        case .systemFolder(let labelId, _), .customLabel(let labelId, _), .customFolder(let labelId, _):
            return try newMailbox(ctx: userSession, labelId: labelId).get()
        }
    }

    private func establishConversationItemMetadata() async throws -> ConversationItemMetadata {
        switch seed {
        case .searchResultItem(let item, let mailbox):
            return .init(
                item: .searchResultItem(messageID: item.id, conversationID: item.conversationID),
                selectedMailbox: mailbox
            )
        case .mailboxItem(let item, let mailbox):
            switch item.type {
            case .conversation:
                return .init(item: .conversation(item.id), selectedMailbox: mailbox)
            case .message:
                return .init(item: .message(item.id), selectedMailbox: mailbox)
            }
        case .pushNotification(let message):
            let message = try await fetchMessage(with: message.remoteId)
            return .init(
                item: .pushNotification(messageID: message.id, conversationID: message.conversationId),
                selectedMailbox: message.exclusiveLocation?.selectedMailbox ?? .inbox
            )
        }
    }

    private func fetchMessage(with remoteId: RemoteId) async throws -> Message {
        guard let userSession = dependencies.appContext.sessionState.userSession else {
            throw ConversationModelError.noActiveSessionFound
        }

        let localId = try await resolveMessageId(session: userSession, remoteId: remoteId).get()

        if let message = try await message(session: userSession, id: localId).get() {
            return message
        } else {
            throw ConversationModelError.noMessageFound(messageID: localId)
        }
    }

    private func createLiveQueryAndPrepareMessages(
        forConversationID conversationID: ID,
        origin: OpenConversationOrigin,
        mailbox: Mailbox
    ) async throws -> LiveQueryValues {
        let watchConversationResult = await watchConversation(
            mailbox: mailbox,
            id: conversationID,
            origin: origin,
            callback: conversationMessageListCallback
        )

        switch watchConversationResult {
        case .ok(let watchedConversation):
            messagesLiveQuery = watchedConversation
        case .error(let actionError):
            throw actionError
        }

        /// We want to set the state to expanded before rendering the list to scroll to the correct position
        await setRelevantMessageStateAsExpanded()
        return await readConversationLiveQueryValues()
    }

    private func createSingleMessageLiveQuerry(for messageID: ID) async throws -> LiveQueryValues {
        let watchMessageResult = await watchMessage(
            session: userSession,
            messageId: messageID,
            callback: singleMessageCallback
        )

        switch watchMessageResult {
        case .ok(let message):
            self.singleMessageLiveQuery = message
        case .error(let actionError):
            throw actionError
        }

        return await readMessageLiveQueryValues()
    }

    private func setRelevantMessageStateAsExpanded() async {
        if let messageID = await messageIDToScrollTo() {
            expandedMessages.insert(messageID)
        } else {
            let msg = "Failed to expand relevant message. Error: missing messageID."
            AppLogger.log(message: msg, category: .conversationDetail, isError: true)
        }
    }

    private func updateStateToMessagesReady(with messages: [MessageCellUIModel]) {
        updateState(.messagesReady(messages: messages))
    }

    private func scrollToRelevantMessage(messages: [MessageCellUIModel]) async throws {
        if let messageIDToScrollTo = await messageIDToScrollTo(),
            let messageToScroll = messages.first(where: { $0.id == messageIDToScrollTo })
        {
            self.scrollToMessage = messageToScroll.cellId
        } else if let lastNonDraftMessage = messages.last(where: { !$0.isDraft }) {
            self.scrollToMessage = lastNonDraftMessage.cellId
        }
    }

    private func messageIDToScrollTo() async -> ID? {
        let messageID: ID?
        switch seed {
        case .searchResultItem(let item, _):
            messageID = item.id
        case .mailboxItem(let item, _):
            switch item.type {
            case .conversation:
                logMessageIdToOpen()
                messageID = messagesLiveQuery?.messageIdToOpen
            case .message:
                messageID = item.id
            }
        case .pushNotification(let message):
            switch await resolveMessageId(session: userSession, remoteId: message.remoteId) {
            case .ok(let localId):
                messageID = localId
            case .error(let error):
                AppLogger.log(error: error, category: .conversationDetail)
                messageID = nil
            }
        }
        return messageID
    }

    private func logMessageIdToOpen() {
        let value: String
        if let messageIdToOpen = messagesLiveQuery?.messageIdToOpen {
            value = String(messageIdToOpen.value)
        } else {
            value = "n/a"
        }
        AppLogger.logTemporarily(message: "messageIdToOpen = \(value)", category: .conversationDetail)
    }

    private struct LiveQueryValues {
        let messages: [MessageCellUIModel]
        let isStarred: Bool
    }

    private func readLiveQueryValues() async -> LiveQueryValues {
        switch conversationItem?.itemType {
        case .conversation:
            await readConversationLiveQueryValues()
        case .message:
            await readMessageLiveQueryValues()
        case .none:
            .init(messages: [], isStarred: false)
        }
    }

    private func readMessageLiveQueryValues() async -> LiveQueryValues {
        do {
            guard let conversationItem, conversationItem.itemType == .message else {
                return .init(messages: [], isStarred: false)
            }
            let messageID = conversationItem.id
            let message = try await message(session: userSession, id: messageID).get()
            let isStarred = message?.starred ?? false

            let singleMessage: [MessageCellUIModel] = [message]
                .compactMap { $0 }
                .map { message in
                    .init(
                        id: message.id,
                        locationID: message.exclusiveLocation?.model.id,
                        type: .expanded(message.toExpandedMessageCellUIModel())
                    )
                }
            return .init(messages: singleMessage, isStarred: isStarred)
        } catch {
            AppLogger.log(error: error, category: .conversationDetail)
            return .init(messages: [], isStarred: false)
        }
    }

    private func readConversationLiveQueryValues() async -> LiveQueryValues {
        do {
            guard let conversationItem, let mailbox else {
                let msg = "no mailbox object (labelId=\(String(describing: mailbox?.labelId().value))) or conversationItem (\(String(describing: conversationItem))"
                AppLogger.log(message: msg, category: .conversationDetail, isError: true)
                return .init(messages: [], isStarred: false)
            }
            let conversationID = conversationItem.id
            let conversationAndMessages = try await conversation(mailbox: mailbox, id: conversationID).get()
            let isStarred = conversationAndMessages?.conversation.isStarred ?? false
            let messages = conversationAndMessages?.messages ?? []

            let lastNonDraftMessageIndex = messages.lastIndex(where: { message in !message.isDraft })

            let result: [MessageCellUIModel] =
                messages
                .enumerated()
                .map { index, message in
                    let messageCellUIModelType: MessageCellUIModelType
                    let showExpanded = !message.isDraft && (expandedMessages.contains(message.id) || index == lastNonDraftMessageIndex)

                    if showExpanded {
                        messageCellUIModelType = .expanded(message.toExpandedMessageCellUIModel())
                    } else {
                        messageCellUIModelType = .collapsed(message.toCollapsedMessageCellUIModel())
                    }
                    return .init(
                        id: message.id,
                        locationID: message.exclusiveLocation?.model.id,
                        type: messageCellUIModelType
                    )
                }

            return .init(messages: result, isStarred: isStarred)
        } catch {
            AppLogger.log(error: error, category: .conversationDetail)
            return .init(messages: [], isStarred: false)
        }
    }

    private func updateState(_ newState: State) {
        AppLogger.log(message: "conversation detail state \(newState.debugDescription)", category: .conversationDetail)
        state = newState
    }

    private func onReplyAction(messageId: ID, action: ReplyAction, toastStateStore: ToastStateStore) {
        Task {
            do {
                try await draftPresenter.handleReplyAction(for: messageId, action: action)
            } catch {
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        }
    }

    private func handle(
        action: EditScheduleAlertAction,
        messageId: ID,
        toastStateStore: ToastStateStore,
        goBack: @escaping () -> Void
    ) async {
        editScheduledMessageConfirmationAlert = nil
        if action == .edit {
            do {
                try await self.draftPresenter.cancelScheduledMessageAndOpenDraft(for: messageId)
                goBack()
            } catch {
                switch error {
                case .other(let protonError) where protonError == .network:
                    toastStateStore.present(toast: .information(message: L10n.Action.Send.editScheduleNetworkIsRequired.string))
                default:
                    toastStateStore.present(toast: .error(message: error.localizedDescription))
                }
            }
        }
    }

    func reloadBottomBarActions() async {
        guard let mailbox, let conversationItem else { return }
        switch mailbox.viewMode() {
        case .conversations:
            do {
                let actions = try await allAvailableConversationActionsForConversation(
                    mailbox: mailbox,
                    conversationId: conversationItem.id
                ).get()
                self.conversationToolbarActions = .conversation(actions: actions, conversationID: conversationItem.id)
            } catch {
                AppLogger.log(error: error, category: .conversationDetail)
            }
        case .messages:
            let theme = messageAppearanceOverrideStore.themeOpts(
                messageID: conversationItem.id,
                colorScheme: colorScheme
            )
            do {
                let actions = try await allAvailableMessageActionsForMessage(
                    mailbox: mailbox,
                    theme: theme,
                    messageId: conversationItem.id
                ).get()
                self.conversationToolbarActions = .message(actions: actions, messageID: conversationItem.id)
            } catch {
                AppLogger.log(error: error, category: .conversationDetail)
            }
        }
    }
}

extension ConversationDetailModel {
    enum State: Equatable {
        case initial
        case fetchingMessages
        case noConnection
        case messagesReady(messages: [MessageCellUIModel])

        var debugDescription: String {
            if case .messagesReady(let messages) = self {
                return "messagesReady: \(messages.count) messages"
            }
            return "\(self)"
        }
    }
}

extension ConversationDetailModel {

    struct Dependencies {
        let appContext: AppContext

        init(
            appContext: AppContext = .shared,
        ) {
            self.appContext = appContext
        }
    }
}

struct MessageCellUIModel: Equatable {
    let id: ID
    let locationID: ID?
    let type: MessageCellUIModelType

    /// Used to identify Views in a way that allows to scroll to them and allows to refresh
    /// the screen when collapsiong/expanding cells. This is because we don't modify the
    /// existing view but we replace it with another type so we need a different
    /// id value: CollapsedMessageCell <--> ExpandedMessageCell
    var cellId: String {
        "\(id.value)-\(type.description)"
    }
}

enum MessageCellUIModelType: Equatable {
    case collapsed(CollapsedMessageCellUIModel)
    case expanded(ExpandedMessageCellUIModel)

    var description: String {
        switch self {
        case .collapsed:
            "collapsed"
        case .expanded:
            "expanded"
        }
    }
}

enum ConversationModelError: Error {
    case noActiveSessionFound
    case noMessageFound(messageID: ID)
}

private extension MailboxActionSheetsState {
    static func initial() -> Self {
        .init(labelAs: nil, moveTo: nil, editToolbar: nil)
    }
}

private extension MessageCellUIModel {

    var isDraft: Bool {
        switch type {
        case .collapsed(let model):
            model.isDraft
        case .expanded:
            false
        }
    }

}

enum SnoozeErrorPresenter {

    static func presentIfNeeded(error: SnoozeError, toastStateStore: ToastStateStore) {
        if case .reason(let snoozeErrorReason) = error {
            toastStateStore.present(toast: .error(message: snoozeErrorReason.errorMessage.string))
        }
    }

}

private extension ConversationDetailModel.State {

    func hasAtMostOneMessage(withSameLocationAs messageID: ID?) -> Bool {
        switch self {
        case .initial, .fetchingMessages, .noConnection:
            return false
        case .messagesReady(let messages):
            let targetMessage =
                messages
                .first(where: { $0.id == messageID })
            return
                messages
                .filter { message in message.locationID == targetMessage?.locationID }
                .count == 1
        }
    }

}

private extension MessageAppearanceOverrideStore {

    func themeOpts(messageID: ID, colorScheme: ColorScheme) -> ThemeOpts {
        let isForcingLightMode = isForcingLightMode(forMessageWithId: messageID)
        return .init(colorScheme: colorScheme, isForcingLightMode: isForcingLightMode)
    }

}
