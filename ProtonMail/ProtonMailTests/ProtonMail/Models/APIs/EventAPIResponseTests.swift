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

final class EventAPIResponseTests: XCTestCase {

    func testParsingUserSetting() throws {
        let data = try XCTUnwrap(EventTestData.userSettings.data(using: .utf8))
        let result = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        XCTAssertNotNil(result.userSettings)
    }

    func testParsingMailSetting() throws {
        let data = try XCTUnwrap(EventTestData.mailSettings.data(using: .utf8))
        let result = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        XCTAssertNotNil(result.mailSettings)
    }

    func testParsingIncomingDefault() throws {
        let data = try XCTUnwrap(EventTestData.incomingDefaults.data(using: .utf8))
        let result = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        XCTAssertNotNil(result.incomingDefaults)
    }

    func testParsingUser() throws {
        let data = try XCTUnwrap(EventTestData.user.data(using: .utf8))
        let result = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        XCTAssertNotNil(result.user)
    }

    func testParsingAddresses() throws {
        let data = try XCTUnwrap(EventTestData.addresses.data(using: .utf8))
        let result = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        XCTAssertNotNil(result.addresses)
    }

    func testParsingMessageCounts() throws {
        let data = try XCTUnwrap(EventTestData.messageCounts.data(using: .utf8))
        let result = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        XCTAssertNotNil(result.messageCounts)
    }

    func testParsingConversationCounts() throws {
        let data = try XCTUnwrap(EventTestData.conversationCounts.data(using: .utf8))
        let result = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        XCTAssertNotNil(result.conversationCounts)
    }

    func testParsingLabels() throws {
        let data = try XCTUnwrap(EventTestData.newLabel.data(using: .utf8))
        let result = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        XCTAssertNotNil(result.labels)

        let data2 = try XCTUnwrap(EventTestData.deleteLabel.data(using: .utf8))
        let result2 = try JSONDecoder().decode(EventAPIResponse.self, from: data2)
        XCTAssertNotNil(result2.labels)
    }

    func testParsingContacts() throws {
        let data = try XCTUnwrap(EventTestData.deleteContact.data(using: .utf8))
        let result = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        XCTAssertNotNil(result.contacts)

        let data2 = try XCTUnwrap(EventTestData.modifyContact.data(using: .utf8))
        let result2 = try JSONDecoder().decode(EventAPIResponse.self, from: data2)
        XCTAssertNotNil(result2.contacts)
    }

    func testParsingContactEmails() throws {
        let data = try XCTUnwrap(EventTestData.modifyContact.data(using: .utf8))
        let result = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        XCTAssertNotNil(result.contactEmails)

        let data2 = try XCTUnwrap(EventTestData.modifyContact.data(using: .utf8))
        let result2 = try JSONDecoder().decode(EventAPIResponse.self, from: data2)
        XCTAssertNotNil(result2.contactEmails)
    }

    func testParsingConversation() throws {
        let data = try XCTUnwrap(EventTestData.conversationUpdate.data(using: .utf8))
        let result = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        XCTAssertNotNil(result.conversations)
    }

    func testParsingMessage() throws {
        let data = try XCTUnwrap(EventTestData.messageUpdate.data(using: .utf8))
        let result = try JSONDecoder().decode(EventAPIResponse.self, from: data)
        XCTAssertNotNil(result.messages)
    }
}
