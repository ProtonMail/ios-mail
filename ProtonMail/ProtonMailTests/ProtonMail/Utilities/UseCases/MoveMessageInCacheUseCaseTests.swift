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

import Groot
@testable import ProtonMail
import XCTest

final class MoveMessageInCacheUseCaseTests: XCTestCase {
    private var sut: MoveMessageInCache!
    private var contextProvider: MockCoreDataContextProvider!
    private var lastUpdatedStore: LastUpdatedStore!
    private var userID: UserID!
    var testMessage: Message!
    var testEntity: MessageEntity!

    override func setUp() {
        super.setUp()
        contextProvider = .init()
        lastUpdatedStore = .init(contextProvider: contextProvider)
        userID = .init(String.randomString(20))

        let globalContainer = GlobalContainer()
        globalContainer.contextProviderFactory.register { self.contextProvider }
        globalContainer.lastUpdatedStoreFactory.register { self.lastUpdatedStore }

        sut = .init(dependencies: .init(
            contextProvider: contextProvider,
            lastUpdatedStore: lastUpdatedStore,
            userID: userID,
            pushUpdater: globalContainer.pushUpdater
        ))
        prepareTestMessage()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        lastUpdatedStore = nil
        contextProvider = nil
        userID = nil
    }

    func testExecute_moveToArchive() throws {
        let currentLocation = Message.Location.inbox.labelID
        let unreadOfInbox = lastUpdatedStore.unreadCount(
            by: currentLocation,
            userID: userID,
            type: .singleMessage
        )
        let unreadOfArchive = lastUpdatedStore.unreadCount(
            by: Message.Location.archive.labelID,
            userID: userID,
            type: .singleMessage
        )

        try sut.execute(params: .init(
            messagesToBeMoved: [testEntity],
            from: [Message.Location.inbox.labelID],
            targetLocation: Message.Location.archive.labelID
        ))

        // check labels
        let newLabels = testMessage.getLabelIDs()
        XCTAssertFalse(newLabels.contains(currentLocation.rawValue))
        XCTAssertTrue(newLabels.contains(Message.Location.archive.rawValue))
        XCTAssertTrue(newLabels.contains(Message.Location.almostAllMail.rawValue))

        // check unread counts
        let unreadOfInboxAfterMove = lastUpdatedStore.unreadCount(
            by: currentLocation,
            userID: userID,
            type: .singleMessage
        )
        let unreadOfArchiveAfterMove = lastUpdatedStore.unreadCount(
            by: Message.Location.archive.labelID,
            userID: userID,
            type: .singleMessage
        )
        XCTAssertEqual(unreadOfInbox, unreadOfInboxAfterMove)
        XCTAssertEqual(unreadOfArchive, unreadOfArchiveAfterMove)
    }

    func testExecute_moveUnreadMessageToArchive_unreadCountWillBeUpdated() throws {
        let currentLocation = Message.Location.inbox.labelID
        testMessage.unRead = true
        lastUpdatedStore.updateUnreadCount(
            by: currentLocation,
            userID: userID,
            unread: 1,
            total: nil,
            type: .singleMessage,
            shouldSave: true
        )
        lastUpdatedStore.updateUnreadCount(
            by: Message.Location.archive.labelID,
            userID: userID,
            unread: 0,
            total: nil,
            type: .singleMessage,
            shouldSave: true
        )

        let unreadOfInbox = lastUpdatedStore.unreadCount(
            by: currentLocation,
            userID: userID,
            type: .singleMessage
        )
        let unreadOfArchive = lastUpdatedStore.unreadCount(
            by: Message.Location.archive.labelID,
            userID: userID,
            type: .singleMessage
        )
        XCTAssertEqual(unreadOfInbox, 1)
        XCTAssertEqual(unreadOfArchive, 0)

        try sut.execute(params: .init(
            messagesToBeMoved: [testEntity],
            from: [Message.Location.inbox.labelID],
            targetLocation: Message.Location.archive.labelID
        ))

        // check labels
        let newLabels = testMessage.getLabelIDs()
        XCTAssertFalse(newLabels.contains(currentLocation.rawValue))
        XCTAssertTrue(newLabels.contains(Message.Location.archive.rawValue))
        XCTAssertTrue(newLabels.contains(Message.Location.almostAllMail.rawValue))

        // check unread counts
        let unreadOfInboxAfterMove = lastUpdatedStore.unreadCount(
            by: currentLocation,
            userID: userID,
            type: .singleMessage
        )
        let unreadOfArchiveAfterMove = lastUpdatedStore.unreadCount(
            by: Message.Location.archive.labelID,
            userID: userID,
            type: .singleMessage
        )
        XCTAssertEqual(unreadOfInboxAfterMove, 0)
        XCTAssertEqual(unreadOfArchiveAfterMove, 1)
    }

    func testExecute_moveMessageToTrash() throws {
        let currentLocation = Message.Location.inbox.labelID
        testMessage.unRead = true
        _ = testMessage.add(labelID: Message.Location.starred.rawValue)
        lastUpdatedStore.updateUnreadCount(
            by: currentLocation,
            userID: userID,
            unread: 1,
            total: nil,
            type: .singleMessage,
            shouldSave: true
        )
        lastUpdatedStore.updateUnreadCount(
            by: Message.Location.trash.labelID,
            userID: userID,
            unread: 0,
            total: nil,
            type: .singleMessage,
            shouldSave: true
        )
        let unreadOfInbox = lastUpdatedStore.unreadCount(
            by: currentLocation,
            userID: userID,
            type: .singleMessage
        )
        let unreadOfTrash = lastUpdatedStore.unreadCount(
            by: Message.Location.trash.labelID,
            userID: userID,
            type: .singleMessage
        )
        XCTAssertEqual(unreadOfInbox, 1)
        XCTAssertEqual(unreadOfTrash, 0)
        XCTAssertTrue(testMessage.contains(label: .starred))

        try sut.execute(params: .init(
            messagesToBeMoved: [testEntity],
            from: [Message.Location.inbox.labelID],
            targetLocation: Message.Location.trash.labelID
        ))

        // unread message should be set to be read after moving to trash
        XCTAssertFalse(testMessage.unRead)
        // check labels
        let newLabels = testMessage.getLabelIDs()
        XCTAssertFalse(newLabels.contains(currentLocation.rawValue))
        XCTAssertTrue(newLabels.contains(Message.Location.trash.rawValue))
        // almostAllMail should be removed
        XCTAssertFalse(newLabels.contains(Message.Location.almostAllMail.rawValue))
        // star label should be removed
        XCTAssertFalse(newLabels.contains(Message.Location.starred.rawValue))

        // check unread counts
        let unreadOfInboxAfterMove = lastUpdatedStore.unreadCount(
            by: currentLocation,
            userID: userID,
            type: .singleMessage
        )
        let unreadOfTrashAfterMove = lastUpdatedStore.unreadCount(
            by: Message.Location.trash.labelID,
            userID: userID,
            type: .singleMessage
        )
        XCTAssertEqual(unreadOfInboxAfterMove, 0)
        XCTAssertEqual(unreadOfTrashAfterMove, 0)
    }

    func testExecute_moveMessageToSpam() throws {
        let currentLocation = Message.Location.inbox.labelID
        testMessage.unRead = true
        _ = testMessage.add(labelID: Message.Location.starred.rawValue)
        lastUpdatedStore.updateUnreadCount(
            by: currentLocation,
            userID: userID,
            unread: 1,
            total: nil,
            type: .singleMessage,
            shouldSave: true
        )
        lastUpdatedStore.updateUnreadCount(
            by: Message.Location.spam.labelID,
            userID: userID,
            unread: 0,
            total: nil,
            type: .singleMessage,
            shouldSave: true
        )
        let unreadOfInbox = lastUpdatedStore.unreadCount(
            by: currentLocation,
            userID: userID,
            type: .singleMessage
        )
        let unreadOfSpam = lastUpdatedStore.unreadCount(
            by: Message.Location.spam.labelID,
            userID: userID,
            type: .singleMessage
        )
        XCTAssertEqual(unreadOfInbox, 1)
        XCTAssertEqual(unreadOfSpam, 0)
        XCTAssertTrue(testMessage.contains(label: .starred))

        try sut.execute(params: .init(
            messagesToBeMoved: [testEntity],
            from: [Message.Location.inbox.labelID],
            targetLocation: Message.Location.spam.labelID
        ))

        // check labels
        let newLabels = testMessage.getLabelIDs()
        XCTAssertFalse(newLabels.contains(currentLocation.rawValue))
        XCTAssertTrue(newLabels.contains(Message.Location.spam.rawValue))
        // almostAllMail should be removed
        XCTAssertFalse(newLabels.contains(Message.Location.almostAllMail.rawValue))
        // star label should be removed
        XCTAssertFalse(newLabels.contains(Message.Location.starred.rawValue))

        // check unread counts
        let unreadOfInboxAfterMove = lastUpdatedStore.unreadCount(
            by: currentLocation,
            userID: userID,
            type: .singleMessage
        )
        let unreadOfSpamAfterMove = lastUpdatedStore.unreadCount(
            by: Message.Location.spam.labelID,
            userID: userID,
            type: .singleMessage
        )
        XCTAssertEqual(unreadOfInboxAfterMove, 0)
        XCTAssertEqual(unreadOfSpamAfterMove, 1)
    }

    func testExecute_moveMessageFromSpamOrTrashToInbox() throws {
        let labelsFrom = [
            Message.Location.trash.labelID,
            Message.Location.spam.labelID
        ]

        for labelFrom in labelsFrom {
            testMessage.remove(labelID: Message.Location.inbox.rawValue)
            testMessage.add(labelID: labelFrom.rawValue)

            // move to inbox
            try sut.execute(params: .init(
                messagesToBeMoved: [testEntity],
                from: [labelFrom],
                targetLocation: Message.Location.inbox.labelID
            ))

            let newLabels = testMessage.getLabelIDs()
            XCTAssertTrue(newLabels.contains(Message.Location.inbox.rawValue))
            XCTAssertTrue(newLabels.contains(Message.Location.allmail.rawValue))
            XCTAssertTrue(newLabels.contains(Message.Location.almostAllMail.rawValue))
        }
    }

    func testExecute_invalidObjectID_receiveAnErrorAboutNoMessageIsFound() throws {
        let objectID = try contextProvider.performAndWaitOnRootSavingContext { context in
            return Label(context: context).objectID
        }
        do {
            try sut.execute(params: .init(
                messagesToBeMoved: [.make(objectID: .init(rawValue: objectID))],
                from: [Message.Location.inbox.labelID],
                targetLocation: Message.Location.trash.labelID
            ))
            XCTFail("Error needs to be thrown")
        } catch {}
    }
}

extension MoveMessageInCacheUseCaseTests {
    func prepareTestMessage() {
        contextProvider.performAndWaitOnRootSavingContext { context in
            let parsedObject = testMessageMetaData.parseObjectAny()!
            self.testMessage = try? GRTJSONSerialization.object(
                withEntityName: "Message",
                fromJSONDictionary: parsedObject, in: context
            ) as? Message
            self.testMessage.userID = self.userID.rawValue

            let parsedLabel = testLabelsData.parseJson()!
            _ = try? GRTJSONSerialization.objects(
                withEntityName: Label.Attributes.entityName,
                fromJSONArray: parsedLabel,
                in: context
            )

            try? context.save()

            self.testEntity = .init(self.testMessage)
        }
    }
}
