// Copyright (c) 2022 Proton AG
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

import CoreData
import XCTest

@testable import ProtonMail

class ConversationEntityTests: XCTestCase {
    private var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        let contextProviderMock = MockCoreDataContextProvider()
        testContext = contextProviderMock.viewContext
    }

    override func tearDown() {
        testContext = nil

        super.tearDown()
    }

    func testInit() throws {
        // Make test data

        let testObject = Conversation(context: testContext)
        testObject.conversationID = String.randomString(20)
        testObject.expirationTime = nil
        testObject.numAttachments = NSNumber(value: 1)
        testObject.numMessages = NSNumber(value: 1)
        testObject.order = NSNumber(value: 100)
        testObject.senders = String.randomString(10)
        testObject.recipients = String.randomString(10)
        testObject.isSoftDeleted = Bool.random()
        testObject.size = NSNumber(value: 1000)
        testObject.subject = String.randomString(100)
        testObject.userID = String.randomString(20)

        let testLabel = ContextLabel(context: testContext)
        testLabel.messageCount = NSNumber(value: 1)
        testLabel.unreadCount = NSNumber(value: 1)
        testLabel.time = Date()
        testLabel.size = NSNumber(value: 1000)
        testLabel.attachmentCount = NSNumber(value: 1)
        testLabel.conversationID = testObject.conversationID
        testLabel.labelID = Message.Location.inbox.labelID.rawValue
        testLabel.userID = testObject.userID
        testLabel.order = NSNumber(value: 100)
        testLabel.isSoftDeleted = testObject.isSoftDeleted

        let testLabel2 = ContextLabel(context: testContext)
        testLabel2.messageCount = NSNumber(value: 1)
        testLabel2.unreadCount = NSNumber(value: 1)
        testLabel2.time = Date()
        testLabel2.size = NSNumber(value: 1000)
        testLabel2.attachmentCount = NSNumber(value: 1)
        testLabel2.conversationID = testObject.conversationID
        testLabel2.labelID = Message.Location.allmail.labelID.rawValue
        testLabel2.userID = testObject.userID
        testLabel2.order = NSNumber(value: 200)
        testLabel2.isSoftDeleted = testObject.isSoftDeleted

        let mutableSet = testObject.mutableSetValue(forKey: Conversation.Attributes.labels)
        mutableSet.add(testLabel)
        mutableSet.add(testLabel2)

        try testContext.save()

        let sut = ConversationEntity(testObject)

        XCTAssertEqual(sut.objectID.rawValue, testObject.objectID)
        XCTAssertEqual(sut.conversationID.rawValue, testObject.conversationID)
        XCTAssertEqual(sut.expirationTime, testObject.expirationTime)
        XCTAssertEqual(sut.attachmentCount, testObject.numAttachments.intValue)
        XCTAssertEqual(sut.messageCount, testObject.numMessages.intValue)
        XCTAssertEqual(sut.order, testObject.order.intValue)
        XCTAssertEqual(sut.senders, testObject.senders)
        XCTAssertEqual(sut.recipients, testObject.recipients)
        XCTAssertEqual(sut.size, testObject.size?.intValue)
        XCTAssertEqual(sut.subject, testObject.subject)
        XCTAssertEqual(sut.userID.rawValue, testObject.userID)
        XCTAssertEqual(sut.contextLabelRelations.count, testObject.labels.count)

        let contextLabels = try XCTUnwrap(sut.contextLabelRelations)

        let sortedLabels = contextLabels.sorted(by: { $0.order < $1.order })
        XCTAssertEqual(contextLabels, sortedLabels)

        let allMailLabel = try XCTUnwrap(contextLabels.first(where: { $0.labelID == Message.Location.allmail.labelID }))
        XCTAssertEqual(allMailLabel.messageCount, testLabel2.messageCount.intValue)
        XCTAssertEqual(allMailLabel.unreadCount, testLabel2.unreadCount.intValue)
        XCTAssertEqual(allMailLabel.time, testLabel2.time)
        XCTAssertEqual(allMailLabel.size, testLabel2.size.intValue)
        XCTAssertEqual(allMailLabel.attachmentCount, testLabel2.attachmentCount.intValue)
        XCTAssertEqual(allMailLabel.conversationID.rawValue, testLabel2.conversationID)
        XCTAssertEqual(allMailLabel.labelID.rawValue, testLabel2.labelID)
        XCTAssertEqual(allMailLabel.userID.rawValue, testLabel2.userID)
        XCTAssertEqual(allMailLabel.order, testLabel2.order.intValue)
        XCTAssertEqual(allMailLabel.isSoftDeleted, testLabel2.isSoftDeleted)

        let inboxLabel = try XCTUnwrap(contextLabels.first(where: { $0.labelID == Message.Location.inbox.labelID }))
        XCTAssertEqual(inboxLabel.messageCount, testLabel.messageCount.intValue)
        XCTAssertEqual(inboxLabel.unreadCount, testLabel.unreadCount.intValue)
        XCTAssertEqual(inboxLabel.time, testLabel.time)
        XCTAssertEqual(inboxLabel.size, testLabel.size.intValue)
        XCTAssertEqual(inboxLabel.attachmentCount, testLabel.attachmentCount.intValue)
        XCTAssertEqual(inboxLabel.conversationID.rawValue, testLabel.conversationID)
        XCTAssertEqual(inboxLabel.labelID.rawValue, testLabel.labelID)
        XCTAssertEqual(inboxLabel.userID.rawValue, testLabel.userID)
        XCTAssertEqual(inboxLabel.order, testLabel.order.intValue)
        XCTAssertEqual(inboxLabel.isSoftDeleted, testLabel.isSoftDeleted)
    }

    func testStarred_hasStarLabel_returnTrue() {
        let sut = createRandomConversationEntity(with: [Message.Location.starred.labelID])
        XCTAssertTrue(sut.starred)
    }

    func testStarred_hasNoStarLabel_returnFalse() {
        let casesWithoutStar = Message.Location.allCases.filter{ $0 != .starred }.map(\.labelID)
        let sut = createRandomConversationEntity(with: casesWithoutStar)
        XCTAssertFalse(sut.starred)
    }

    func testGetNumUnread() {
        let sut = createRandomConversationEntity(with: [Message.Location.inbox.labelID],
                                                 unreadNum: 100)
        XCTAssertEqual(sut.getNumUnread(labelID: Message.Location.inbox.labelID), 100)

        let casesWithoutInbox = Message.Location.allCases.filter{ $0 != .inbox }.map(\.labelID)
        for labelID in casesWithoutInbox {
            XCTAssertEqual(sut.getNumUnread(labelID: labelID), 0)
        }
    }

    func testIsUnread() {
        let sut = createRandomConversationEntity(with: [Message.Location.inbox.labelID],
                                                 unreadNum: 100)
        XCTAssertTrue(sut.isUnread(labelID: Message.Location.inbox.labelID))

        let casesWithoutInbox = Message.Location.allCases.filter{ $0 != .inbox }.map(\.labelID)
        for labelID in casesWithoutInbox {
            XCTAssertFalse(sut.isUnread(labelID: labelID))
        }
    }

    func testGetLabelIDs() {
        let allCases = Message.Location.allCases.map(\.labelID)
        let sut = createRandomConversationEntity(with: allCases)

        let result = sut.getLabelIDs()
        allCases.forEach { labelID in
            XCTAssertTrue(result.contains(labelID))
        }
        XCTAssertEqual(result.count, allCases.count)
    }

    func testGetTime() {
        let sut = createRandomConversationEntity(with: [Message.Location.inbox.labelID],
                                                 date: Date(timeIntervalSince1970: 100000))
        XCTAssertEqual(sut.getTime(labelID: Message.Location.inbox.labelID),
                       Date(timeIntervalSince1970: 100000))

        let casesWithoutInbox = Message.Location.allCases.filter{ $0 != .inbox }.map(\.labelID)
        for labelID in casesWithoutInbox {
            XCTAssertNil(sut.getTime(labelID: labelID))
        }
    }
}

extension ConversationEntityTests {
    private func createRandomConversationEntity(with LabelIDs: [LabelID],
                                                unreadNum: Int = 0,
                                                date: Date = Date()
    ) -> ConversationEntity {
        let testObject = Conversation(context: testContext)
        testObject.conversationID = String.randomString(20)
        testObject.expirationTime = nil
        testObject.numAttachments = NSNumber(value: 1)
        testObject.numMessages = NSNumber(value: 1)
        testObject.order = NSNumber(value: 100)
        testObject.senders = String.randomString(10)
        testObject.recipients = String.randomString(10)
        testObject.isSoftDeleted = Bool.random()
        testObject.size = NSNumber(value: 1000)
        testObject.subject = String.randomString(100)
        testObject.userID = String.randomString(20)

        for label in LabelIDs {
            let testLabel = ContextLabel(context: testContext)
            testLabel.messageCount = NSNumber(value: 1)
            testLabel.unreadCount = NSNumber(value: unreadNum)
            testLabel.time = date
            testLabel.size = NSNumber(value: 1000)
            testLabel.attachmentCount = NSNumber(value: 1)
            testLabel.conversationID = testObject.conversationID
            testLabel.labelID = label.rawValue
            testLabel.userID = testObject.userID
            testLabel.order = NSNumber(value: Int.random(in: 1...100))
            testLabel.isSoftDeleted = testObject.isSoftDeleted

            let mutableSet = testObject.mutableSetValue(forKey: Conversation.Attributes.labels)
            mutableSet.add(testLabel)
        }
        return ConversationEntity(testObject)
    }
}
