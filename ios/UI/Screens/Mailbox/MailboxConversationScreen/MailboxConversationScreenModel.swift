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

enum MailboxConversationScreenState: Sendable {
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

@Observable
final class MailboxConversationScreenModel {
    private let dependencies: Dependencies
    private(set) var state: MailboxConversationScreenState = .loading

    var conversations: [MailboxConversationCellUIModel] {
        state.conversations
    }

    var isLoading: Bool {
        state.isLoading
    }

    var isEmpty: Bool {
        state.isEmpty
    }

    init(conversations: [MailboxConversationCellUIModel] = [], dependencies: Dependencies = .init()) {
        self.state = conversations.isEmpty ? .empty : .data(conversations)
        self.dependencies = dependencies
    }

    func fecthConversations() async {
        do {
            await updateState(.loading)
            guard let userContext = try await dependencies.appContext.userContextForActiveSession() else {
                return
            }
            let mailbox = try Mailbox(ctx: userContext)
            let conversations = try mailbox.conversations(count: 50)
            await updateState(.data(conversations.map { $0.toMailboxConversationCellUIModel() }))
        } catch {
            print("❌ fetchConversations error: \(error)")
        }
    }

    @MainActor
    private func updateState(_ state: MailboxConversationScreenState) {
        self.state = state
    }

    @MainActor
    func onConversationSelectionChange(id: String, isSelected: Bool) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else {
            return
        }
        conversations[index].isSelected.set(isSelected)
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

extension MailboxConversationScreenModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}

extension LocalConversation {

    var initials: String {
        (senders.first?.senderName.prefix(2) ?? "P").uppercased()
    }

    func toLabel() -> MailboxLabelUIModel {
        guard 
            let labels = self.labels,
            let firstLabel = labels.first
        else { return .init() }
        return .init(
            id: String(firstLabel.id),
            color: Color(hex: firstLabel.color),
            text: firstLabel.name,
            numExtraLabels: labels.count
        )
    }

    func toMailboxConversationCellUIModel() -> MailboxConversationCellUIModel {
        .init(
            id: remoteId ?? String(id),
            avatar: .init(initials: initials),
            senders: senders.map(\.senderName).joined(separator: ", "),
            subject: subject,
            date: Date(timeIntervalSince1970: TimeInterval(time)),
            isRead: numUnread == 0,
            isStarred: false, // TODO:
            isSenderProtonOfficial: senders.first?.isProton.isTrue ?? false,
            numMessages: numMessages > 1 ? Int(numMessages) : 0,
            labelUIModel: toLabel(),
            expirationDate: .init(text: "", color: .black)
        )
    }
}

extension MessageAddress {

    var senderName: String {
        !name.isEmpty ? name : address
    }
}

extension ProtonBoolean {
    var isTrue: Bool {
        switch self {
        case .true: return true
        case .false: return false
        }
    }
}
