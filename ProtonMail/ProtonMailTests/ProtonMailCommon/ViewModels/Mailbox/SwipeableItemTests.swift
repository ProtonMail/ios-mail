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
    private let inboxLabel = Message.Location.inbox.rawValue

    private var testContext: NSManagedObjectContext {
        coreDataContextProviderMock.rootSavingContext
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        coreDataContextProviderMock = MockCoreDataContextProvider()

        conversation = Conversation(context: testContext)
        conversation.conversationID = conversationID
        conversation.applyLabelChanges(labelID: inboxLabel, apply: true, context: testContext)

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
        let starredLabel = Label(context: testContext)
        starredLabel.labelID = Message.Location.starred.rawValue
        let sut = SwipeableItem.message(message)

        XCTAssertFalse(sut.isStarred)

        message.add(labelID: starredLabel.labelID)

        XCTAssert(sut.isStarred)
    }

    func testIsStarredConversation() throws {
        let sut = SwipeableItem.conversation(conversation)

        XCTAssertFalse(sut.isStarred)

        conversation.applyLabelChanges(labelID: Message.Location.starred.rawValue, apply: true, context: testContext)

        XCTAssert(sut.isStarred)
    }

    func testItemIDMessage() throws {
        let sut = SwipeableItem.message(message)
        XCTAssertEqual(sut.itemID, messageID)
    }

    func testItemIDConversation() throws {
        let sut = SwipeableItem.conversation(conversation)
        XCTAssertEqual(sut.itemID, conversationID)
    }

    func testIsUnreadMessage() throws {
        let sut = SwipeableItem.message(message)

        XCTAssert(sut.isUnread(labelID: inboxLabel))

        message.unRead = false

        XCTAssertFalse(sut.isUnread(labelID: inboxLabel))
    }

    func testIsUnreadConversation() throws {
        let sut = SwipeableItem.conversation(conversation)

        conversation.applyMarksAsChanges(unRead: true, labelID: inboxLabel, context: testContext)
        XCTAssert(sut.isUnread(labelID: inboxLabel))

        conversation.applyMarksAsChanges(unRead: false, labelID: inboxLabel, context: testContext)
        XCTAssertFalse(sut.isUnread(labelID: inboxLabel))
    }
}
