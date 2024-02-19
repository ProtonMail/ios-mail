// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import XCTest

@testable import ProtonMail

class MailboxItemTests: XCTestCase {
    private let conversationID = ConversationID("some conversation ID")
    private let messageID = MessageID("some message ID")
    private let inboxLabel = Message.Location.inbox.labelID

    func testExpirationTime_message() {
        let date = Date()
        let entity = MessageEntity.make(expirationTime: date)
        let sut = MailboxItem.message(entity)
        XCTAssertEqual(sut.expirationTime, date)
    }

    func testExpirationTime_conversation() {
        let date = Date()
        let entity = ConversationEntity.make(expirationTime: date)
        let sut = MailboxItem.conversation(entity)
        XCTAssertEqual(sut.expirationTime, date)
    }

    func testIsScheduledForSending_message() {
        let nonScheduledEntity = MessageEntity.make()
        let nonScheduledSUT = MailboxItem.message(nonScheduledEntity)
        XCTAssertFalse(nonScheduledSUT.isScheduledForSending)

        let scheduledEntity = MessageEntity.make(rawFlag: MessageFlag.scheduledSend.rawValue)
        let scheduledSUT = MailboxItem.message(scheduledEntity)
        XCTAssert(scheduledSUT.isScheduledForSending)
    }

    func testIsScheduledForSending_conversation() {
        let nonScheduledEntity = ConversationEntity.make()
        let nonScheduledSUT = MailboxItem.conversation(nonScheduledEntity)
        XCTAssertFalse(nonScheduledSUT.isScheduledForSending)

        let scheduledEntity = ConversationEntity.make(
            contextLabelRelations: [.make(labelID: Message.Location.scheduled.labelID)]
        )
        let scheduledSUT = MailboxItem.conversation(scheduledEntity)
        XCTAssert(scheduledSUT.isScheduledForSending)
    }

    func testIsStarred_message() throws {
        let nonStarredMessage = MessageEntity.make()
        let nonStarredSUT = MailboxItem.message(nonStarredMessage)
        XCTAssertFalse(nonStarredSUT.isStarred)

        let starredMessageEntity = MessageEntity.make(
            labels: [.make(labelID: LabelID(Message.Location.starred.rawValue))]
        )
        let starredSUT = MailboxItem.message(starredMessageEntity)
        XCTAssert(starredSUT.isStarred)
    }

    func testIsStarred_conversation() throws {
        let nonStarredConversation = ConversationEntity.make()
        let nonStarredSUT = MailboxItem.conversation(nonStarredConversation)
        XCTAssertFalse(nonStarredSUT.isStarred)

        let starredConversationEntity = ConversationEntity.make(
            contextLabelRelations: [.make(labelID: LabelID(Message.Location.starred.rawValue))]
        )
        let starredSUT = MailboxItem.conversation(starredConversationEntity)
        XCTAssert(starredSUT.isStarred)
    }

    func testItemID_message() throws {
        let messageEntity = MessageEntity.make(messageID: messageID)
        let sut = MailboxItem.message(messageEntity)
        XCTAssertEqual(sut.itemID, messageID.rawValue)
    }

    func testItemID_conversation() throws {
        let conversationEntity = ConversationEntity.make(conversationID: conversationID)
        let sut = MailboxItem.conversation(conversationEntity)
        XCTAssertEqual(sut.itemID, conversationID.rawValue)
    }

    func testIsUnread_message() throws {
        let unreadMessage = MessageEntity.make(unRead: true)
        let unreadSUT = MailboxItem.message(unreadMessage)
        XCTAssert(unreadSUT.isUnread(labelID: inboxLabel))

        let readMessage = MessageEntity.make(unRead: false)
        let readSUT = MailboxItem.message(readMessage)
        XCTAssertFalse(readSUT.isUnread(labelID: inboxLabel))
    }

    func testIsUnread_conversation() throws {
        let unreadConversation = ConversationEntity.make(
            contextLabelRelations: [.make(unreadCount: 1, labelID: inboxLabel)]
        )
        let unreadSUT = MailboxItem.conversation(unreadConversation)
        XCTAssert(unreadSUT.isUnread(labelID: inboxLabel))

        let readConversation = ConversationEntity.make(
            contextLabelRelations: [.make(unreadCount: 0, labelID: inboxLabel)]
        )
        let readSUT = MailboxItem.conversation(readConversation)
        XCTAssertFalse(readSUT.isUnread(labelID: inboxLabel))
    }

    func testTime_message() {
        let date = Date()
        let entity = MessageEntity.make(time: date)
        let sut = MailboxItem.message(entity)
        XCTAssertEqual(sut.time(labelID: inboxLabel), date)
    }

    func testTime_conversation() {
        let date = Date()
        let entity = ConversationEntity.make(contextLabelRelations: [.make(time: date, labelID: inboxLabel)])
        let sut = MailboxItem.conversation(entity)
        XCTAssertEqual(sut.time(labelID: inboxLabel), date)
    }

    func testPreviewableAttachmenstDoNotContainInlineAttachments() {
        let attachmentMetadataInline = AttachmentsMetadata(id: String.randomString(Int.random(in: 0..<10)),
                                                           name: String.randomString(Int.random(in: 0..<10)),
                                                           size: Int.random(in: 0..<10),
                                                           mimeType: String.randomString(Int.random(in: 0..<10)),
                                                           disposition: .inline)
        let attachmentMetadataAttachment = AttachmentsMetadata(id: String.randomString(Int.random(in: 0..<10)),
                                                               name: String.randomString(Int.random(in: 0..<10)),
                                                               size: Int.random(in: 0..<10),
                                                               mimeType: String.randomString(Int.random(in: 0..<10)),
                                                               disposition: .attachment)
        let entity = ConversationEntity.make(attachmentsMetadata: [attachmentMetadataAttachment, attachmentMetadataInline])
        let sut = MailboxItem.conversation(entity)
        XCTAssertEqual(sut.previewableAttachments.count, 1)
        XCTAssertEqual(sut.previewableAttachments[0], attachmentMetadataAttachment)
    }
}
