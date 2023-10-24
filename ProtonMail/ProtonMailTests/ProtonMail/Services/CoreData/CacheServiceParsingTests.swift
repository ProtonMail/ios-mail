//
//  CacheServiceParsingTests.swift
//  ProtonMailTests
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

import Groot
@testable import ProtonMail
import XCTest

class CacheServiceParsingTests: XCTestCase {
    private var globalContainer: GlobalContainer!
    var lastUpdatedStore: MockLastUpdatedStoreProtocol!
    var sut: CacheService!
    var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        let coreDataService = MockCoreDataContextProvider()
        testContext = coreDataService.viewContext

        lastUpdatedStore = MockLastUpdatedStoreProtocol()

        globalContainer = .init()
        globalContainer.contextProviderFactory.register { coreDataService }
        globalContainer.lastUpdatedStoreFactory.register { self.lastUpdatedStore }
        
        sut = CacheService(userID: "userID", dependencies: globalContainer)
    }

    override func tearDownWithError() throws {
        cleanData()

        sut = nil
        globalContainer = nil
        testContext = nil
        lastUpdatedStore = nil
    }

    func testParseMessagesResponse() throws {
        let testData = try XCTUnwrap(testFetchingMessagesDataInInbox.parseObjectAny())
        try sut.parseMessagesResponse(
            labelID: Message.Location.inbox.labelID,
            isUnread: false,
            response: testData,
            idsOfMessagesBeingSent: []
        )

        XCTAssertEqual(lastUpdatedStore.updateLastUpdatedTimeStub.callCounter, 1)
        let lastUpdate = try XCTUnwrap(lastUpdatedStore.updateLastUpdatedTimeStub.lastArguments)
        XCTAssertEqual(lastUpdate.a1, Message.Location.inbox.labelID)
        XCTAssertEqual(lastUpdate.a2, false)
        XCTAssertEqual(lastUpdate.a3, Date(timeIntervalSince1970: 1614266155))
        XCTAssertEqual(lastUpdate.a4, Date(timeIntervalSince1970: 1614093303))
        XCTAssertEqual(lastUpdate.a5, 614)
        XCTAssertEqual(lastUpdate.a6, sut.userID)
        XCTAssertEqual(lastUpdate.a7, .singleMessage)

        let msgs = fetchMessgaes(by: .inbox)
        let msgIDsToMatch = ["Wv3p2AFdMVM-4SLmbVTC1ibPp0a4cfD4phT3rYshtMm5C-ZryQcomqBgie-JWH1pZFWszFrq52cQtIMX4KA38w==", "bzW4_jl_7LfKJCWmE8C0kKgA8XfZ9aGEiXiat3h3XKz9A-9KJ1MYLgBDpYWWDkOiC0EtlzWFSDcp6vL24W_C_w==", "3oGie5p95xf4he7137pkQpuXEdY0cDfDWQuC2japrDWHUoc1DyFAh54HvW9chauqNKHcO7KT48ETNJvc7KakUA==", "ylgAmW17HJcRJSj5FFx5XILy0WmIqXEXzNfqoR_UO1hqkeemUhN7gbGwF8-2OfFMAdJnT5MFopsMeJKG7XN2gg=="]

        XCTAssertEqual(msgs.count, 4)

        for msg in msgs {
            XCTAssertEqual(msg.messageStatus, NSNumber(value: 1))
            XCTAssertEqual(msg.userID, sut.userID.rawValue)
            XCTAssertTrue(msgIDsToMatch.contains(msg.messageID))
        }
    }

    func testParseMessagesResponseWithBadFormattedData() throws {
        let testData = try XCTUnwrap(testBadFormatedFetchingMessagesDataInInbox.parseObjectAny())

        XCTAssertThrowsError(
            try sut.parseMessagesResponse(
                labelID: Message.Location.inbox.labelID,
                isUnread: false,
                response: testData,
                idsOfMessagesBeingSent: []
            )
        )

        let msgs = fetchMessgaes(by: .inbox)
        XCTAssertEqual(msgs.count, 0)
    }

    func testParseMessageResponsePreventOverridingSendingDraft() throws {
        // Load fake sending draft message
        let fakeData = testDraftMessageMetaData.parseObjectAny()!
        let fakeMsg = try GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: fakeData, in: testContext) as! Message
        fakeMsg.userID = sut.userID.rawValue
        fakeMsg.messageStatus = 1
        try testContext.save()

        // try to update the cache
        let testData = try XCTUnwrap(testFetchingMessagesDataInDraft.parseObjectAny())

        try sut.parseMessagesResponse(
            labelID: Message.Location.draft.labelID,
            isUnread: false,
            response: testData,
            idsOfMessagesBeingSent: [fakeMsg.messageID]
        )

        let draftMsg = try XCTUnwrap(Message.messageForMessageID("7JU0HG2gpOMhk9dL65NWkF0y0os0WKf03vkDpLig_rAv-MOR5CgowrEUgJ8GBKypj5Aw65mT2A4ryFTmH1HOEA==", inManagedObjectContext: testContext))
        XCTAssertEqual(draftMsg.subject, "(No Subject) Before Update")

        let msgs = fetchMessgaes(by: .draft)
        XCTAssertEqual(msgs.count, 2)
    }

    func testMessageWithoutAutoReplyHeaderShouldBeDetectedAsNotBeingAnAutoReply() throws {
        let testMessageData = testMessageDetailData.parseObjectAny()!
        let testMessage = try GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: testMessageData, in: testContext) as! Message
        try testContext.save()
        XCTAssertFalse(MessageEntity(testMessage).isAutoReply)
    }

    func testMessageWithAutoReplyHeaderShouldBeDetectedAsBeingAnAutoReply() throws {
        let testMessageData = testMessageDetailDataWithAutoReply.parseObjectAny()!
        let testMessage = try GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: testMessageData, in: testContext) as! Message
        try testContext.save()
        XCTAssertTrue(MessageEntity(testMessage).isAutoReply)
    }
}

private extension CacheServiceParsingTests {
    func fetchMessgaes(by label: Message.Location) -> [Message] {
        let fetchReq = Message.fetchRequest()
        fetchReq.predicate = NSPredicate(format: "(ANY labels.labelID = %@) AND (%K > %d) AND (%K == %@)",
                                         label.rawValue, Message.Attributes.messageStatus, 0, Message.Attributes.userID, sut.userID.rawValue)
        return (try? testContext.fetch(fetchReq) as? [Message]) ?? []
    }

    func cleanData() {
        let fetchRequest = NSFetchRequest<Message>(entityName: "Message")
        let objs = try! testContext.fetch(fetchRequest)
        for case let obj as NSManagedObject in objs {
            testContext.delete(obj)
        }
        try! testContext.save()
    }
}
