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

import XCTest

@testable import ProtonMail

final class MailboxMessageCellHelperTests: XCTestCase {
    private var sut: MailboxMessageCellHelper!

    override func setUpWithError() throws {
        try super.setUpWithError()

        sut = MailboxMessageCellHelper()
    }

    override func tearDownWithError() throws {
        sut = nil

        try super.tearDownWithError()
    }

    func testConcatenatesSenderNamesAndInsertsBadgesWhereApplicable() throws {
        let protonSender = TestPerson(name: "Proton", isOfficial: true)
        let randomSender1 = TestPerson(name: "Foo Bar", isOfficial: false)
        let randomSender2 = TestPerson(name: "John Doe", isOfficial: false)

        let cases: [(input: [TestPerson], expectedOutput: [SenderRowComponent])] = [
            ([protonSender], [.string("Proton"), .officialBadge]),
            ([randomSender1], [.string("Foo Bar")]),
            ([randomSender1, randomSender2], [.string("Foo Bar, John Doe")]),
            ([protonSender, randomSender1, randomSender2], [.string("Proton"), .officialBadge, .string(", Foo Bar, John Doe")]),
            ([randomSender1, protonSender, randomSender2], [.string("Foo Bar, Proton"), .officialBadge, .string(", John Doe")]),
            ([randomSender1, randomSender2, protonSender], [.string("Foo Bar, John Doe, Proton"), .officialBadge]),
        ]

        for testCase in cases {
            let senderString = try serialize(testInput: testCase.input)
            let conversation = ConversationEntity.make(senders: senderString)
            XCTAssertEqual(sut.senderRowComponents(for: conversation, basedOn: [:]), testCase.expectedOutput)
        }
    }

    func testReplacesEmailAddressesWithEmailNames() throws {
        let testSender = TestPerson(name: "Mr. Foo", address: "foo@example.com")

        let email = EmailEntity.make(email: testSender.address, name: testSender.name)

        let rawSender = try serialize(testInput: testSender)
        let message = MessageEntity.make(rawSender: rawSender)

        let components = sut.senderRowComponents(for: message, basedOn: [email.email: email], groupContacts: [])

        XCTAssertEqual(components, [.string("Mr. Foo")])
    }

    func testDisplaysRecipientsInsteadOfSenderForSentMessages() throws {
        let testSender = TestPerson(name: "Mr. Foo", address: "foo@example.com")
        let testRecipients = [TestPerson(name: "Mr. Bar", address: "bar@example.com")]

        let email = EmailEntity.make(email: testSender.address, name: testSender.name)

        let rawSender = try serialize(testInput: testSender)
        let rawToList = try serialize(testInput: testRecipients)

        let message = MessageEntity.make(
            rawSender: rawSender,
            rawTOList: rawToList,
            labels: [LabelEntity.make(labelID: Message.Location.sent.labelID)]
        )

        let components = sut.senderRowComponents(for: message, basedOn: [email.email: email], groupContacts: [])

        XCTAssertEqual(components, [.string("Mr. Bar")])
    }

    private func serialize(testInput: TestPerson) throws -> String {
        let data = try JSONEncoder().encode(testInput)
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }

    private func serialize(testInput: [TestPerson]) throws -> String {
        let data = try JSONEncoder().encode(testInput)
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }
}

private struct TestPerson: Encodable {
    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case address = "Address"
        case isProton = "IsProton"
    }

    let name: String
    let address: String
    let isProton: Int

    init(name: String, address: String = "", isOfficial: Bool = false) {
        self.name = name
        self.address = address
        isProton = isOfficial ? 1 : 0
    }
}

