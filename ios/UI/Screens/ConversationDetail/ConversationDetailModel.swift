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
import proton_mail_uniffi

@MainActor
final class ConversationDetailModel: Sendable, ObservableObject {
    static let lastCellId = "last"

    @Published private(set) var state: State = .initial
    @Published private(set) var seed: ConversationDetailSeed
    @Published private(set) var scrollToMessage: String? = nil

    private var mailbox: Mailbox?
    private var messagesLiveQuery: ConversationMessagesLiveQueryResult?
    private var expandedMessages: Set<PMLocalMessageId>
    private let dependencies: Dependencies
    private let messageListCallback: PMMailboxLiveQueryUpdatedCallback = .init(delegate: {})

    init(seed: ConversationDetailSeed, dependencies: Dependencies = .init()) {
        self.seed = seed
        self.expandedMessages = .init()
        self.dependencies = dependencies

    }

    private func setUpCallback() {
        messageListCallback.delegate = { [weak self] in
            guard let self else { return }
            Task {
                await self.readLiveQueryValues()
            }
        }
    }

    func fetchInitialData() async {
        await updateState(.fetchingMessages)
        do {
            let mailbox = try await initialiseMailbox()
            let conversationId = try await obtainLocalConversationId()
            let messages = try await createLiveQueryAndPrepareMessages(for: conversationId, mailbox: mailbox)

            await updateStateToMessagesReady(with: messages)
            try await scrollToRelevantMessage(messages: messages)

        } catch {
            let msg = "Failed fetching initial data. Error: \(String(describing: error))"
            AppLogger.log(message: msg, category: .conversationDetail, isError: true)
        }
    }

    func onMessageTap(messageId: PMLocalMessageId) {
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
}

extension ConversationDetailModel {

    private func initialiseMailbox() async throws -> Mailbox {
        guard let userSession = dependencies.appContext.activeUserSession else {
            throw ConversationModelError.noActiveSessionFound
        }
        let newMailbox: Mailbox
        switch seed.selectedMailbox {
        case .inbox:
            newMailbox = try await Mailbox.inbox(ctx: userSession)
        case .label(let localLabelId, _, _):
            newMailbox = try await Mailbox(ctx: userSession, labelId: localLabelId)
        }
        mailbox = newMailbox
        return newMailbox
    }

    private func obtainLocalConversationId() async throws -> PMLocalConversationId {
        switch seed {
        case .mailboxItem(let item, _):
            return item.conversationId
        case .message(let messageId, _, _):
            return try await obtainLocalConversationIdFrom(remoteMessageId: messageId)
        }
    }

    private func obtainLocalConversationIdFrom(remoteMessageId: String) async throws -> PMLocalConversationId {
        guard let session = dependencies.appContext.activeUserSession else {
            throw ConversationModelError.noActiveSessionFound
        }
        guard let messageFromRemoteId = try await session.messageMetadataWithRemoteId(remoteId: remoteMessageId) else {
            throw ConversationModelError.noMessageFoundForRemoteId(id: remoteMessageId)
        }
        return messageFromRemoteId.conversationId
    }

    private func createLiveQueryAndPrepareMessages(
        for conversationId: PMLocalConversationId,
        mailbox: Mailbox
    ) async throws -> [MessageCellUIModel] {
        messagesLiveQuery = try await mailbox.newConversationMessagesLiveQuery(
            id: conversationId,
            cb: messageListCallback
        )
        /// We want to set the state to expanded before rendering the list to scroll to the correct position
        await setRelevantMessageStateAsExpanded()
        return await readLiveQueryValues()
    }

    private func setRelevantMessageStateAsExpanded() async {
        do {
            if let initialMessage = try await determineLocalMessageIdToScrollTo() {
                expandedMessages.insert(initialMessage)
            }
        } catch {
            let msg = "Failed to expand relevant message. Error: \(String(describing: error))"
            AppLogger.log(message: msg, category: .conversationDetail, isError: true)
        }
    }

    private func updateStateToMessagesReady(with messages: [MessageCellUIModel]) async {
        if let lastMessage = messages.last, case .expanded(let last) = lastMessage.type {
            await updateState(.messagesReady(previous: messages.dropLast(), last: last))
        }
    }

    private func scrollToRelevantMessage(messages: [MessageCellUIModel]) async throws {
        let localMessageIdToScrollTo = try await determineLocalMessageIdToScrollTo()
        let cell = messages.first(where: { $0.id == localMessageIdToScrollTo })
        scrollToMessage = cell?.cellId ?? Self.lastCellId
    }

    private func determineLocalMessageIdToScrollTo() async throws -> PMLocalMessageId? {
        let localMessageIdToScrollTo: PMLocalMessageId?
        switch seed {
        case .mailboxItem(let item, _):
            switch item.type {
            case .conversation:
                logMessageIdToOpen()
                localMessageIdToScrollTo = messagesLiveQuery?.messageIdToOpen
            case .message:
                localMessageIdToScrollTo = item.id
            }
        case .message(let remoteMessageId, _, _):
            let session = dependencies.appContext.activeUserSession
            localMessageIdToScrollTo = try await session?.messageMetadataWithRemoteId(remoteId: remoteMessageId)?.id
        }
        return localMessageIdToScrollTo
    }

    private func logMessageIdToOpen() {
        let value: String
        if let messageIdToOpen = messagesLiveQuery?.messageIdToOpen {
            value = String(messageIdToOpen)
        } else {
            value = "n/a"
        }
        AppLogger.logTemporarily(message: "messageIdToOpen = \(value)", category: .conversationDetail)
    }

    private func readLiveQueryValues() async -> [MessageCellUIModel] {
        do {
            guard let mailbox, let messagesLiveQuery else {
                let msg = "no mailbox object or message live query"
                AppLogger.log(message: msg, category: .conversationDetail, isError: true)
                return []
            }
            let messages = try messagesLiveQuery.query.value()
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
                    messageCellUIModel = await .collapsed(message.toCollapsedMessageCellUIModel())
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
        for message: LocalMessageMetadata,
        wait: Bool,
        mailbox: Mailbox
    ) async throws -> ExpandedMessageCellUIModel {
        let messageBody = wait ? try await mailbox.messageBody(id: message.id).body() : nil
        return await message.toExpandedMessageCellUIModel(message: messageBody)
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
    let id: PMLocalMessageId
    let type: MessageCellUIModelType
    
    /// Used to identify Views in a way that allows to scroll to them and allows to refresh 
    /// the screen when collapsiong/expanding cells. This is because we don't modify the
    /// existing view but we replace it with another type so we need a different
    /// id value: CollapsedMessageCell <--> ExpandedMessageCell
    var cellId: String {
        "\(id)-\(type.description)"
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
    case noMessageFoundForRemoteId(id: String)
}
