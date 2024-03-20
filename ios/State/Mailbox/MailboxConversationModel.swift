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
import SwiftUI
import proton_mail_uniffi
import class UIKit.UIImage

/**
 Source of truth for the Mailbox view showing conversations.
 */
@Observable
final class MailboxConversationModel: MailboxConversationType, MailboxConversationOutput, Sendable {
    var input: MailboxConversationInput { self }
    var output: MailboxConversationOutput { self }

    private(set) var state: MailboxConversationModel.State

    private var selectedMailbox: SelectedMailbox
    private var conversationsLiveQuery: MailboxConversationLiveQuery?
    private let dependencies: Dependencies

    init(selectedMailbox: SelectedMailbox, state: State = .loading, dependencies: Dependencies = .init()) {
        let message = "MailboxConversationModel labelId \(selectedMailbox.name)"
        AppLogger.log(message: message, category: .mailboxConversations)
        self.state = state
        self.selectedMailbox = selectedMailbox
        self.dependencies = dependencies
    }

    func initialDataFetch() async {
        AppLogger.log(message: "initial conversation data fetch", category: .mailboxConversations)
        await fetchData()
    }

    func updateSelectedMailbox(_ selectedMailbox: SelectedMailbox) async {
        self.selectedMailbox = selectedMailbox
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
        guard let userContext = try await dependencies.appContext.userContextForActiveSession() else {
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
    private func updateState(_ newState: State) {
        AppLogger.logTemporarily(message: "updateState \(newState.debugDescription)", category: .mailboxConversations)
        state = newState
    }
}

// MARK: MailboxConversationInput

extension MailboxConversationModel: MailboxConversationInput {

    @MainActor
    func onConversationSelectionChange(id: String, isSelected: Bool) {
        guard let index = state.conversations.firstIndex(where: { $0.id == id }) else {
            return
        }
        state.conversations[index].isSelected.set(isSelected)
    }

    @MainActor
    func onConversationStarChange(id: String, isStarred: Bool) {
        // ...
    }

    @MainActor
    func onAttachmentTap(attachmentId: String) {
        print("Attachment tapped \(attachmentId)")
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
