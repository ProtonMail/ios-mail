//
// Copyright (c) 2025 Proton Technologies AG
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

import proton_app_uniffi

extension Conversation {
    public static func testData(
        conversationId: UInt64 = UInt64.random(in: 0..<100),
        senders: [MessageSender] = [.testData(name: "", address: "sender@example.com")],
        recipients: [MessageRecipient] = [.testData(name: "", address: "recipient@example.com")]
    ) -> Self {
        .init(
            id: .init(value: conversationId),
            attachmentsMetadata: [],
            customLabels: [],
            displaySnoozeReminder: false,
            snoozedUntil: nil,
            locations: [.system(name: .inbox, id: .init(value: 41))],
            expirationTime: 1_625_140_800,
            isStarred: true,
            numAttachments: 0,
            numMessages: 1,
            numUnread: 1,
            totalMessages: 1,
            totalUnread: 1,
            displayOrder: 0,
            recipients: recipients,
            senders: senders,
            size: 1_024,
            subject: .notUsed,
            time: 1_622_548_800,
            avatar: .init(text: .notUsed, color: .notUsed),
            hiddenMessagesBanner: nil
        )
    }
}
