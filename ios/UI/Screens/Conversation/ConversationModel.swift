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

enum ConversationScreenSeedUIModel {
    case pushNotification(messageId: String, subject: String, sender: String)
    case mailboxItem(MailboxItemCellUIModel)

    var conversationId: PMLocalConversationId? {
        switch self {
        case .pushNotification:
            return nil
        case .mailboxItem(let conversationDetails):
            return conversationDetails.id
        }
    }

    var subject: String {
        switch self {
        case .pushNotification(_, let subject, _):
            return subject
        case .mailboxItem(let conversationDetails):
            return conversationDetails.subject
        }
    }

    var isStarStateKnown: Bool {
        if case .mailboxItem = self {
            return true
        }
        return false
    }

    var isStarred: Bool {
        switch self {
        case .pushNotification:
            return false
        case .mailboxItem(let conversationDetails):
            return conversationDetails.isStarred
        }
    }

    var numAttachments: Int {
        switch self {
        case .pushNotification:
            return 0
        case .mailboxItem(let conversationDetails):
            return conversationDetails.attachmentsUIModel.count
        }
    }
}

final class ConversationModel: Sendable, ObservableObject {
    @Published private(set) var state: State = .initial
    @Published private(set) var seed: ConversationScreenSeedUIModel

    private var mailbox: Mailbox?
    private var messagesLiveQuery: MailboxConversationMessagesLiveQuery?

    private let dependencies: Dependencies

    init(seed: ConversationScreenSeedUIModel, dependencies: Dependencies = .init()) {
        self.seed = seed
        self.dependencies = dependencies
    }

    func fetchData() async {
        await updateState(.fetchingMessages)
        guard let userSession = dependencies.appContext.activeUserSession else {
            AppLogger.log(message: "no user session found", category: .mailboxItemDetail, isError: true)
            return
        }
        do {
            mailbox = try await Mailbox.inbox(ctx: userSession)
            guard let mailbox, let conversationId = seed.conversationId else {
                AppLogger.log(message: "no mailbox object or conversationId", category: .mailboxItemDetail, isError: true)
                return
            }
            messagesLiveQuery = try await mailbox.newConversationMessagesLiveQuery(
                id: conversationId,
                cb: PMMailboxLiveQueryUpdatedCallback(delegate: self)
            )
            let messages = await readLiveQueryValues()
            if let lastMessage = messages.last, case .open(let last) = lastMessage.type {
                await updateState(.messagesReady(previous: messages.dropLast(), last: last))
            }
        } catch {
            AppLogger.log(error: error, category: .mailboxItemDetail)
        }
    }

    private func readLiveQueryValues() async -> [MessageCellUIModel] {
        do {
            guard let messagesLiveQuery else { return [] }
            let messages = try messagesLiveQuery.value()
            guard let lastMessage = messages.last else { return [] }
            var result = [MessageCellUIModel]()
            for i in messages.indices.dropLast() {
                let message = messages[i]
                let collapsedMessage = await message.toCollapsedMessageCellUIModel()
                result.append(.init(id: message.id, type: .collapsed(collapsedMessage)))
            }
            guard let mailbox else {
                AppLogger.log(message: "no mailbox object", category: .mailboxItemDetail, isError: true)
                return result
            }
            let openMessage = try await openMessageCellUIModel(for: lastMessage, mailbox: mailbox)
            result.append(.init(id: lastMessage.id, type: .open(openMessage)))
            return result
        } catch {
            AppLogger.log(error: error, category: .mailboxItemDetail)
            return []
        }
    }

    private func openMessageCellUIModel(
        for message: LocalMessageMetadata,
        mailbox: Mailbox
    ) async throws -> OpenMessageCellUIModel {
        let messageBody = try await mailbox.messageBody(id: message.id).body()
        return await message.toOpenMessageCellUIModel(message:"\n\n[MESSAGE BODY NOT IMPLEMENTED YET] \n\n Yours sincerely, \n The ET team.")
    }

    @MainActor
    private func updateState(_ newState: State) async {
        AppLogger.log(message: "conversation detail state \(newState.debugDescription)", category: .mailboxItemDetail)
        state = newState
    }
}

extension ConversationModel: MailboxLiveQueryUpdatedCallback {

    func onUpdated() {
        Task {
            await readLiveQueryValues()
        }
    }
}

extension ConversationModel {
    enum State {
        case initial
        case fetchingMessages
        case messagesReady(previous: [MessageCellUIModel], last: OpenMessageCellUIModel)

        var debugDescription: String {
            if case .messagesReady(let array, _) = self {
                return "messagesReady: \(array.count + 1) messages"
            }
            return "\(self)"
        }
    }
}

extension ConversationModel {

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
}

enum MessageCellUIModelType {
    case collapsed(CollapsedMessageCellUIModel)
    case open(OpenMessageCellUIModel)
}
