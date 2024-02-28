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

enum PreviewData {

    static let conversationMailboxModel = ConversationMailboxModel(conversations: [
        Conversation(id: UUID().uuidString, avatarImage: URL(fileURLWithPath: ""), senders: "Proton", subject: "Save up to 40% on our most popular plans", date: Calendar.current.date(byAdding: .minute, value: -1, to: Date())!, isRead: false, isStarred: false),
        Conversation(id: UUID().uuidString, avatarImage: URL(fileURLWithPath: ""), senders: "Mike Smith", subject: "Holidays in Greece!", date: Calendar.current.date(byAdding: .minute, value: -67, to: Date())!, isRead: true, isStarred: false),
        Conversation(id: UUID().uuidString, avatarImage: URL(fileURLWithPath: ""), senders: "Proton", subject: "Fundraiser end Monday: Last chance to win a Lifetime account, rare usernames", date: Calendar.current.date(byAdding: .minute, value: -5000, to: Date())!, isRead: true, isStarred: false),
        Conversation(id: UUID().uuidString, avatarImage: URL(fileURLWithPath: ""), senders: "Emma Sands", subject: "About today's meeting", date: Calendar.current.date(byAdding: .minute, value: -5000, to: Date())!, isRead: true, isStarred: false),
        Conversation(id: UUID().uuidString, avatarImage: URL(fileURLWithPath: ""), senders: "customersupport@example.com", subject: "Ticket #6457234", date: Calendar.current.date(byAdding: .minute, value: -8800, to: Date())!, isRead: false, isStarred: true),
        Conversation(id: UUID().uuidString, avatarImage: URL(fileURLWithPath: ""), senders: "Brad, Monica Lenders, Elisabeth", subject: "Beers at 7pm", date: Calendar.current.date(byAdding: .minute, value: -17500, to: Date())!, isRead: true, isStarred: true),
        Conversation(id: UUID().uuidString, avatarImage: URL(fileURLWithPath: ""), senders: "Proton", subject: "Get more out of your inbox", date: Calendar.current.date(byAdding: .minute, value: -40000, to: Date())!, isRead: true, isStarred: false),
    ])
}
