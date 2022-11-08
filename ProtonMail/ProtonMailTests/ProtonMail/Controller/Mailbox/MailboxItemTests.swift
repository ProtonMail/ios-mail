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

class SwipeableItemTests: XCTestCase {
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

    func testIsStarredMessage() throws {
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

    func testIsStarredConversation() throws {
        let nonStarredConversation = ConversationEntity(conversation)
        let nonStarredSUT = MailboxItem.conversation(nonStarredConversation)
        XCTAssertFalse(nonStarredSUT.isStarred)

        conversation.applyLabelChanges(labelID: Message.Location.starred.rawValue, apply: true)

        let starredConversationEntity = ConversationEntity(conversation)
        let starredSUT = MailboxItem.conversation(starredConversationEntity)
        XCTAssert(starredSUT.isStarred)
    }

    func testItemIDMessage() throws {
        let messageEntity = MessageEntity(message)
        let sut = MailboxItem.message(messageEntity)
        XCTAssertEqual(sut.itemID, messageID)
    }

    func testItemIDConversation() throws {
        let conversationEntity = ConversationEntity(conversation)
        let sut = MailboxItem.conversation(conversationEntity)
        XCTAssertEqual(sut.itemID, conversationID)
    }

    func testIsUnreadMessage() throws {
        let unreadMessage = MessageEntity(message)
        let unreadSUT = MailboxItem.message(unreadMessage)
        XCTAssert(unreadSUT.isUnread(labelID: inboxLabel))

        message.unRead = false

        let readMessage = MessageEntity(message)
        let readSUT = MailboxItem.message(readMessage)
        XCTAssertFalse(readSUT.isUnread(labelID: inboxLabel))
    }

    func testIsUnreadConversation() throws {
        conversation.applyMarksAsChanges(unRead: true, labelID: inboxLabel.rawValue)

        let unreadConversation = ConversationEntity(conversation)
        let unreadSUT = MailboxItem.conversation(unreadConversation)
        XCTAssert(unreadSUT.isUnread(labelID: inboxLabel))

        conversation.applyMarksAsChanges(unRead: false, labelID: inboxLabel.rawValue)

        let readConversation = ConversationEntity(conversation)
        let readSUT = MailboxItem.conversation(readConversation)
        XCTAssertFalse(readSUT.isUnread(labelID: inboxLabel))
    }
}
