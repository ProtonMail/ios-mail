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
import XCTest

@testable import ProtonMail

final class MailboxMessageCellHelperTests: XCTestCase {
    private var testContainer: TestContainer!
    private var sut: MailboxMessageCellHelper!

    override func setUpWithError() throws {
        try super.setUpWithError()

        testContainer = .init()
        sut = MailboxMessageCellHelper(contactPickerModelHelper: testContainer.contactPickerModelHelper)
    }

    override func tearDownWithError() throws {
        sut = nil
        testContainer = nil

        try super.tearDownWithError()
    }

    // MARK: senderRowComponents

    func testConcatenatesSenderNamesAndInsertsBadgesWhereApplicable() throws {
        let protonSender = TestPerson(name: "Proton", isOfficial: true)
        let randomSender1 = TestPerson(name: "Foo Bar", isOfficial: false)
        let randomSender2 = TestPerson(name: "John Doe", isOfficial: false)

        let cases: [(input: [TestPerson], expectedOutput: [SenderRowComponent])] = [
            ([protonSender], [.string("Proton"), .officialBadge]),
            ([randomSender1], [.string("Foo Bar")]),
            ([randomSender1, randomSender2], [.string("Foo Bar"), .string(", John Doe")]),
            ([protonSender, randomSender1, randomSender2], [.string("Proton"), .officialBadge, .string(", Foo Bar"), .string(", John Doe")]),
            ([randomSender1, protonSender, randomSender2], [.string("Foo Bar"), .string(", Proton"), .officialBadge, .string(", John Doe")]),
            ([randomSender1, randomSender2, protonSender], [.string("Foo Bar"), .string(", John Doe"), .string(", Proton"), .officialBadge]),
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

        let components = sut.senderRowComponents(for: message,
                                                 basedOn: [email.email: email],
                                                 groupContacts: [],
                                                 shouldReplaceSenderWithRecipients: Bool.random())

        XCTAssertEqual(components, [.string("Mr. Foo")])
    }

    func testDisplaysRecipientsInsteadOfSenderForSentMessages() throws {
        let testSender = TestPerson(name: "Mr. Foo", address: "foo@example.com")
        let testRecipients = [
            TestPerson(name: "Mr. Bar", address: "bar@example.com"),
            TestPerson(name: "Mr. Xyz", address: "xyz@example.com")
        ]

        let email = EmailEntity.make(email: testSender.address, name: testSender.name)

        let rawSender = try serialize(testInput: testSender)
        let rawToList = try serialize(testInput: testRecipients)

        let message = MessageEntity.make(
            rawSender: rawSender,
            rawTOList: rawToList,
            labels: [LabelEntity.make(labelID: Message.Location.sent.labelID)]
        )

        let components = sut.senderRowComponents(for: message,
                                                 basedOn: [email.email: email],
                                                 groupContacts: [],
                                                 shouldReplaceSenderWithRecipients: true)

        XCTAssertEqual(components, [.string("Mr. Bar"), .string(", Mr. Xyz")])
    }

    func testDisplaysSenderForSentMessagesIfReplacementIsDisabled() throws {
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

        let components = sut.senderRowComponents(for: message,
                                                 basedOn: [email.email: email],
                                                 groupContacts: [],
                                                 shouldReplaceSenderWithRecipients: false)

        XCTAssertEqual(components, [.string("Mr. Foo")])
    }

    private func serialize(testInput: TestPerson) throws -> String {
        let data = try JSONEncoder().encode(testInput)
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }

    private func serialize(testInput: [TestPerson]) throws -> String {
        let data = try JSONEncoder().encode(testInput)
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }

    // MARK: allEmailAddresses

    func testRecipientsNameWithGroup() {
        let fakeMessageData = testSentMessageWithGroupToAndCC.parseObjectAny()!
        let fakeMsgEntity = prepareMessage(with: fakeMessageData)

        let fakeEmailData = testEmailData_aaa.parseObjectAny()!
        let fakeEmailEntity = prepareEmail(with: fakeEmailData)
        let vo = ContactGroupVO(
            ID: "id",
            name: "groupA",
            groupSize: 6,
            color: "#000000",
            contextProvider: testContainer.contextProvider
        )
        let names = sut.allEmailAddresses(
            message: fakeMsgEntity,
            replacingEmails: [fakeEmailEntity.email: fakeEmailEntity],
            allGroupContacts: [vo]
        )
        XCTAssertEqual(["groupA (5/6)", "test5"], names)
    }

    func testRecipientsNameWithoutGroup_localContactWithoutTheAddress() {
        let fakeMessageData = testSentMessageWithToAndCC.parseObjectAny()!
        let fakeMsgEntity = prepareMessage(with: fakeMessageData)

        let fakeEmailData = testEmailData_aaa.parseObjectAny()!
        let fakeEmailEntity = prepareEmail(with: fakeEmailData)
        let names = sut.allEmailAddresses(
            message: fakeMsgEntity,
            replacingEmails: [fakeEmailEntity.email: fakeEmailEntity],
            allGroupContacts: []
        )
        XCTAssertEqual(["test0", "test1", "test2", "test3", "test4", "test5"], names)
    }

    func testRecipientsNameWithoutGroup_localContactHasTheAddress() {
        let fakeMessageData = testSentMessageWithToAndCC.parseObjectAny()!
        let fakeMsgEntity = prepareMessage(with: fakeMessageData)

        let fakeEmailData = testEmailData_bbb.parseObjectAny()!
        let fakeEmailEntity = prepareEmail(with: fakeEmailData)
        let names = sut.allEmailAddresses(
            message: fakeMsgEntity,
            replacingEmails: [fakeEmailEntity.email: fakeEmailEntity],
            allGroupContacts: []
        )
        XCTAssertEqual(["test0", "test1", "test2", "test3", "test4", "test000"], names)
    }

    private func prepareMessage(with data: [String: Any]) -> MessageEntity {
        try! testContainer.contextProvider.write { context in
            guard let fakeMsg = try GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: data, in: context) as? Message else {
                fatalError("The fake data initialize failed")
            }
            return MessageEntity(fakeMsg)
        }
    }

    private func prepareEmail(with data: [String: Any]) -> EmailEntity {
        try! testContainer.contextProvider.write { context in
            guard let fakeEmail = try GRTJSONSerialization.object(withEntityName: "Email", fromJSONDictionary: data, in: context) as? Email else {
                fatalError("The fake data initialize failed")
            }
            return EmailEntity(email: fakeEmail)
        }
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

