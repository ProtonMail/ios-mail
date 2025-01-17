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

import Combine
@testable import InboxComposer
import InboxContacts
import proton_app_uniffi
import struct SwiftUI.Color
import XCTest

final class ComposerProtonContactsDatasourceTests: XCTestCase {
    private var sut: ComposerProtonContactsDatasource!

    override func setUp() {
        super.setUp()
        sut = ComposerProtonContactsDatasource(mailUserSession: .empty(), contactsProvider: .mockInstance())
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testAllContacts_itParsesSingleProtonContactsCorrectly() async {
        let contacts = await sut.allContacts()
        let composerContact = contacts.filter { $0.name == "Carl Cooper" }.first!

        XCTAssertEqual(composerContact.avatarColor, Color(UIColor(hex: "#FF33A1")))
        if case .single(let singleContact) = composerContact.type {
            XCTAssertEqual(singleContact.name, "Carl Cooper")
            XCTAssertEqual(singleContact.email, "carl.cooper@protonmail.com")
            XCTAssertEqual(singleContact.initials, "CC")
        } else {
            XCTFail("sinle contact expected")
        }
    }

    func testAllContacts_itParsesProtonContactGroupsCorrectly() async {
        let contacts = await sut.allContacts()
        let composerContact = contacts.filter { $0.name == "Corporate Team" }.first!

        XCTAssertEqual(composerContact.avatarColor, Color(UIColor(hex: "#3357FF")))
        if case .group(let groupContact) = composerContact.type {
            XCTAssertEqual(groupContact.name, "Corporate Team")
            XCTAssertEqual(groupContact.totalMembers, 3)
        } else {
            XCTFail("contact group expected")
        }
    }

    func testAllContacts_whenAProtonContactDoesNotHaveEmail_itShouldNotReturnIt() async {
        let contacts = await sut.allContacts()
        XCTAssertEqual(contacts.map(\.name).contains("Bob Ainsworth"), false)
    }

    func testAllContacts_whenAProtonContactHasMultipleEmails_itShouldReturnMultipleComposerContacts() async {
        let contacts = await sut.allContacts()
        XCTAssertEqual(contacts.map(\.name).filter { $0.contains("Betty Brown") }.count, 2)
    }

    func testAllContacts_whenAProtonContactIsAGroup_itShouldReturnAComposerContactGroup() async {
        let contacts = await sut.allContacts()
        XCTAssertEqual(contacts.map(\.name).filter { $0.contains("Corporate Team") }.count, 1)
        XCTAssertEqual(contacts.map(\.type).filter { $0.isGroup }.count, 1)
    }
}

private extension GroupedContactsProvider {
    static func mockInstance() -> Self {
        .init(allContacts: { _ in .ok(stubbedContacts) })
    }

    private static var stubbedContacts: [GroupedContacts] {
        [
            .init(
                groupedBy: "B",
                items: [
                    .contact(
                        .init(
                            id: .init(value: 1),
                            name: "Bob Ainsworth",
                            avatarInformation: .init(text: "BA", color: "#FF33A1"),
                            emails: []
                        )
                    ),
                    .contact(
                        .init(
                            id: .init(value: 2),
                            name: "Betty Brown",
                            avatarInformation: .init(text: "BB", color: "#FF5733"),
                            emails: [
                                .init(id: 3, email: "betty.brown.consulting.department.group@example.com"),
                                .init(id: 4, email: "betty.brown@protonmail.com")
                            ]
                        )
                    ),
                ]
            ),
            .init(
                groupedBy: "C",
                items: [
                    .group(
                        .init(
                            id: 11, 
                            name: "Corporate Team",
                            avatarColor: "#3357FF",
                            contacts: [
                                .init(id: 12, email: "corp.team@example.com"),
                                .init(id: 13, email: "corp.team@protonmail.com"),
                                .init(id: 14, email: "corporate@proton.me"),
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: .init(value: 15),
                            name: "Carl Cooper",
                            avatarInformation: .init(text: "CC", color: "#FF33A1"),
                            emails: [
                                .init(id: 17, email: "carl.cooper@protonmail.com")
                            ]
                        )
                    ),
                ]
            )
        ]
    }
}

private extension MailUserSession {

    static func empty() -> MailUserSession {
        MailUserSession(noPointer: .init())
    }
}

private extension ContactGroupItem {

    init(id: UInt64, name: String, avatarColor: String, contacts: [ContactEmailItem]) {
        self.init(
            id: Id(value: id),
            name: name,
            avatarColor: avatarColor,
            contacts: [
                .init(
                    id: .init(value: id),
                    name: name,
                    avatarInformation: .init(text: "__NOT_USED__", color: avatarColor),
                    emails: contacts
                )
            ]
        )
    }

}


private extension ContactEmailItem {

    init(id: UInt64, email: String) {
        self.init(id: Id(value: id), email: email, isProton: false, lastUsedTime: 0)
    }

}
