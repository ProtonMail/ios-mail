// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail
import Groot

class MessageExtensionTest: XCTestCase {

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
    
    
    func testRecipients() throws {
        let fakeMessageData = testSentMessageWithGroupToAndCC.parseObjectAny()!
        guard let fakeMsg = try? GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: fakeMessageData, in: testContext) as? Message else {
            XCTFail("The fake data initialize failed")
            return
        }
        guard let toList = fakeMsg.toList.parseJson(),
              let ccList = fakeMsg.ccList.parseJson(),
              let bccList = fakeMsg.bccList.parseJson() else {
                  XCTFail("Parse dictionary failed")
                  return
              }
        let recipients = toList + ccList + bccList
        XCTAssertEqual(recipients.count, fakeMsg.recipients.count)
        XCTAssertEqual(recipients[0]["Name"] as? String,
                       fakeMsg.recipients[0]["Name"] as? String)
    }

    func testMessageWithInalidIDShouldGenerateNilNotificationUUID() {
        let bogusMessageID = String.randomString(Int.random(in: 1...100))
        let message = Message(context: testContext)
        message.messageID = bogusMessageID
        let generatedUUID = message.notificationId
        XCTAssertNil(generatedUUID)
    }

    func testMessageWithValidIDShouldGenerateMatchingNotificationUUID() {
        let base64MessageID = "B8noUg_pBEQ7Bw1EQv1vsYmw6YlnoZVg_Vh5gwYvIkU_fHlMLlgKGAF5E9fQ04xx0VVv6wUxn7pCScr4-8DHmw=="
        let expectedUUID = "07c9e852-0a41-110e-c1c3-000000000000"
        let message = Message(context: testContext)
        message.messageID = base64MessageID
        let generatedUUID = message.notificationId
        XCTAssertEqual(generatedUUID, expectedUUID)
    }
}
