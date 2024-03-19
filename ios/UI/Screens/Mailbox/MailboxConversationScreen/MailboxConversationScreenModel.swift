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
import struct SwiftUI.Color
import proton_mail_uniffi
import class UIKit.UIImage

@Observable
final class MailboxConversationScreenModel: Sendable {
    private var selectedMailbox: SelectedMailbox?
    private let dependencies: Dependencies
    private(set) var state: State = .loading
    private(set) var conversationsLiveQuery: MailboxConversationLiveQuery?

    init(
        selectedMailbox: SelectedMailbox? = nil,
        conversations: [MailboxConversationCellUIModel] = [],
        dependencies: Dependencies = .init()
    ) {
        AppLogger.log(message: "MailboxConversationScreenModel labelId \(selectedMailbox?.name ?? "-")", category: .mailboxConversations)
        self.selectedMailbox = selectedMailbox
        self.state = conversations.isEmpty ? .empty : .data(conversations)
        self.dependencies = dependencies
        Task {
            await self.fetchData()
        }
    }

    func onNewSelectedMailbox(selectedMailbox: SelectedMailbox) {
        self.selectedMailbox = selectedMailbox
        Task {
            await fetchData()
        }
    }

    func fetchData() async {
        do {
            await updateState(.loading)
            try await fetchConversations()
        } catch {
            AppLogger.log(error: error, category: .rustLibrary)
        }
    }

    private func fetchConversations() async throws {
        guard
            let selectedMailbox,
            let userContext = try await dependencies.appContext.userContextForActiveSession()
        else {
            return
        }
        let mailbox = Mailbox(ctx: userContext, labelId: selectedMailbox.localId)
        let liveQuery = mailbox.newConversationLiveQuery(limit: 50, cb: self)
        self.conversationsLiveQuery = liveQuery
        await updateData()
    }

    private func updateData() async {
        guard let conversationsLiveQuery else { return }
        let conversations = conversationsLiveQuery.value().map { $0.toMailboxConversationCellUIModel() }
        await updateState(.data(conversations))
    }

    @MainActor
    private func updateState(_ state: State) {
        AppLogger.logTemporarily(message: "updateState \(state.debugDescription)", category: .mailboxConversations)
        self.state = state
    }

    @MainActor
    func onConversationSelectionChange(id: String, isSelected: Bool) {
        guard let index = state.conversations.firstIndex(where: { $0.id == id }) else {
            return
        }
        state.conversations[index].isSelected.set(isSelected)
    }

    func onConversationStarChange(id: String, isStarred: Bool) {
//        Task {
//             RustSDK.star(conversationId: id, isStarred: isStarred)
//        }
    }

    @MainActor
    func onAttachmentTap(attachmentId: String) {
        print("Attachment tapped \(attachmentId)")
    }
}

extension MailboxConversationScreenModel: MailboxLiveQueryUpdatedCallback {
    func onUpdated() {
        Task {
            await updateData()
        }
    }
}

extension MailboxConversationScreenModel: MailboxBackgroundResult {
    func onBackgroundResult(error: proton_mail_uniffi.MailboxError?) {
        guard let error else { return }
        AppLogger.log(error: error)
    }
}

extension MailboxConversationScreenModel {

    enum State: Sendable {
        case loading
        case empty
        case data([MailboxConversationCellUIModel])

        var conversations: [MailboxConversationCellUIModel] {
            switch self {
            case .data(let conversations): return conversations
            case .empty, .loading: return []
            }
        }

        var debugDescription: String {
            if case .data(let array) = self {
                return "data \(array.count) conversations"
            }
            return "\(self)"
        }
    }
}

extension MailboxConversationScreenModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
