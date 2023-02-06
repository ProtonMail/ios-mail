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

import CoreData
import XCTest

@testable import ProtonMail

class MailboxItemTests: XCTestCase {
    private var conversation: Conversation!
    private var message: Message!
    private var testContext: NSManagedObjectContext!

    private let conversationID = "some conversation ID"
    private let messageID = "some message ID"
    private let inboxLabel = Message.Location.inbox.labelID

    override func setUpWithError() throws {
        try super.setUpWithError()

        testContext = MockCoreDataStore.testPersistentContainer.viewContext

        conversation = Conversation(context: testContext)
        conversation.conversationID = conversationID
        conversation.applyLabelChanges(labelID: inboxLabel.rawValue, apply: true)

        message = Message(context: testContext)
        message.messageID = messageID
        message.conversationID = conversationID
    }

    override func tearDownWithError() throws {
        testContext.registeredObjects.forEach(testContext.delete)

        conversation = nil
        message = nil
        testContext = nil

        try super.tearDownWithError()
    }

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
        let nonStarredMessage = MessageEntity(message)
        let nonStarredSUT = MailboxItem.message(nonStarredMessage)
        XCTAssertFalse(nonStarredSUT.isStarred)

        let starredLabel = Label(context: testContext)
        starredLabel.labelID = Message.Location.starred.rawValue
        message.add(labelID: starredLabel.labelID)

        let starredMessageEntity = MessageEntity(message)
        let starredSUT = MailboxItem.message(starredMessageEntity)
        XCTAssert(starredSUT.isStarred)
    }

    func testIsStarred_conversation() throws {
        let nonStarredConversation = ConversationEntity(conversation)
        let nonStarredSUT = MailboxItem.conversation(nonStarredConversation)
        XCTAssertFalse(nonStarredSUT.isStarred)

        conversation.applyLabelChanges(labelID: Message.Location.starred.rawValue, apply: true)

        let starredConversationEntity = ConversationEntity(conversation)
        let starredSUT = MailboxItem.conversation(starredConversationEntity)
        XCTAssert(starredSUT.isStarred)
    }

    func testItemID_message() throws {
        let messageEntity = MessageEntity(message)
        let sut = MailboxItem.message(messageEntity)
        XCTAssertEqual(sut.itemID, messageID)
    }

    func testItemID_conversation() throws {
        let conversationEntity = ConversationEntity(conversation)
        let sut = MailboxItem.conversation(conversationEntity)
        XCTAssertEqual(sut.itemID, conversationID)
    }

    func testObjectID_message() throws {
        let entity = MessageEntity(message)
        let sut = MailboxItem.message(entity)
        XCTAssertEqual(sut.objectID.rawValue, message.objectID)
    }

    func testObjectID_conversation() throws {
        let entity = ConversationEntity(conversation)
        let sut = MailboxItem.conversation(entity)
        XCTAssertEqual(sut.objectID.rawValue, conversation.objectID)
    }

    func testIsUnread_message() throws {
        let unreadMessage = MessageEntity(message)
        let unreadSUT = MailboxItem.message(unreadMessage)
        XCTAssert(unreadSUT.isUnread(labelID: inboxLabel))

        message.unRead = false

        let readMessage = MessageEntity(message)
        let readSUT = MailboxItem.message(readMessage)
        XCTAssertFalse(readSUT.isUnread(labelID: inboxLabel))
    }

    func testIsUnread_conversation() throws {
        conversation.applyMarksAsChanges(unRead: true, labelID: inboxLabel.rawValue)

        let unreadConversation = ConversationEntity(conversation)
        let unreadSUT = MailboxItem.conversation(unreadConversation)
        XCTAssert(unreadSUT.isUnread(labelID: inboxLabel))

        conversation.applyMarksAsChanges(unRead: false, labelID: inboxLabel.rawValue)

        let readConversation = ConversationEntity(conversation)
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
}
