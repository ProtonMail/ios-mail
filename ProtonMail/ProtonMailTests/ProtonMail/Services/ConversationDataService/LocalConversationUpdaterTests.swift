// Copyright (c) 2023 Proton Technologies AG
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

@testable import ProtonMail
import XCTest

final class LocalConversationUpdaterTests: XCTestCase {

    private var sut: LocalConversationUpdater!
    private var globalContainer: GlobalContainer!
    private var userID: UserID!
    var msgID: MessageID!
    var conversationID: ConversationID!
    private var contextProvider: MockCoreDataContextProvider!
    private var testMessage: Message!
    private var testConversation: Conversation!

    override func setUp() {
        super.setUp()
        userID = .init(String.randomString(20))
        msgID = .init(String.randomString(20))
        conversationID = .init(String.randomString(20))
        contextProvider = .init()

        globalContainer = .init()
        globalContainer.contextProviderFactory.register { self.contextProvider }

        sut = LocalConversationUpdater(userID: userID.rawValue, dependencies: globalContainer)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        globalContainer = nil
        contextProvider = nil
        userID = nil
    }

    func testEditLabels_moveConversationFromInboxToSpam() async throws {
        let labelIDs = [
            Message.Location.inbox.labelID,
            Message.Location.allmail.labelID,
            Message.Location.almostAllMail.labelID
        ]
        try prepareTestData(labelIDs: labelIDs, unread: true)

        try await sut.editLabels(
            conversationIDs: [conversationID],
            labelToRemove: Message.Location.inbox.labelID,
            labelToAdd: Message.Location.spam.labelID,
            isFolder: true
        )

        XCTAssertFalse(
            testConversation.contains(of: Message.Location.inbox.rawValue)
        )
        XCTAssertTrue(
            testConversation.contains(of: Message.Location.spam.rawValue)
        )
        XCTAssertFalse(
            testConversation.contains(of: Message.Location.almostAllMail.rawValue)
        )

        XCTAssertFalse(
            testMessage.contains(label: Message.Location.inbox.rawValue)
        )
        XCTAssertTrue(
            testMessage.contains(label: Message.Location.spam.rawValue)
        )
        XCTAssertFalse(
            testMessage.contains(label: Message.Location.almostAllMail.rawValue)
        )

        contextProvider.read { context in
            let inboxCount = ConversationCount.lastContextUpdate(
                by: Message.Location.inbox.rawValue,
                userID: self.userID.rawValue,
                inManagedObjectContext: context
            )
            XCTAssertEqual(inboxCount?.unread, 0)
            let spamCount = ConversationCount.lastContextUpdate(
                by: Message.Location.spam.rawValue,
                userID: self.userID.rawValue,
                inManagedObjectContext: context
            )
            XCTAssertEqual(spamCount?.unread, 1)
        }
    }

    func testEditLabels_moveConversationFromInboxToTrash_unreadCountShouldBeZero() async throws {
        let labelIDs = [
            Message.Location.inbox.labelID,
            Message.Location.allmail.labelID,
            Message.Location.almostAllMail.labelID
        ]
        try prepareTestData(labelIDs: labelIDs, unread: true)

        try await sut.editLabels(
            conversationIDs: [conversationID],
            labelToRemove: Message.Location.inbox.labelID,
            labelToAdd: Message.Location.trash.labelID,
            isFolder: true
        )

        XCTAssertFalse(
            testConversation.contains(of: Message.Location.inbox.rawValue)
        )
        XCTAssertTrue(
            testConversation.contains(of: Message.Location.trash.rawValue)
        )
        XCTAssertFalse(
            testConversation.contains(of: Message.Location.almostAllMail.rawValue)
        )

        XCTAssertFalse(
            testMessage.contains(label: Message.Location.inbox.rawValue)
        )
        XCTAssertTrue(
            testMessage.contains(label: Message.Location.trash.rawValue)
        )
        XCTAssertFalse(
            testMessage.contains(label: Message.Location.almostAllMail.rawValue)
        )

        // mark all message/conversation to read
        XCTAssertFalse(testMessage.unRead)
        testConversation.labels
            .compactMap { $0 as? ContextLabel }
            .forEach { contextLabel in
                XCTAssertEqual(contextLabel.unreadCount.intValue, 0)
            }

        contextProvider.read { context in
            let inboxCount = ConversationCount.lastContextUpdate(
                by: Message.Location.inbox.rawValue,
                userID: self.userID.rawValue,
                inManagedObjectContext: context
            )
            XCTAssertEqual(inboxCount?.unread, 0)
            let trashCount = ConversationCount.lastContextUpdate(
                by: Message.Location.trash.rawValue,
                userID: self.userID.rawValue,
                inManagedObjectContext: context
            )
            XCTAssertEqual(trashCount?.unread, 0)
        }
    }

    func testEditLabels_moveFromTrashToInbox() async throws {
        let labelIDs = [
            Message.Location.trash.labelID,
            Message.Location.allmail.labelID
        ]
        try prepareTestData(labelIDs: labelIDs)

        try await sut.editLabels(
            conversationIDs: [conversationID],
            labelToRemove: Message.Location.trash.labelID,
            labelToAdd: Message.Location.inbox.labelID,
            isFolder: true
        )

        XCTAssertFalse(
            testConversation.contains(of: Message.Location.trash.rawValue)
        )
        XCTAssertTrue(
            testConversation.contains(of: Message.Location.inbox.rawValue)
        )
        XCTAssertTrue(
            testConversation.contains(of: Message.Location.almostAllMail.rawValue)
        )

        XCTAssertFalse(
            testMessage.contains(label: Message.Location.trash.rawValue)
        )
        XCTAssertTrue(
            testMessage.contains(label: Message.Location.inbox.rawValue)
        )
        XCTAssertTrue(
            testMessage.contains(label: Message.Location.almostAllMail.rawValue)
        )
    }

    func testEditLabels_editSnoozeTimeOfASnoozedMessage() async throws {
        let labelIDs = [
            Message.Location.snooze.labelID,
            Message.Location.allmail.labelID
        ]
        let snoozeTime = Date()
        try prepareTestData(labelIDs: labelIDs, snoozeTime: snoozeTime)

        try await sut.editLabels(
            conversationIDs: [conversationID],
            labelToRemove: Message.Location.inbox.labelID,
            labelToAdd: Message.Location.snooze.labelID,
            isFolder: true
        )

        XCTAssertTrue(
            testMessage.contains(label: Message.Location.snooze.rawValue)
        )
        XCTAssertTrue(
            testMessage.contains(label: Message.Location.allmail.rawValue)
        )
    }
}

extension LocalConversationUpdaterTests {
    func prepareTestData(
        labelIDs: [LabelID],
        unread: Bool = false,
        snoozeTime: Date? = nil
    ) throws {

        try contextProvider.write { context in
            TestDataCreator.loadDefaultConversationCountData(
                userID: self.userID,
                context: context
            )
            TestDataCreator.loadMessageLabelData(context: context)
            self.testMessage = TestDataCreator.mockMessage(
                messageID: self.msgID,
                conversationID: self.conversationID,
                in: labelIDs,
                labelIDType: .folder,
                userID: self.userID,
                isUnread: unread,
                context: context
            )
            self.testConversation = TestDataCreator.mockConversation(
                conversationID: self.conversationID,
                in: labelIDs,
                userID: self.userID,
                isUnread: unread,
                context: context
            )
            for labelID in labelIDs {
                let conversationCount = ConversationCount.lastContextUpdate(
                    by: labelID.rawValue,
                    userID: self.userID.rawValue,
                    inManagedObjectContext: context
                )
                conversationCount?.unread = unread ? 1 : 0
                if labelID == Message.Location.snooze.labelID, let snoozeTime {
                    let label = self.testConversation.getContextLabel(location: .snooze)
                    label?.snoozeTime = snoozeTime
                }
            }
            _ = context.saveUpstreamIfNeeded()
        }
    }
}
