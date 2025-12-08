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
import XCTest
import proton_app_uniffi

import struct SwiftUI.Color

@testable import InboxComposer
@testable import InboxContacts

final class ComposerProtonContactsDatasourceTests: XCTestCase {
    private var sut: ComposerProtonContactsDatasource!

    override func setUp() {
        super.setUp()
        sut = ComposerProtonContactsDatasource(
            repository: .init(
                contactStore: CNContactStorePartialStub(),
                allContactsProvider: .init(contactSuggestions: { deviceContacts, _ in
                    return .ok(ContactSuggestionsStub(all: .testData))
                }),
                mailUserSession: .empty()
            )
        )
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testAllContacts_itParsesSingleProtonContactsCorrectly() async {
        let contacts = await sut.allContacts().contacts
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

    func testAllContacts_itParsesSingleDeviceContactsCorrectly() async {
        let contacts = await sut.allContacts().contacts
        let composerContact = contacts.filter { $0.name == "Bob Ainsworth" }.first!

        XCTAssertEqual(composerContact.avatarColor, Color(UIColor(hex: "#3357FF")))
        if case .single(let singleContact) = composerContact.type {
            XCTAssertEqual(singleContact.name, "Bob Ainsworth")
            XCTAssertEqual(singleContact.email, "bob.ainsworth@pm.me")
            XCTAssertEqual(singleContact.initials, "BA")
        } else {
            XCTFail("sinle contact expected")
        }
    }

    func testAllContacts_itParsesProtonContactGroupsCorrectly() async {
        let contacts = await sut.allContacts().contacts
        let composerContact = contacts.filter { $0.name == "Corporate Team" }.first!

        XCTAssertEqual(composerContact.avatarColor, Color(UIColor(hex: "#3357FF")))
        if case .group(let groupContact) = composerContact.type {
            XCTAssertEqual(groupContact.name, "Corporate Team")
            XCTAssertEqual(groupContact.totalMembers, 3)
        } else {
            XCTFail("contact group expected")
        }
    }

    func testAllContacts_whenAProtonContactHasMultipleEmails_itShouldReturnMultipleComposerContacts() async {
        let contacts = await sut.allContacts().contacts
        XCTAssertEqual(contacts.map(\.name).filter { $0.contains("Betty Brown") }.count, 2)
    }

    func testAllContacts_whenAProtonContactIsAGroup_itShouldReturnAComposerContactGroup() async {
        let contacts = await sut.allContacts().contacts
        XCTAssertEqual(contacts.map(\.name).filter { $0.contains("Corporate Team") }.count, 1)
        XCTAssertEqual(contacts.map(\.type).filter { $0.isGroup }.count, 1)
    }
}

private extension Array where Element == ContactSuggestion {
    static var testData: Self {
        [
            .init(
                key: "1",
                name: "Bob Ainsworth",
                avatarInformation: .init(text: "BA", color: "#3357FF"),
                kind: .deviceContact(.init(email: "bob.ainsworth@pm.me"))
            ),
            .init(
                key: "2",
                name: "Betty Brown",
                avatarInformation: .init(text: "BB", color: "#FF5733"),
                kind: .contactItem(.init(id: 3, email: "betty.brown.consulting.department.group@example.com"))
            ),
            .init(
                key: "3",
                name: "Betty Brown",
                avatarInformation: .init(text: "BB", color: "#FF5733"),
                kind: .contactItem(.init(id: 4, email: "betty.brown@protonmail.com"))
            ),
            .init(
                key: "11",
                name: "Corporate Team",
                avatarInformation: .init(text: "CT", color: "#3357FF"),
                kind: .contactGroup([
                    .init(id: 12, email: "corp.team@example.com"),
                    .init(id: 13, email: "corp.team@protonmail.com"),
                    .init(id: 14, email: "corporate@proton.me"),
                ])
            ),
            .init(
                key: "15",
                name: "Carl Cooper",
                avatarInformation: .init(text: "CC", color: "#FF33A1"),
                kind: .contactItem(.init(id: 17, email: "carl.cooper@protonmail.com"))
            ),
        ]
    }
}

private extension MailUserSession {
    static func empty() -> MailUserSession {
        MailUserSession(noPointer: .init())
    }
}

private class ContactSuggestionsStub: ContactSuggestions, @unchecked Sendable {
    private let _all: [ContactSuggestion]

    init(all: [ContactSuggestion]) {
        _all = all
        super.init(noPointer: .init())
    }

    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    override func all() -> [ContactSuggestion] {
        _all
    }
}

private extension ComposerContact {
    var name: String {
        type.name
    }
}

private extension ComposerContactType {
    var isGroup: Bool {
        switch self {
        case .single: false
        case .group: true
        }
    }

    var name: String {
        switch self {
        case .single(let single): single.name
        case .group(let group): group.name
        }
    }
}

private extension ContactItem {
    init(id: UInt64, email: String) {
        let item = ContactEmailItem(id: id, email: email)
        self.init(
            id: item.contactId,
            name: item.name,
            avatarInformation: item.avatarInformation,
            emails: [item]
        )
    }
}
