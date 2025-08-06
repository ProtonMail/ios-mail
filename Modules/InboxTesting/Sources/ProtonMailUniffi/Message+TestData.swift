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

extension Message {
    public static func testData(
        messageId: UInt64 = UInt64.random(in: 0..<100),
        to: [MessageRecipient] = [],
        cc: [MessageRecipient] = [],
        bcc: [MessageRecipient] = [],
        sender: MessageSender = .testData(name: "", address: "sender@example.com")
    ) -> Self {
        .init(
            id: .init(value: messageId),
            conversationId: .init(value: 31),
            addressId: .init(value: 32),
            attachmentsMetadata: [],
            bccList: bcc,
            ccList: cc,
            exclusiveLocation: .system(name: .inbox, id: .init(value: 33)),
            expirationTime: 1625140800,
            flags: .init(value: 2),
            isForwarded: true,
            isReplied: true,
            isRepliedAll: true,
            numAttachments: 1,
            displayOrder: 0,
            sender: sender,
            size: 1_024,
            snoozeTime: 0,
            displaySnoozeReminder: false,
            subject: .notUsed,
            time: 1622548800,
            toList: to,
            unread: true,
            customLabels: [],
            starred: true,
            avatar: .init(text: .notUsed, color: .notUsed),
            isDraft: false,
            isScheduled: false,
            canReply: true
        )
    }
}

extension String {
    static let notUsed = "__NOT_USED__"
}
