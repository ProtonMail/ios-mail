//
//  MessageDataServiceTests.swift
//  Proton MailTests
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
@testable import ProtonMail
import CoreData
import Groot

class MessageDataServiceTests: XCTestCase {
    var coreDataService: CoreDataService!
    var testContext: NSManagedObjectContext!
    let customLabelId = "Vg_DqN6s-xg488vZQBkiNGz0U-62GKN6jMYRnloXY-isM9s5ZR-rWCs_w8k9Dtcc-sVC-qnf8w301Q-1sA6dyw=="

    override func setUpWithError() throws {
        coreDataService = CoreDataService(container: CoreDataStore.shared.memoryPersistentContainer)
        testContext = coreDataService.rootSavingContext

        let parsedLabel = testLabelsData.parseJson()!
        _ = try GRTJSONSerialization.objects(withEntityName: Label.Attributes.entityName,
                                             fromJSONArray: parsedLabel,
                                             in: testContext)

        try testContext.save()
    }

    override func tearDownWithError() throws {
        coreDataService = nil
        testContext = nil
    }

    func testFindMessagesWithSourceIdsWithMessageInSpamToInbox() throws {
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.spam.rawValue))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([message], [customLabelId], Message.Location.inbox.rawValue)

        XCTAssertEqual(result.count, 1)
        let pair = try XCTUnwrap(result.first)
        XCTAssertEqual(pair.1, Message.Location.spam.rawValue)
        XCTAssertEqual(pair.0, message)
    }

    func testFindMessagesWithSourceIdsWithMessageInCustomFolderToInbox() throws {
        let message = try XCTUnwrap(makeTestMessageIn(customLabelId))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([message], [customLabelId], Message.Location.inbox.rawValue)

        XCTAssertEqual(result.count, 1)
        let pair = try XCTUnwrap(result.first)
        XCTAssertEqual(pair.1, customLabelId)
        XCTAssertEqual(pair.0, message)
    }

    func testFindMessagesWithSourceIdsWithMessageInSpamToSamePlace() throws {
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.spam.rawValue))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([message], [customLabelId], Message.Location.spam.rawValue)

        XCTAssertEqual(result.count, 0)
    }

    func testFindMessagesWithSourceIdsWithMessageInDraftToSpam() throws {
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.draft.rawValue))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([message], [customLabelId], Message.Location.spam.rawValue)

        XCTAssertEqual(result.count, 0)
    }

    func testFindMessagesWithSourceIdsWithMessageInSentToSpam() throws {
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.sent.rawValue))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([message], [customLabelId], Message.Location.spam.rawValue)

        XCTAssertEqual(result.count, 0)
    }

    func testFindMessagesWithSourceIdsWithMessageInDraftToInbox() throws {
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.draft.rawValue))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([message], [customLabelId], Message.Location.inbox.rawValue)

        XCTAssertEqual(result.count, 0)
    }

    func testFindMessagesWithSourceIdsWithMessageInSentToInbox() throws {
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.sent.rawValue))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([message], [customLabelId], Message.Location.inbox.rawValue)

        XCTAssertEqual(result.count, 0)
    }

    func testFindMessagesWithSourceIdsWithMessageHavingRandomLabelIdToInbox() throws {
        let message = try XCTUnwrap(makeTestMessageIn("sjldfjisdflngw"))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([message], [customLabelId], Message.Location.inbox.rawValue)

        XCTAssertEqual(result.count, 0)
    }

    private func makeTestMessageIn(_ labelId: String) -> Message? {
        let parsedObject = testMessageMetaData.parseObjectAny()!
        let message = try? GRTJSONSerialization
            .object(withEntityName: Message.Attributes.entityName,
                    fromJSONDictionary: parsedObject,
                    in: testContext) as? Message
        message?.remove(labelID: "0")
        message?.add(labelID: labelId)
        try? testContext.save()
        return message
    }
}
