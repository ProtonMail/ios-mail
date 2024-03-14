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
final class MailboxConversationScreenModel {
    private let dependencies: Dependencies
    private(set) var state: State = .loading
    private(set) var mailbox: Mailbox?
    private(set) var conversationsLiveQuery: MailboxConversationLiveQuery?

    init(conversations: [MailboxConversationCellUIModel] = [], dependencies: Dependencies = .init()) {
        self.state = conversations.isEmpty ? .empty : .data(conversations)
        self.dependencies = dependencies
    }

    func onViewDidAppear() async {
        do {
            await updateState(.loading)
            try await initMailbox()
            try await fetchConversations()
        } catch {
            print("❌ onViewDidAppear error: \(error)")
        }
    }

    private func initMailbox() async throws {
        guard let userContext = try await dependencies.appContext.userContextForActiveSession() else {
            return
        }
        self.mailbox = try Mailbox(ctx: userContext)
    }

    private func fetchConversations() async throws {
        guard let mailbox else { return }
        let liveQuery = mailbox.newConversationObservedQuery(limit: 50, cb: self)
        conversationsLiveQuery = liveQuery
        await updateData()
    }

    private func updateData() async {
        guard let mailbox else { return }
        guard let conversationsLiveQuery else { return }
        var conversations = [MailboxConversationCellUIModel]()
        do {
            conversations = try mailbox.conversations(count: 50).map { $0.toMailboxConversationCellUIModel() }
        } catch {}
        //let conversations = // conversationsLiveQuery.value().map { $0.toMailboxConversationCellUIModel() }
        await updateState(.data(conversations))
    }

    @MainActor
    private func updateState(_ state: State) {
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
//            await updateData()
        }
    }
}

extension MailboxConversationScreenModel {

    enum State: Sendable {
        case loading
        case empty
        case data([MailboxConversationCellUIModel])

        var isEmpty: Bool {
            switch self {
            case .empty: return true
            case .loading, .data: return false
            }
        }

        var isLoading: Bool {
            switch self {
            case .loading: return true
            case .empty, .data: return false
            }
        }

        var conversations: [MailboxConversationCellUIModel] {
            switch self {
            case .data(let conversations): return conversations
            case .empty, .loading: return []
            }
        }
    }
}

extension MailboxConversationScreenModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
