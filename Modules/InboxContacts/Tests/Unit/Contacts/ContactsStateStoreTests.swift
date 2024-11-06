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
    var stubbedContacts: [GroupedContacts]!
    var deleteContactsSpy: [Id]!
    var deleteContactGroupsSpy: [Id]!

    override func setUp() {
        super.setUp()
        stubbedContacts = []
        deleteContactsSpy = []
        deleteContactGroupsSpy = []

        sut = makeSUT(search: .initial)
    }

    override func tearDown() {
        deleteContactsSpy = nil
        deleteContactGroupsSpy = nil
        stubbedContacts = nil
        sut = nil
        super.tearDown()
    }

    func testState_ItHasCorrectInitialState() {
        let expectedState = ContactsScreenState(
            search: .init(query: "", isActive: false),
            allItems: []
        )

        XCTAssertEqual(sut.state, expectedState)
        XCTAssertEqual(sut.state.displayItems, expectedState.allItems)
    }

    // MARK: - `onLoad` action

    func testOnLoadAction_ItLoadsAllContacts() {
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
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)

        XCTAssertEqual(sut.state, .init(search: .initial, allItems: groupedItems))
        XCTAssertEqual(sut.state.displayItems, sut.state.allItems)
        XCTAssertEqual(deleteContactsSpy, [])
        XCTAssertEqual(deleteContactGroupsSpy, [])
    }

    func testOnLoadAction_WhenContainsSpecificSearchPhrase_ItDisplaysFilteredItemsInOneSection() {
        sut = makeSUT(search: .active(query: "Andr"))

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
            ),
            .init(
                groupedBy: "E",
                item: [
                    .contact(.evanAndrage),
                    .contact(.elenaErickson)
                ]
            )
        ]
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)

        let expectedDisplayItems: [GroupedContacts] = [
            .init(
                groupedBy: "",
                item: [
                    .contact(.andrewAllen),
                    .contact(.evanAndrage)
                ]
            )
        ]

        XCTAssertEqual(sut.state, .init(search: .init(query: "Andr", isActive: true), allItems: groupedItems))
        XCTAssertEqual(sut.state.displayItems, expectedDisplayItems)
        XCTAssertEqual(deleteContactsSpy, [])
        XCTAssertEqual(deleteContactGroupsSpy, [])
    }

    func testOnLoad_WhenSearchIsActiveButEmptySearchPhrase_ItDisplaysAllItemsInOneSection() {
        sut = makeSUT(search: .active(query: ""))

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
            ),
            .init(
                groupedBy: "E",
                item: [
                    .contact(.evanAndrage),
                    .contact(.elenaErickson)
                ]
            )
        ]
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)

        XCTAssertEqual(sut.state, .init(search: .init(query: "", isActive: true), allItems: groupedItems))
        XCTAssertEqual(sut.state.displayItems, [.init(groupedBy: "", item: sut.state.allItems.flatMap(\.item))])
        XCTAssertEqual(deleteContactsSpy, [])
        XCTAssertEqual(deleteContactGroupsSpy, [])
    }

    // MARK: - `onDeleteItem` action

    func testOnDeleteItemActionForTwoItems_WhenSearchIsInactive_ItUpdatesStateCorrectlyAndTriggersContactAndContactGroupDeletions() {
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
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)
        sut.handle(action: .onDeleteItem(.group(.advisorsGroup)))
        sut.handle(action: .onDeleteItem(.contact(.andrewAllen)))

        let expectedItems: [GroupedContacts] = [
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
                    .contact(.amandaArcher)
                ]
            )
        ]

        XCTAssertEqual(sut.state, .init(search: .initial, allItems: expectedItems))
        XCTAssertEqual(sut.state.displayItems, sut.state.allItems)
        XCTAssertEqual(deleteContactsSpy, [ContactItem.andrewAllen.id])
        XCTAssertEqual(deleteContactGroupsSpy, [ContactGroupItem.advisorsGroup.id])
    }

    func testOnDeleteItemActionForOneItem_WhenSearchIsActive_ItUpdatesStateCorrectlyAndTriggersContactDeletion() {
        sut = makeSUT(search: .active(query: ""))

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
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher)
                ]
            )
        ]
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)
        sut.handle(action: .onDeleteItem(.contact(.vip)))

        let expectedItems: [GroupedContacts] = [
            .init(
                groupedBy: "A",
                item: [
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher)
                ]
            )
        ]

        XCTAssertEqual(sut.state, .init(search: .active(query: ""), allItems: expectedItems))
        XCTAssertEqual(sut.state.displayItems, [.init(groupedBy: "", item: expectedItems.flatMap(\.item))])
        XCTAssertEqual(deleteContactsSpy, [ContactItem.vip.id])
        XCTAssertEqual(deleteContactGroupsSpy, [])
    }

    // MARK: - Private

    private func makeSUT(search: ContactsScreenState.Search) -> ContactsStateStore {
        .init(
            state: .init(search: search, allItems: []),
            mailUserSession: .testInstance(),
            contactsProvider: .init(allContacts: { _ in self.stubbedContacts }),
            contactsDeleter: .init(delete: { id, _ in self.deleteContactsSpy.append(id) }),
            contactGroupDeleter: .init(delete: { id, _ in self.deleteContactGroupsSpy.append(id) })
        )
    }

}
