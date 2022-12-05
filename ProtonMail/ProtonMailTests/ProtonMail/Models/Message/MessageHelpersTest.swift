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
import Groot

class MessageHelpersTest: XCTestCase {

    var coreDataService: CoreDataService!
    var testContext: NSManagedObjectContext!

       override func setUpWithError() throws {
           coreDataService = CoreDataService(container: MockCoreDataStore.testPersistentContainer)

           testContext = coreDataService.mainContext
       }

       override func tearDownWithError() throws {
           coreDataService = nil
           testContext = nil
       }

       func testRecipientsNameWithGroup() {
           let fakeMessageData = testSentMessageWithGroupToAndCC.parseObjectAny()!
           guard let fakeMsg = try? GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: fakeMessageData, in: testContext) as? Message else {
               XCTFail("The fake data initialize failed")
               return
           }
           let fakeMsgEntity = MessageEntity(fakeMsg)

           let fakeEmailData = testEmailData_aaa.parseObjectAny()!
           guard let fakeEmail = try? GRTJSONSerialization.object(withEntityName: "Email", fromJSONDictionary: fakeEmailData, in: testContext) as? Email else {
               XCTFail("The fake data initialize failed")
               return
           }
           let vo = ContactGroupVO(ID: "id", name: "groupA", groupSize: 5, color: "#000000")
           let name = fakeMsgEntity.getSenderName(replacingEmailsMap: [fakeEmail.email: EmailEntity(email: fakeEmail)], groupContacts: [vo])
           XCTAssertEqual("groupA (0/5), test5", name)
       }

    func testRecipientsNameWithoutGroup_localContactWithoutTheAddress() {
        let fakeMessageData = testSentMessageWithToAndCC.parseObjectAny()!
        guard let fakeMsg = try? GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: fakeMessageData, in: testContext) as? Message else {
            XCTFail("The fake data initialize failed")
            return
        }
        let fakeMsgEntity = MessageEntity(fakeMsg)

        let fakeEmailData = testEmailData_aaa.parseObjectAny()!
        guard let fakeEmail = try? GRTJSONSerialization.object(withEntityName: "Email", fromJSONDictionary: fakeEmailData, in: testContext) as? Email else {
            XCTFail("The fake data initialize failed")
            return
        }
        let name = fakeMsgEntity.getSenderName(replacingEmailsMap: [fakeEmail.email: EmailEntity(email: fakeEmail)], groupContacts: [])
        XCTAssertEqual("test0, test1, test2, test3, test4, test5", name)
    }

    func testRecipientsNameWithoutGroup_localContactHasTheAddress() {
        let fakeMessageData = testSentMessageWithToAndCC.parseObjectAny()!
        guard let fakeMsg = try? GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: fakeMessageData, in: testContext) as? Message else {
            XCTFail("The fake data initialize failed")
            return
        }
        let fakeMsgEntity = MessageEntity(fakeMsg)

        let fakeEmailData = testEmailData_bbb.parseObjectAny()!
        guard let fakeEmail = try? GRTJSONSerialization.object(withEntityName: "Email", fromJSONDictionary: fakeEmailData, in: testContext) as? Email else {
            XCTFail("The fake data initialize failed")
            return
        }
        let name = fakeMsgEntity.getSenderName(replacingEmailsMap: [fakeEmail.email: EmailEntity(email: fakeEmail)], groupContacts: [])
        XCTAssertEqual("test0, test1, test2, test3, test4, test000", name)
    }
}
