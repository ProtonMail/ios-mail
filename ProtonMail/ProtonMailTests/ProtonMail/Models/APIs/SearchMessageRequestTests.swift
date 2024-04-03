// Copyright (c) 2024 Proton Technologies AG
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

final class SearchMessageRequestTests: XCTestCase {
    func testInit() throws {
        let page = UInt.random(in: 0 ... UInt.max)
        let labelIDs: [LabelID] = [Message.Location.trash.labelID, Message.Location.spam.labelID]
        let beginTimeStamp = Date().timeIntervalSince1970
        let endTimeStamp = Date().timeIntervalSince1970
        let beginID = MessageID(String.randomString(10))
        let endID = MessageID(String.randomString(10))
        let keyword = String.randomString(20)
        let toField = [String.randomString(10)]
        let ccField = [String.randomString(10)]
        let bccField = [String.randomString(10)]
        let fromField = [String.randomString(10)]
        let subject = String.randomString(20)
        let hasAttachment = Bool.random()
        let starred = Bool.random()
        let unread = Bool.random()
        let addressID = AddressID(String.randomString(10))

        let query = SearchMessageQuery(
            page: page,
            labelIDs: labelIDs,
            beginTimeStamp: UInt(beginTimeStamp),
            endTimeStamp: UInt(endTimeStamp),
            beginID: beginID,
            endID: endID,
            keyword: keyword,
            toField: toField,
            ccField: ccField,
            bccField: bccField,
            fromField: fromField,
            subject: subject,
            hasAttachments: hasAttachment,
            starred: starred,
            unread: unread,
            addressID: addressID
        )

        let sut = SearchMessageRequest(
            query: query
        )

        XCTAssertEqual(sut.method, .get)
        XCTAssertEqual(sut.path, "/mail/v4/messages")
        let expected: [String: Any] = [
            "Page": page,
            "LabelID": "3,4",
            "Begin": beginTimeStamp,
            "End": endTimeStamp,
            "BeginID": beginID.rawValue,
            "EndID": endID.rawValue,
            "Keyword": keyword,
            "To": toField.joined(),
            "CC": ccField.joined(),
            "BCC": bccField.joined(),
            "From": fromField.joined(),
            "Subject": subject,
            "Attachments": hasAttachment.intValue,
            "Starred": starred.intValue,
            "Unread": unread.intValue,
            "AddressID": addressID.rawValue,
            "Sort": "Time",
            "Desc": 1,
            "Limit": 50
        ]
        let parameters = try XCTUnwrap(sut.parameters)
        for key in parameters.keys {
            if let number = parameters[key] as? Int,
               let expectedValue = expected[key] as? Int {
                XCTAssertEqual(number, expectedValue)
            } else if let string = parameters[key] as? String,
                      let expectedValue = expected[key] as? String {
                XCTAssertEqual(string, expectedValue)
            }
        }
    }
}
