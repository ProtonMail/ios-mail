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

@testable import ProtonContacts
import proton_app_uniffi
import ProtonCore
import ProtonTesting
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
                    .contact(
                        .init(
                            id: 1_000,
                            name: "0 VIP",
                            avatarInformation: .init(text: "0V", color: "#33FF57"),
                            emails: [
                                .init(id: 1_001, email: "vip@proton.me"),
                            ]
                        )
                    ),
                ]
            ),
            .init(
                groupedBy: "A",
                item: [
                    .contact(
                        .init(
                            id: 0,
                            name: "Alice Adams",
                            avatarInformation: .init(text: "AA", color: "#FF5733"),
                            emails: [
                                .init(id: 1, email: "alice.adams@proton.me"),
                                .init(id: 2, email: "alice.adams@gmail.com")
                            ]
                        )
                    ),
                    .group(
                        .init(
                            id: 3,
                            name: "Advisors Group: Comprehensive Wealth Management and Strategic Financial Solutions",
                            avatarColor: "#A1FF33",
                            emails: [
                                .init(id: 4, email: "group.advisor@pm.me"),
                                .init(id: 5, email: "group.advisor@protonmail.com"),
                                .init(id: 6, email: "advisor.group@yahoo.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 7,
                            name: "🙂 Andrew Allen",
                            avatarInformation: .init(text: "AA", color: "#33FF57"),
                            emails: [
                                .init(id: 8, email: "andrew.allen@protonmail.com"),
                                .init(id: 9, email: "andrew.allen@yahoo.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 10,
                            name: "Amanda Archer",
                            avatarInformation: .init(text: "AA", color: "#3357FF"),
                            emails: [
                                .init(id: 11, email: "amanda.archer@gmail.com"),
                                .init(id: 12, email: "amanda.archer@pm.me")
                            ]
                        )
                    )
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

private final class TestExecutor: SerialExecutor {
    static let shared = TestExecutor()

    func enqueue(_ job: consuming ExecutorJob) {
        job.runSynchronously(on: asUnownedSerialExecutor())
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}
