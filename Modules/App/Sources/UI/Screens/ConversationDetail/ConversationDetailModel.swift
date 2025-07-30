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

import Foundation
import InboxCore
import InboxCoreUI
import proton_app_uniffi

@MainActor
final class ConversationDetailModel: Sendable, ObservableObject {
    @Published private(set) var state: State = .initial
    @Published private(set) var seed: ConversationDetailSeed
    @Published private(set) var scrollToMessage: String? = nil
    @Published private(set) var mailbox: Mailbox?
    @Published private(set) var conversationID: ID?
    @Published private(set) var isStarred: Bool
    @Published private(set) var bottomBarActions: [BottomBarActions] = []
    @Published var actionSheets: MailboxActionSheetsState = .initial()
    @Published var editScheduledMessageConfirmationAlert: AlertModel?
    @Published var deleteConfirmationAlert: AlertModel?
    @Published var attachmentIDToOpen: ID?

    let messageAppearanceOverrideStore = MessageAppearanceOverrideStore()
    let messagePrinter: MessagePrinter

    var isBottomBarHidden: Bool {
        seed.isOutbox || bottomBarActions.isEmpty
    }

    var areActionsHidden: Bool {
        seed.isOutbox
    }

    private var messagesLiveQuery: WatchedConversation?
    private var expandedMessages: Set<ID>
    private let draftPresenter: DraftPresenter
    private let dependencies: Dependencies
    private let backOnlineActionExecutor: BackOnlineActionExecutor

    private lazy var messageListCallback = LiveQueryCallbackWrapper { [weak self] in
        guard let self else { return }
        Task { @MainActor in
            let liveQueryValues = await self.readLiveQueryValues()
            self.isStarred = liveQueryValues.isStarred
            self.updateStateToMessagesReady(with: liveQueryValues.messages)
            await self.reloadBottomBarActions()
        }
    }

    private lazy var starActionPerformer: StarActionPerformer = {
        .init(mailUserSession: dependencies.appContext.userSession)
    }()

    private var userSession: MailUserSession {
        dependencies.appContext.userSession
    }

    init(
        seed: ConversationDetailSeed,
        draftPresenter: DraftPresenter,
        dependencies: Dependencies = .init(),
        backOnlineActionExecutor: BackOnlineActionExecutor
    ) {
        self.seed = seed
        self.isStarred = seed.isStarred
        self.expandedMessages = .init()
        self.draftPresenter = draftPresenter
        self.dependencies = dependencies
        self.backOnlineActionExecutor = backOnlineActionExecutor
        messagePrinter = .init(userSession: { dependencies.appContext.userSession })
    }

    @MainActor
    func fetchInitialData() async {
        updateState(.fetchingMessages)
        do {
            let (selectedMailbox, conversationID) = try await establishSelectedMailboxAndConversationID()
            let mailbox = try await initialiseMailbox(basedOn: selectedMailbox)
            self.mailbox = mailbox
            self.conversationID = conversationID
            let liveQueryValues = try await createLiveQueryAndPrepareMessages(
                forConversationID: conversationID,
                mailbox: mailbox
            )

            isStarred = liveQueryValues.isStarred
            updateStateToMessagesReady(with: liveQueryValues.messages)
            await reloadBottomBarActions()
            try await scrollToRelevantMessage(messages: liveQueryValues.messages)
        } catch ActionError.other(.network) {
            updateState(.noConnection)
            reloadContentWhenBackOnline()
        } catch {
            let msg = "Failed fetching initial data. Error: \(String(describing: error))"
            AppLogger.log(message: msg, category: .conversationDetail, isError: true)
        }
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

    @MainActor
    func onEditScheduledMessage(withId messageId: ID, goBack: @escaping () -> Void, toastStateStore: ToastStateStore) {
        let alert: AlertModel = .editScheduleConfirmation(action: { [weak self] action in
            await self?.handle(action: action, messageId: messageId, toastStateStore: toastStateStore, goBack: goBack)
        })
        editScheduledMessageConfirmationAlert = alert
    }

    func markMessageAsReadIfNeeded(metadata: MarkMessageAsReadMetadata) {
        guard let mailbox, metadata.unread else { return }
        Task {
            _ = await markMessagesRead(mailbox: mailbox, messageIds: [metadata.messageID])
        }
    }

    func toggleStarState() {
        isStarred ? unstarConversation() : starConversation()
    }

    func handleConversation(action: BottomBarActions, toastStateStore: ToastStateStore, goBack: @escaping () -> Void) {
        let conversationID = conversationID.unsafelyUnwrapped
        switch action {
        case .labelAs:
            actionSheets = actionSheets.copy(\.labelAs, to: .init(sheetType: .labelAs, ids: [conversationID], type: .conversation))
        case .more:
            actionSheets =
                actionSheets
                .copy(\.mailbox, to: .init(id: conversationID, type: .conversation, title: seed.subject))
        case .moveTo:
            actionSheets =
                actionSheets
                .copy(\.moveTo, to: .init(sheetType: .moveTo, ids: [conversationID], type: .conversation))
        case .star:
            starConversation()
        case .unstar:
            unstarConversation()
        case .markRead:
            markConversationAsRead(goBack: goBack)
        case .markUnread:
            markConversationAsUnread(goBack: goBack)
        case .permanentDelete:
            let alert: AlertModel = .deleteConfirmation(
                itemsCount: 1,
                action: { [weak self] action in
                    self?.handle(action: action, toastStateStore: toastStateStore, goBack: goBack)
                }
            )
            deleteConfirmationAlert = alert
        case .moveToSystemFolder(let label), .notSpam(let label):
            moveConversation(destination: label, toastStateStore: toastStateStore, goBack: goBack)
        case .snooze:
            actionSheets =
                actionSheets
                .copy(\.snooze, to: conversationID)
                .copy(\.mailbox, to: nil)
        }
    }

    func handle(
        action: DeleteConfirmationAlertAction,
        toastStateStore: ToastStateStore,
        goBack: @escaping () -> Void
    ) {
        deleteConfirmationAlert = nil
        if action == .delete, let mailbox {
            Task {
                await DeleteActionPerformer(mailbox: mailbox, deleteActions: .productionInstance)
                    .delete(itemsWithIDs: [conversationID.unsafelyUnwrapped], itemType: .conversation)
                Dispatcher.dispatchOnMain(
                    .init(block: {
                        toastStateStore.present(toast: .deleted())
                        goBack()
                    }))
            }
        }
    }

    func isForcingLightMode(forMessageWithId messageId: ID) -> Bool {
        messageAppearanceOverrideStore.isForcingLightMode(forMessageWithId: messageId)
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

    private func starConversation() {
        starActionPerformer.star(itemsWithIDs: [conversationID.unsafelyUnwrapped], itemType: .conversation)
    }

    private func unstarConversation() {
        starActionPerformer.unstar(itemsWithIDs: [conversationID.unsafelyUnwrapped], itemType: .conversation)
    }

    private func moveConversation(
        destination: MovableSystemFolderAction,
        toastStateStore: ToastStateStore,
        goBack: @escaping () -> Void
    ) {
        guard let mailbox else { return }
        let moveToActionPerformer = MoveToActionPerformer(mailbox: mailbox, moveToActions: .productionInstance)
        Task {
            let toast: Toast

            do {
                try await moveToActionPerformer.moveTo(
                    destinationID: destination.localId,
                    itemsIDs: [conversationID.unsafelyUnwrapped],
                    itemType: .conversation
                )

                toast = .moveTo(destinationName: destination.name.humanReadable.string)
            } catch {
                toast = .error(message: error.localizedDescription)
            }

            Dispatcher.dispatchOnMain(
                .init(block: {
                    toastStateStore.present(toast: toast)
                    goBack()
                }))
        }
    }

    private func markConversationAsRead(goBack: () -> Void) {
        guard let mailbox else { return }
        ReadActionPerformer(mailbox: mailbox)
            .markAsRead(itemsWithIDs: [conversationID.unsafelyUnwrapped], itemType: .conversation)
        goBack()
    }

    private func markConversationAsUnread(goBack: () -> Void) {
        guard let mailbox else { return }
        ReadActionPerformer(mailbox: mailbox)
            .markAsUnread(itemsWithIDs: [conversationID.unsafelyUnwrapped], itemType: .conversation)
        goBack()
    }

    private func initialiseMailbox(basedOn selectedMailbox: SelectedMailbox) async throws -> Mailbox {
        guard let userSession = dependencies.appContext.sessionState.userSession else {
            throw ConversationModelError.noActiveSessionFound
        }

        switch selectedMailbox {
        case .inbox:
            return try await newInboxMailbox(ctx: userSession).get()
        case .systemFolder(let labelId, _), .customLabel(let labelId, _), .customFolder(let labelId, _):
            return try await newMailbox(ctx: userSession, labelId: labelId).get()
        }
    }

    private func establishSelectedMailboxAndConversationID() async throws -> (SelectedMailbox, ID) {
        let selectedMailbox: SelectedMailbox
        let conversationId: ID

        switch seed {
        case .mailboxItem(let item, let mailbox):
            selectedMailbox = mailbox
            conversationId = item.conversationID
        case .pushNotification(let message):
            let message = try await fetchMessage(with: message.remoteId)

            if let exclusiveLocation = message.exclusiveLocation {
                selectedMailbox = exclusiveLocation.selectedMailbox
            } else {
                selectedMailbox = .inbox
            }

            conversationId = message.conversationId
        }

        return (selectedMailbox, conversationId)
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
        mailbox: Mailbox
    ) async throws -> LiveQueryValues {
        let watchConversationResult = await watchConversation(
            mailbox: mailbox,
            id: conversationID,
            callback: messageListCallback
        )

        switch watchConversationResult {
        case .ok(let watchedConversation):
            messagesLiveQuery = watchedConversation
        case .error(let actionError):
            throw actionError
        }

        /// We want to set the state to expanded before rendering the list to scroll to the correct position
        await setRelevantMessageStateAsExpanded()
        return await readLiveQueryValues()
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
        do {
            guard let conversationID, let mailbox else {
                let msg = "no mailbox object (labelId=\(String(describing: mailbox?.labelId().value))) or conversationID (\(String(describing: conversationID))"
                AppLogger.log(message: msg, category: .conversationDetail, isError: true)
                return .init(messages: [], isStarred: false)
            }
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

    @MainActor
    private func updateState(_ newState: State) {
        AppLogger.log(message: "conversation detail state \(newState.debugDescription)", category: .conversationDetail)
        state = newState
    }

    private func onReplyAction(messageId: ID, action: ReplyAction, toastStateStore: ToastStateStore) {
        Task {
            await draftPresenter.handleReplyAction(
                for: messageId, action: action,
                onError: { error in
                    toastStateStore.present(toast: .error(message: error.localizedDescription))
                })
        }
    }

    @MainActor
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

    private func reloadBottomBarActions() async {
        guard let mailbox, let conversationID else {
            return
        }

        bottomBarActions =
            try! await dependencies
            .bottomBarConversationActionsProvider(mailbox, [conversationID])
            .get()
            .visibleBottomBarActions
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
        let bottomBarConversationActionsProvider: ConversationBottomBarActionsProvider

        init(
            appContext: AppContext = .shared,
            bottomBarConversationActionsProvider: @escaping ConversationBottomBarActionsProvider = allAvailableBottomBarActionsForConversations
        ) {
            self.appContext = appContext
            self.bottomBarConversationActionsProvider = bottomBarConversationActionsProvider
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
        .init(mailbox: nil, labelAs: nil, moveTo: nil)
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
