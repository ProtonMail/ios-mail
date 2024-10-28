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

@testable import InboxContacts
import InboxCore
import InboxTesting
import proton_app_uniffi
import XCTest

final class ContactsStateStoreTests: BaseTestCase {

    var sut: ContactsStateStore!
    private var repositorySpy: GroupedContactsRepositorySpy!

    override func setUp() {
        super.setUp()
        repositorySpy = .init()
        sut = .init(state: [], repository: repositorySpy)
    }

    override func tearDown() {
        repositorySpy = nil
        sut = nil
        super.tearDown()
    }

    func testState_ItHasNoItems() {
        XCTAssertEqual(sut.state, [])
    }

    func testState_WhenOnLoad_ItHas2GroupedItems() {
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                item: [
                    .contact(.vip),
                ]
            ),
            .init(
                groupedBy: "A",
                item: [
                    .contact(.aliceAdams),
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher)
                ]
            )
        ]
        repositorySpy.stubbedContacts = groupedItems

        sut.handle(action: .onLoad)

        XCTAssertEqual(sut.state, groupedItems)
    }

}

private class GroupedContactsRepositorySpy: GroupedContactsProviding {

    var stubbedContacts: [GroupedContacts] = []

    // MARK: - GroupedContactsProviding

    func allContacts() async -> [GroupedContacts] {
        stubbedContacts
    }

}
