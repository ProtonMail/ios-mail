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

    var coreDataService: MockCoreDataContextProvider!

       override func setUpWithError() throws {
           coreDataService = MockCoreDataContextProvider()
       }

       override func tearDownWithError() throws {
           coreDataService = nil
       }

       func testRecipientsNameWithGroup() {
           let fakeMessageData = testSentMessageWithGroupToAndCC.parseObjectAny()!
           let fakeMsgEntity = prepareMessage(with: fakeMessageData)

           let fakeEmailData = testEmailData_aaa.parseObjectAny()!
           let fakeEmailEntity = prepareEmail(with: fakeEmailData)
           let vo = ContactGroupVO(ID: "id", name: "groupA", groupSize: 5, color: "#000000")
           let name = fakeMsgEntity.getSenderName(replacingEmailsMap: [fakeEmailEntity.email: fakeEmailEntity], groupContacts: [vo])
           XCTAssertEqual("groupA (0/5), test5", name)
       }

    func testRecipientsNameWithoutGroup_localContactWithoutTheAddress() {
        let fakeMessageData = testSentMessageWithToAndCC.parseObjectAny()!
        let fakeMsgEntity = prepareMessage(with: fakeMessageData)

        let fakeEmailData = testEmailData_aaa.parseObjectAny()!
        let fakeEmailEntity = prepareEmail(with: fakeEmailData)
        let name = fakeMsgEntity.getSenderName(replacingEmailsMap: [fakeEmailEntity.email: fakeEmailEntity], groupContacts: [])
        XCTAssertEqual("test0, test1, test2, test3, test4, test5", name)
    }

    func testRecipientsNameWithoutGroup_localContactHasTheAddress() {
        let fakeMessageData = testSentMessageWithToAndCC.parseObjectAny()!
        let fakeMsgEntity = prepareMessage(with: fakeMessageData)

        let fakeEmailData = testEmailData_bbb.parseObjectAny()!
        let fakeEmailEntity = prepareEmail(with: fakeEmailData)
        let name = fakeMsgEntity.getSenderName(replacingEmailsMap: [fakeEmailEntity.email: fakeEmailEntity], groupContacts: [])
        XCTAssertEqual("test0, test1, test2, test3, test4, test000", name)
    }

    private func prepareMessage(with data: [String: Any]) -> MessageEntity {
        coreDataService.enqueue { context in
            guard let fakeMsg = try? GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: data, in: context) as? Message else {
                fatalError("The fake data initialize failed")
            }
            return MessageEntity(fakeMsg)
        }
    }

    private func prepareEmail(with data: [String: Any]) -> EmailEntity {
        coreDataService.enqueue { context in
            guard let fakeEmail = try? GRTJSONSerialization.object(withEntityName: "Email", fromJSONDictionary: data, in: context) as? Email else {
                fatalError("The fake data initialize failed")
            }
            return EmailEntity(email: fakeEmail)
        }
    }
}
