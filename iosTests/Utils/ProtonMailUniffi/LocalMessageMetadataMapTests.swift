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

import proton_mail_uniffi
@testable import ProtonMail
import XCTest

final class LocalMessageMetadataMapTests: XCTestCase {
    static private let defaultSubject = "Dummy subject"
    static private let recipient1 = makeMessageAddress(withName: "The Rec.A", address: "a@example.com")
    static private let recipient2 = makeMessageAddress(withName: "", address: "b@example.com")
    static private let recipient3 = makeMessageAddress(withName: "The Rec.C", address: "c@example.com")
    private let sender = makeMessageAddress(withName: "", address: "sender@example.com")

    func testToMailboxItemCellUIModel_whenNoSubject_itReturnsAPlaceholder() async {
        let message1 = makeLocalMessageMetadata(subject: "")
        let result1 = await message1.toMailboxItemCellUIModel(selectedIds: [], mapRecipientsAsSender: Bool.random())
        XCTAssertEqual(result1.subject, "(No Subject)")

        let message2 = makeLocalMessageMetadata()
        let result2 = await message2.toMailboxItemCellUIModel(selectedIds: [], mapRecipientsAsSender: Bool.random())
        XCTAssertEqual(result2.subject, Self.defaultSubject)
    }

    func testToMailboxItemCellUIModel_whenSelectedItems_itReturnsTheMessagesAsSelectedIfItMacthes() async {
        let message = makeLocalMessageMetadata(messageId: 33)

        let result1 = await message.toMailboxItemCellUIModel(selectedIds: [12], mapRecipientsAsSender: Bool.random())
        XCTAssertFalse(result1.isSelected)

        let result2 = await message.toMailboxItemCellUIModel(selectedIds: [33], mapRecipientsAsSender: Bool.random())
        XCTAssertTrue(result2.isSelected)
    }

    func testToMailboxItemCellUIModel_whenMappingRecipientsAsSender_itReturnsRecipientsInSenderField() async {
        let message = makeLocalMessageMetadata()
        let result = await message.toMailboxItemCellUIModel(selectedIds: [], mapRecipientsAsSender: true)
        XCTAssertEqual(result.senders, "The Rec.A, b@example.com, The Rec.C")
    }

    func testToMailboxItemCellUIModel_whenMappingRecipientsAsSender_andNoRecipients_itReturnsAPlaceholder() async {
        let message = makeLocalMessageMetadata(to: [], cc: [], bcc: [])
        let result = await message.toMailboxItemCellUIModel(selectedIds: [], mapRecipientsAsSender: true)
        XCTAssertEqual(result.senders, "(No Recipient)")
    }

    func testToMailboxItemCellUIModel_whenNotMappingRecipientsAsSender_itReturnsTheSender() async {
        let message = makeLocalMessageMetadata()
        let result = await message.toMailboxItemCellUIModel(selectedIds: [], mapRecipientsAsSender: false)
        XCTAssertEqual(result.senders, "sender@example.com")
    }
}

extension LocalMessageMetadataMapTests {

    private static func makeMessageAddress(withName name: String, address: String) -> MessageAddress {
        MessageAddress(
            address: address,
            name: name,
            isProton: Bool.random(),
            displaySenderImage: Bool.random(),
            isSimpleLogin: Bool.random(),
            bimiSelector: nil
        )
    }

    private func makeLocalMessageMetadata(
        messageId: UInt64 = UInt64.random(in: 0..<100),
        subject: String = defaultSubject,
        to: [MessageAddress] = [recipient1],
        cc: [MessageAddress] = [recipient2],
        bcc: [MessageAddress] = [recipient3]
    ) -> LocalMessageMetadata {
        LocalMessageMetadata(
            id: messageId,
            rid: nil,
            conversationId: 31,
            addressId: "32",
            order: 0,
            subject: subject,
            unread: true,
            sender: sender,
            to: to,
            cc: cc,
            bcc: bcc,
            time: 1622548800,
            size: 1024,
            expirationTime: 1625140800,
            snoozeTime: 0,
            isReplied: true,
            isRepliedAll: true,
            isForwarded: true,
            externalId: nil,
            numAttachments: 1,
            flags: 2,
            starred: true,
            attachments: [],
            labels: [],
            avatarInformation: .init(text: "JV", color: "blue")
        )
    }
}
