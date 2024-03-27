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

import Combine
import Foundation
import SwiftUI
import proton_mail_uniffi
import class UIKit.UIImage

/**
 Source of truth for the Mailbox view showing conversations.
 */
final class MailboxConversationModel: ObservableObject {
    @ObservedObject var appRoute: AppRoute
    @Published private(set) var state: MailboxConversationModel.State

    private var mailbox: Mailbox?
    private var liveQuery: MailboxConversationLiveQuery?
    private let dependencies: Dependencies
    private var cancellables = Set<AnyCancellable>()


    init(appRoute: AppRoute, state: State = .loading, dependencies: Dependencies = .init()) {
        self.appRoute = appRoute
        self.state = state
        self.dependencies = dependencies

        appRoute
            .$selectedMailbox
            .sink { [weak self] value in
                Task {
                    try? await self?.updateMailboxAndFetchData(selectedMailbox: appRoute.selectedMailbox)
                }
            }
            .store(in: &cancellables)
    }

    func updateMailboxAndFetchData(selectedMailbox: SelectedMailbox) async throws {
        guard let userContext = try await dependencies.appContext.userContextForActiveSession() else { return }
        mailbox = Mailbox(ctx: userContext, labelId: selectedMailbox.localId)
        await fetchData()
    }
}

// MARK: Private

extension MailboxConversationModel {

    private func fetchData() async {
        do {
            await updateState(.loading)
            try await fetchConversations()
        } catch {
            AppLogger.log(error: error, category: .rustLibrary)
        }
    }

    private func fetchConversations() async throws {
        self.liveQuery = mailbox?.newConversationLiveQuery(limit: 50, cb: self)
        await updateData()
    }

    private func updateData() async {
        guard let liveQuery else { return }
        let conversations = liveQuery.value().map { $0.toMailboxConversationCellUIModel() }
        await updateState(.data(conversations))
    }

    @MainActor
    private func updateState(_ newState: State) async {
        AppLogger.logTemporarily(message: "updateState \(newState.debugDescription)", category: .mailboxConversations)
        state = newState
    }
}

// MARK: View actions

extension MailboxConversationModel {

    @MainActor
    func onConversationSelectionChange(id: PMLocalConversationId, isSelected: Bool) {
        guard let index = state.conversations.firstIndex(where: { $0.id == id }) else {
            return
        }
        state.conversations[index].isSelected.set(isSelected)
    }

    @MainActor
    func onConversationStarChange(id: PMLocalConversationId, isStarred: Bool) {
        // ...
    }

    @MainActor
    func onAttachmentTap(attachmentId: String) {
        print("Attachment tapped \(attachmentId)")
    }

    @MainActor
    func onConversationsSetReadStatus(to newStatus: MailboxReadStatus, for ids: [PMLocalConversationId]) {
        AppLogger.log(message: "Conversation set read status \(ids)...", category: .mailboxActions)
        do {
            if case .read = newStatus {
                try mailbox?.markConversationsRead(ids: ids)
            } else if case .unread = newStatus {
                try mailbox?.markConversationsUnread(ids: ids)
            }
        } catch {
            AppLogger.log(error: error, category: .mailboxActions)
        }
    }

    @MainActor
    func onConversationsDeletion(ids: [PMLocalConversationId]) {
        AppLogger.log(message: "Conversation deletion \(ids)...", category: .mailboxActions)
        do {
            try mailbox?.deleteConversations(ids: ids)
        } catch {
            AppLogger.log(error: error, category: .mailboxActions)
        }
    }

    @MainActor
    func onConversationAction(
        _ swipeAction: SwipeAction,
        conversationId: PMLocalConversationId,
        newReadStatus: MailboxReadStatus? = nil
    ) {
        switch swipeAction {
        case .none:
            break
        case .delete:
            onConversationsDeletion(ids: [conversationId])
        case .toggleReadStatus:
            guard let newReadStatus else { return }
            onConversationsSetReadStatus(to: newReadStatus, for: [conversationId])
        }
    }
}

// MARK: MailboxLiveQueryUpdatedCallback

extension MailboxConversationModel: MailboxLiveQueryUpdatedCallback {

    func onUpdated() {
        Task {
            await updateData()
        }
    }
}

extension MailboxConversationModel {

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

extension MailboxConversationModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
