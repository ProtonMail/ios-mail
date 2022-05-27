// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
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
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import CoreData
import XCTest

@testable import ProtonMail

class SwipeableItemTests: XCTestCase {
    private var coreDataContextProviderMock: CoreDataContextProviderProtocol!
    private var conversation: Conversation!
    private var message: Message!

    private let conversationID = "some conversation ID"
    private let messageID = "some message ID"
    private let inboxLabel = Message.Location.inbox.labelID

    private var testContext: NSManagedObjectContext {
        coreDataContextProviderMock.rootSavingContext
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        coreDataContextProviderMock = MockCoreDataContextProvider()

        conversation = Conversation(context: testContext)
        conversation.conversationID = conversationID
        conversation.applyLabelChanges(labelID: inboxLabel.rawValue, apply: true, context: testContext)

        message = Message(context: testContext)
        message.messageID = messageID
        message.conversationID = conversationID
    }

    override func tearDownWithError() throws {
        testContext.registeredObjects.forEach(testContext.delete)

        conversation = nil
        message = nil
        coreDataContextProviderMock = nil

        try super.tearDownWithError()
    }

    func testIsStarredMessage() throws {
        let nonStarredMessage = MessageEntity(message)
        let nonStarredSUT = SwipeableItem.message(nonStarredMessage)
        XCTAssertFalse(nonStarredSUT.isStarred)

        let starredLabel = Label(context: testContext)
        starredLabel.labelID = Message.Location.starred.rawValue
        message.add(labelID: starredLabel.labelID)

        let starredMessageEntity = MessageEntity(message)
        let starredSUT = SwipeableItem.message(starredMessageEntity)
        XCTAssert(starredSUT.isStarred)
    }

    func testIsStarredConversation() throws {
        let nonStarredConversation = ConversationEntity(conversation)
        let nonStarredSUT = SwipeableItem.conversation(nonStarredConversation)
        XCTAssertFalse(nonStarredSUT.isStarred)

        conversation.applyLabelChanges(labelID: Message.Location.starred.rawValue, apply: true, context: testContext)

        let starredConversationEntity = ConversationEntity(conversation)
        let starredSUT = SwipeableItem.conversation(starredConversationEntity)
        XCTAssert(starredSUT.isStarred)
    }

    func testItemIDMessage() throws {
        let messageEntity = MessageEntity(message)
        let sut = SwipeableItem.message(messageEntity)
        XCTAssertEqual(sut.itemID, messageID)
    }

    func testItemIDConversation() throws {
        let conversationEntity = ConversationEntity(conversation)
        let sut = SwipeableItem.conversation(conversationEntity)
        XCTAssertEqual(sut.itemID, conversationID)
    }

    func testIsUnreadMessage() throws {
        let unreadMessage = MessageEntity(message)
        let unreadSUT = SwipeableItem.message(unreadMessage)
        XCTAssert(unreadSUT.isUnread(labelID: inboxLabel))

        message.unRead = false

        let readMessage = MessageEntity(message)
        let readSUT = SwipeableItem.message(readMessage)
        XCTAssertFalse(readSUT.isUnread(labelID: inboxLabel))
    }

    func testIsUnreadConversation() throws {
        conversation.applyMarksAsChanges(unRead: true, labelID: inboxLabel.rawValue, context: testContext)

        let unreadConversation = ConversationEntity(conversation)
        let unreadSUT = SwipeableItem.conversation(unreadConversation)
        XCTAssert(unreadSUT.isUnread(labelID: inboxLabel))

        conversation.applyMarksAsChanges(unRead: false, labelID: inboxLabel.rawValue, context: testContext)

        let readConversation = ConversationEntity(conversation)
        let readSUT = SwipeableItem.conversation(readConversation)
        XCTAssertFalse(readSUT.isUnread(labelID: inboxLabel))
    }
}
