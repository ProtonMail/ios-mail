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
    static let lastCellId = "last"

    @Published private(set) var state: State = .initial
    @Published private(set) var seed: ConversationDetailSeed
    @Published private(set) var scrollToMessage: String? = nil
    @Published private(set) var mailbox: Mailbox?
    @Published private(set) var conversationID: ID?
    @Published private(set) var isStarred: Bool
    @Published var actionSheets: MailboxActionSheetsState = .initial()
    @Published var deleteConfirmationAlert: AlertViewModel<DeleteConfirmationAlertAction>?

    private var messagesLiveQuery: WatchedConversation?
    private var expandedMessages: Set<ID>
    private let dependencies: Dependencies
    private let messageListCallback: LiveQueryCallbackWrapper = .init()
    private let starActionPerformer: StarActionPerformer

    init(seed: ConversationDetailSeed, dependencies: Dependencies = .init()) {
        self.seed = seed
        self.isStarred = seed.isStarred
        self.expandedMessages = .init()
        self.dependencies = dependencies
        self.starActionPerformer = .init(mailUserSession: dependencies.appContext.userSession)
        setUpCallback()
    }

    private func setUpCallback() {
        messageListCallback.delegate = { [weak self] in
            guard let self else { return }
            Task {
                await self.readLiveQueryValues()
                self.updateStarState()
            }
        }
    }

    func fetchInitialData() async {
        await updateState(.fetchingMessages)
        do {
            let mailbox = try await initialiseMailbox()
            let conversationID = try await conversationID()
            self.conversationID = conversationID
            let messages = try await createLiveQueryAndPrepareMessages(
                forConversationID: conversationID,
                mailbox: mailbox
            )

            await updateStateToMessagesReady(with: messages)
            try await scrollToRelevantMessage(messages: messages)

        } catch {
            let msg = "Failed fetching initial data. Error: \(String(describing: error))"
            AppLogger.log(message: msg, category: .conversationDetail, isError: true)
        }
    }

    func onMessageTap(messageId: ID) {
        Task {
            if expandedMessages.contains(messageId) {
                expandedMessages.remove(messageId)
            } else {
                expandedMessages.insert(messageId)
            }
            let messages = await readLiveQueryValues()
            await updateStateToMessagesReady(with: messages)
        }
    }

    func markMessageAsReadIfNeeded(metadata: MarkMessageAsReadMetadata) {
        guard let mailbox, metadata.unread else { return }
        Task {
            try? await markMessagesRead(
                mailbox: mailbox,
                messageIds: [metadata.messageID]
            )
        }
    }

    func toggleStarState() {
        isStarred ? unstarConversation() : starConversation()
    }

    func handleConversation(action: BottomBarAction, toastStateStore: ToastStateStore) {
        let conversationID = conversationID.unsafelyUnwrapped
        switch action {
        case .labelAs:
            actionSheets = actionSheets.copy(\.labelAs, to: .init(ids: [conversationID], type: .conversation))
        case .more:
            actionSheets = actionSheets
                .copy(\.mailbox, to: .init(ids: [conversationID], type: .conversation, title: seed.subject))
        case .moveTo:
            actionSheets = actionSheets
                .copy(\.moveTo, to: .init(ids: [conversationID], type: .conversation))
        case .star:
            starConversation()
        case .unstar:
            unstarConversation()
        case .markRead:
            markConversationAsRead()
        case .markUnread:
            markConversationAsUnread()
        case .permanentDelete:
            deleteConfirmationAlert = .deleteConfirmation(itemsCount: 1)
        case .moveToSystemFolder(let label), .notSpam(let label):
            moveConversation(destination: label, toastStateStore: toastStateStore)
        }
    }

    func handle(action: DeleteConfirmationAlertAction, toastStateStore: ToastStateStore) {
        deleteConfirmationAlert = nil
        if action == .delete, let mailbox {
            Task {
                await DeleteActionPerformer(mailbox: mailbox, deleteActions: .productionInstance)
                    .delete(itemsWithIDs: [conversationID.unsafelyUnwrapped], itemType: .conversation)
                Dispatcher.dispatchOnMain(.init(block: {
                    toastStateStore.present(toast: .deleted())
                }))
            }
        }
    }
}

extension ConversationDetailModel {

    private func updateStarState() {
        let isStarred = messagesLiveQuery?.conversation.isStarred ?? false
        Dispatcher.dispatchOnMain(.init(block: { [weak self] in
            self?.isStarred = isStarred
        }))
    }

    private func starConversation() {
        starActionPerformer.star(itemsWithIDs: [conversationID.unsafelyUnwrapped], itemType: .conversation)
    }

    private func unstarConversation() {
        starActionPerformer.unstar(itemsWithIDs: [conversationID.unsafelyUnwrapped], itemType: .conversation)
    }

    private func moveConversation(destination: MoveToSystemFolderLocation, toastStateStore: ToastStateStore) {
        guard let mailbox else { return }
        let moveToActionPerformer = MoveToActionPerformer(mailbox: mailbox, moveToActions: .productionInstance)
        Task {
            await moveToActionPerformer.moveTo(
                destinationID: destination.localId,
                itemsIDs: [conversationID.unsafelyUnwrapped],
                itemType: .conversation
            )
            Dispatcher.dispatchOnMain(.init(block: {
                toastStateStore.present(toast: .moveTo(destinationName: destination.systemLabel.humanReadable.string))
            }))
        }
    }

    private func markConversationAsRead() {
        guard let mailbox else { return }
        ReadActionPerformer(mailbox: mailbox)
            .markAsRead(itemsWithIDs: [conversationID.unsafelyUnwrapped], itemType: .conversation)
    }

    private func markConversationAsUnread() {
        guard let mailbox else { return }
        ReadActionPerformer(mailbox: mailbox)
            .markAsUnread(itemsWithIDs: [conversationID.unsafelyUnwrapped], itemType: .conversation)
    }

    private func initialiseMailbox() async throws -> Mailbox {
        guard let userSession = dependencies.appContext.sessionState.userSession else {
            throw ConversationModelError.noActiveSessionFound
        }
        let newMailbox: Mailbox
        switch seed.selectedMailbox {
        case .inbox:
            newMailbox = try await Mailbox.inbox(ctx: userSession)
        case .systemFolder, .customLabel, .customFolder:
            newMailbox = try await Mailbox(ctx: userSession, labelId: seed.selectedMailbox.localId)
        }
        mailbox = newMailbox
        return newMailbox
    }

    private func conversationID() async throws -> ID {
        switch seed {
        case .mailboxItem(let item, _):
            return item.conversationID
        case .message(let message):
            let message = try await fetchMessage(with: message.remoteID)
            return message.conversationId
        }
    }

    private func fetchMessage(with messageID: ID) async throws -> Message {
        guard let message = try await message(session: dependencies.appContext.userSession, id: messageID) else {
            throw ConversationModelError.noMessageFound(messageID: messageID)
        }

        return message
    }

    private func createLiveQueryAndPrepareMessages(
        forConversationID conversationID: ID,
        mailbox: Mailbox
    ) async throws -> [MessageCellUIModel] {
        messagesLiveQuery = try await watchConversation(
            mailbox: mailbox,
            id: conversationID,
            callback: messageListCallback
        )

        /// We want to set the state to expanded before rendering the list to scroll to the correct position
        setRelevantMessageStateAsExpanded()
        return await readLiveQueryValues()
    }

    private func setRelevantMessageStateAsExpanded() {
        if let messageID = messageIDToScrollTo() {
            expandedMessages.insert(messageID)
        } else {
            let msg = "Failed to expand relevant message. Error: missing messageID."
            AppLogger.log(message: msg, category: .conversationDetail, isError: true)
        }
    }

    private func updateStateToMessagesReady(with messages: [MessageCellUIModel]) async {
        if let lastMessage = messages.last, case .expanded(let last) = lastMessage.type {
            await updateState(.messagesReady(previous: messages.dropLast(), last: last))
        }
    }

    private func scrollToRelevantMessage(messages: [MessageCellUIModel]) async throws {
        let messageIDToScrollTo = messageIDToScrollTo()
        if messages.last?.id == messageIDToScrollTo {
            scrollToMessage = Self.lastCellId
        } else {
            let cell = messages.first(where: { $0.id == messageIDToScrollTo })
            scrollToMessage = cell?.cellId ?? Self.lastCellId
        }
    }

    private func messageIDToScrollTo() -> ID? {
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
        case .message(let message):
            messageID = message.remoteID
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

    private func readLiveQueryValues() async -> [MessageCellUIModel] {
        do {
            guard let mailbox, let messagesLiveQuery else {
                let msg = "no mailbox object (labelId=\(String(describing: mailbox?.labelId().value))) or message live query"
                AppLogger.log(message: msg, category: .conversationDetail, isError: true)
                return []
            }
            let conversationID = try await conversationID()
            let messages = try await conversation(mailbox: mailbox, id: conversationID)?.messages ?? []
            guard let lastMessage = messages.last else { return [] }
            
            // list of messages except the last one
            var result = [MessageCellUIModel]()
            for i in messages.indices.dropLast() {
                let message = messages[i]

                let messageCellUIModel: MessageCellUIModelType
                if expandedMessages.contains(message.id) {
                    let wait = message.id == messagesLiveQuery.messageIdToOpen
                    let uiModel = try await expandedMessageCellUIModel(for: message, wait: wait, mailbox: mailbox)
                    messageCellUIModel = .expanded(uiModel)
                } else {
                    messageCellUIModel = .collapsed(message.toCollapsedMessageCellUIModel())
                }

                result.append(.init(id: message.id, type: messageCellUIModel))
            }
            
            // last message
            let expandedMessage = try await expandedMessageCellUIModel(for: lastMessage, wait: true, mailbox: mailbox)
            result.append(.init(id: lastMessage.id, type: .expanded(expandedMessage)))

            return result
        } catch {
            AppLogger.log(error: error, category: .conversationDetail)
            return []
        }
    }

    private func expandedMessageCellUIModel(
        for message: Message,
        wait: Bool,
        mailbox: Mailbox
    ) async throws -> ExpandedMessageCellUIModel {
        let provider = MessageBodyProvider(mailbox: mailbox)
        let messageBody = wait ? await provider.messageBody(for: message.id) : nil
        return message.toExpandedMessageCellUIModel(message: messageBody)
    }

    @MainActor
    private func updateState(_ newState: State) async {
        AppLogger.log(message: "conversation detail state \(newState.debugDescription)", category: .conversationDetail)
        state = newState
    }
}

extension ConversationDetailModel {
    enum State {
        case initial
        case fetchingMessages
        case messagesReady(previous: [MessageCellUIModel], last: ExpandedMessageCellUIModel)

        var debugDescription: String {
            if case .messagesReady(let array, _) = self {
                return "messagesReady: \(array.count + 1) messages"
            }
            return "\(self)"
        }
    }
}

extension ConversationDetailModel {

    struct Dependencies {
        let appContext: AppContext

        init(appContext: AppContext = .shared) {
            self.appContext = appContext
        }
    }
}

struct MessageCellUIModel {
    let id: ID
    let type: MessageCellUIModelType
    
    /// Used to identify Views in a way that allows to scroll to them and allows to refresh 
    /// the screen when collapsiong/expanding cells. This is because we don't modify the
    /// existing view but we replace it with another type so we need a different
    /// id value: CollapsedMessageCell <--> ExpandedMessageCell
    var cellId: String {
        "\(id.value)-\(type.description)"
    }
}

enum MessageCellUIModelType {
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
