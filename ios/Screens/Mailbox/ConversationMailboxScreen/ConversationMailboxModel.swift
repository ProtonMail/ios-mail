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

typealias ConversationId = String

@Observable
final class Conversation: Identifiable {
    let id: String
    let avatarImage: URL
    let senders: String
    let subject: String
    let date: Date
    let isRead: Bool
    let isStarred: Bool
    var isSelected: Bool = false

    init(id: String, avatarImage: URL, senders: String, subject: String, date: Date, isRead: Bool, isStarred: Bool) {
        self.id = id
        self.avatarImage = avatarImage
        self.senders = senders
        self.subject = subject
        self.date = date
        self.isRead = isRead
        self.isStarred = isStarred
    }
}

@Observable
final class ConversationMailboxModel {
    private(set) var conversations: [Conversation]

    init(conversations: [Conversation]) {
        self.conversations = conversations
    }

    @MainActor
    func onConversationSelectionChange(id: String, isSelected: Bool) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else {
            return
        }
        conversations[index].isSelected = isSelected
    }

    @MainActor
    func onConversationStarChange(id: String, isStarred: Bool) {
//        Task {
//             RustSDK.star(conversationId: id, isStarred: isStarred)
//        }
    }
}
