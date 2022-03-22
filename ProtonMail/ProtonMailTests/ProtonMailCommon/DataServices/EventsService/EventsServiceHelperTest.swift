// Copyright (c) 2021 Proton AG
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

import XCTest
@testable import ProtonMail
import CoreData
import Groot

class EventsServiceHelperTest: XCTestCase {
    var coreDataService: CoreDataService!
    var testContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        coreDataService = CoreDataService(container: CoreDataStore.shared.memoryPersistentContainer)
        
        testContext = coreDataService.rootSavingContext
    }
    
    override func tearDownWithError() throws {
        coreDataService = nil
        testContext = nil
    }
    
    func testMergeDraft_noNeeded() throws {
        var fakeMessageData = testSentMessageWithGroupToAndCC.parseObjectAny()!
        let id = UUID().uuidString
        fakeMessageData["ID"] = id
        guard let fakeMsg = try? GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: fakeMessageData, in: testContext) as? Message else {
            XCTFail("The fake data initialize failed")
            return
        }
        fakeMsg.isDetailDownloaded = false
        let message: [String: Any] = [
            "LabelIDs": ["3"]
        ]
        let response: [String: Any] = [
            "Action": 2,
            "Message": message,
            "ID": id
        ]
        let event = MessageEvent(event: response)
        let existing = EventsService.Helper.getMessageWithMetaData(for: fakeMsg.messageID,
                                                       context: testContext)
        XCTAssertFalse(event.isDraft)
        XCTAssertNil(existing)
    }

    func testMergeDraft_needed() throws {
        let fakeMessageData = testSentMessageWithGroupToAndCC.parseObjectAny()!
        guard let fakeMsg = try? GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: fakeMessageData, in: testContext) as? Message else {
            XCTFail("The fake data initialize failed")
            return
        }
        fakeMsg.messageStatus = 1
        let messageID = fakeMsg.messageID
        let subject = "Test subject"
        let toList = [[
            "Name": "000",
            "Address": "first@protonmail.com",
            "Group": ""
        ]]
        let ccList = [[
            "Name": "001",
            "Address": "second@protonmail.com",
            "Group": ""
        ]]
        let bccList = [[
            "Name": "002",
            "Address": "third@protonmail.com",
            "Group": ""
        ]]
        let time: Double = 1637215641
        let conversationID = "conversation id"
        let message: [String: Any] = [
            "LabelIDs": ["1"],
            "Subject": subject,
            "ToList": toList,
            "CCList": ccList,
            "BCCList": bccList,
            "Time": time,
            "ConversationID": conversationID
        ]
        let response: [String: Any] = [
            "Action": 2,
            "Message": message,
            "ID": messageID
        ]

        let event = MessageEvent(event: response)
        guard let existing = EventsService.Helper.getMessageWithMetaData(for: messageID, context: testContext) else {
            XCTFail("The message should exist")
            return
        }
        EventsService.Helper.mergeDraft(event: event, existing: existing)
        _ = testContext.saveUpstreamIfNeeded()

        guard let message = Message.messageForMessageID(messageID ,
                                                        inManagedObjectContext: testContext) else {
            XCTFail("Can't find the message")
            return
        }
        XCTAssertEqual(message.subject, subject)
        XCTAssertEqual(message.toList.parseJson()?.first?["Name"] as? String,
                       toList[0]["Name"])
        XCTAssertEqual(message.ccList.parseJson()?.first?["Name"] as? String,
                       ccList[0]["Name"])
        XCTAssertEqual(message.bccList.parseJson()?.first?["Name"] as? String,
                       bccList[0]["Name"])
        XCTAssertEqual(message.time, Date(timeIntervalSince1970: time))
        XCTAssertEqual(message.conversationID, conversationID)
    }
}
