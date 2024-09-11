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

import proton_app_uniffi
@testable import ProtonMail
import XCTest

final class MessageMappingTests: XCTestCase {
    private let defaultSubject = "Dummy subject"
    private let recipient1: MessageAddress = .testData(name: "The Rec.A", address: "a@example.com")
    private let recipient2: MessageAddress = .testData(name: "", address: "b@example.com")
    private let recipient3: MessageAddress = .testData(name: "The Rec.C", address: "c@example.com")
    private let sender: MessageAddress = .testData(name: "", address: "sender@example.com")

    func testToMailboxItemCellUIModel_whenNoSubject_itReturnsAPlaceholder() {
        let message1 = Message.testData(subject: "")
        let result1 = message1.toMailboxItemCellUIModel(selectedIds: [], displaySenderEmail: .random())
        XCTAssertEqual(result1.subject, "(No Subject)")

        let message2 = Message.testData(subject: defaultSubject)
        let result2 = message2.toMailboxItemCellUIModel(selectedIds: [], displaySenderEmail: .random())
        XCTAssertEqual(result2.subject, defaultSubject)
    }

    func testToMailboxItemCellUIModel_whenSelectedItems_itReturnsTheMessagesAsSelectedIfItMacthes() {
        let message = Message.testData(messageId: 33)

        let result1 = message.toMailboxItemCellUIModel(
            selectedIds: [.init(value: 12)], displaySenderEmail: .random()
        )
        XCTAssertFalse(result1.isSelected)

        let result2 = message.toMailboxItemCellUIModel(
            selectedIds: [.init(value: 33)], displaySenderEmail: .random()
        )
        XCTAssertTrue(result2.isSelected)
    }

    func testToMailboxItemCellUIModel_whenDoNotDisplaySenderEmail_itReturnsRecipientsInSenderField() {
        let message = Message.testData(to: [recipient1], cc: [recipient2], bcc: [recipient3])
        let result = message.toMailboxItemCellUIModel(selectedIds: [], displaySenderEmail: false)
        XCTAssertEqual(result.emails, "The Rec.A, b@example.com, The Rec.C")
    }

    func testToMailboxItemCellUIModel_whenDoNotDisplaySenderEmail_andNoRecipients_itReturnsAPlaceholder() {
        let message = Message.testData(to: [], cc: [], bcc: [])
        let result = message.toMailboxItemCellUIModel(selectedIds: [], displaySenderEmail: false)
        XCTAssertEqual(result.emails, "(No Recipient)")
    }

    func testToMailboxItemCellUIModel_whenDisplaySenderEmail_itReturnsTheSender() {
        let message = Message.testData(to: [recipient1], cc: [recipient2], bcc: [recipient3])
        let result = message.toMailboxItemCellUIModel(selectedIds: [], displaySenderEmail: true)
        XCTAssertEqual(result.emails, "sender@example.com")
    }
}

private extension MessageAddress {

    static func testData(name: String, address: String) -> Self {
        .init(
            address: address,
            bimiSelector: nil,
            displaySenderImage: .random(),
            isProton: .random(),
            isSimpleLogin: .random(),
            name: name
        )
    }

}

private extension Message {

    static func testData(
        messageId: UInt64 = UInt64.random(in: 0..<100),
        to: [MessageAddress] = [],
        cc: [MessageAddress] = [],
        bcc: [MessageAddress] = [],
        sender: MessageAddress = .testData(name: "", address: "sender@example.com"),
        subject: String = .notUsed
    ) -> Self {
        .init(
            id: .init(value: messageId),
            conversationId: .init(value: 31),
            addressId: .init(value: 32),
            attachmentsMetadata: [],
            bccList: bcc,
            ccList: cc,
            exclusiveLocation: nil,
            expirationTime: 1625140800,
            header: .notUsed,
            flags: .init(value: 2),
            isForwarded: true,
            isReplied: true,
            isRepliedAll: true,
            numAttachments: 1,
            displayOrder: 0,
            replyTos: [],
            sender: sender,
            size: 1_024,
            snoozeTime: 0,
            subject: subject,
            time: 1622548800,
            toList: to,
            unread: true,
            customLabels: [],
            starred: true, 
            avatar: .init(text: .notUsed, color: .notUsed)
        )
    }

}

extension String {
    static let notUsed = "__NOT_USED__"
}
