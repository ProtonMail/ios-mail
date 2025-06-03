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
    var watchContactsCallback: ContactsLiveQueryCallback?
    var createdLiveQueryCallbackWrapper: ContactsLiveQueryCallbackWrapper?
    fileprivate var deleterSpy: DeleterSpy!

    override func setUp() {
        super.setUp()
        stubbedContacts = []
        deleterSpy = .init()

        sut = makeSUT(search: .initial)
    }

    override func tearDown() {
        deleterSpy = nil
        createdLiveQueryCallbackWrapper = nil
        watchContactsCallback = nil
        stubbedContacts = nil
        sut = nil
        super.tearDown()
    }

    func testInit_ItDoesNotStartWatchingContacts() throws {
        XCTAssertNil(createdLiveQueryCallbackWrapper)
        XCTAssertNil(watchContactsCallback)
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

    func testOnLoadAction_ItStartsWatchingContactsUpdates() throws {
        sut.handle(action: .onLoad)

        let callbackWrapper = try XCTUnwrap(createdLiveQueryCallbackWrapper)

        XCTAssertIdentical(callbackWrapper, watchContactsCallback)
    }

    func testOnLoadAction_ItLoadsAllContacts() {
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .contact(.aliceAdams),
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
        ]
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)

        XCTAssertEqual(sut.state, .init(search: .initial, allItems: groupedItems))
        XCTAssertEqual(sut.state.displayItems, sut.state.allItems)
        XCTAssertEqual(deleterSpy.deleteContactCalls, [])
        XCTAssertEqual(deleterSpy.deleteContactGroupCalls, [])
    }

    func testOnLoadAction_WhenContainsSpecificSearchPhrase_ItDisplaysFilteredItemsInOneSection() {
        sut = makeSUT(search: .active(query: "Andr"))

        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .contact(.aliceAdams),
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
            .init(
                groupedBy: "E",
                items: [
                    .contact(.evanAndrage),
                    .contact(.elenaErickson),
                ]
            ),
        ]
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)

        let expectedDisplayItems: [GroupedContacts] = [
            .init(
                groupedBy: "",
                items: [
                    .contact(.andrewAllen),
                    .contact(.evanAndrage),
                ]
            )
        ]

        XCTAssertEqual(sut.state, .init(search: .init(query: "Andr", isActive: true), allItems: groupedItems))
        XCTAssertEqual(sut.state.displayItems, expectedDisplayItems)
        XCTAssertEqual(deleterSpy.deleteContactCalls, [])
        XCTAssertEqual(deleterSpy.deleteContactGroupCalls, [])
    }

    func testOnLoad_WhenSearchIsActiveButEmptySearchPhrase_ItDisplaysAllItemsInOneSection() {
        sut = makeSUT(search: .active(query: ""))

        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .contact(.aliceAdams),
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
            .init(
                groupedBy: "E",
                items: [
                    .contact(.evanAndrage),
                    .contact(.elenaErickson),
                ]
            ),
        ]
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)

        XCTAssertEqual(sut.state, .init(search: .init(query: "", isActive: true), allItems: groupedItems))
        XCTAssertEqual(sut.state.displayItems, [.init(groupedBy: "", items: sut.state.allItems.flatMap(\.items))])
        XCTAssertEqual(deleterSpy.deleteContactCalls, [])
        XCTAssertEqual(deleterSpy.deleteContactGroupCalls, [])
    }

    // MARK: - `onDeleteItem` action

    func testOnDeleteItemActionForGroupItem_WhenSearchIsInactive_ItUpdatesStateCorrectlyAndTriggersContactGroupDeletions() {
        let itemToDelete: ContactItemType = .group(.advisorsGroup)
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .contact(.aliceAdams),
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
        ]
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)
        sut.handle(action: .onDeleteItem(itemToDelete))

        XCTAssertEqual(sut.state, .init(search: .initial, allItems: groupedItems, itemToDelete: itemToDelete))
        XCTAssertEqual(sut.state.displayItems, sut.state.allItems)

        simulateSuccessfulOnDeleteItemAlertAction(.group(.advisorsGroup), from: groupedItems)

        let expectedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .contact(.aliceAdams),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
        ]

        XCTAssertEqual(sut.state, .init(search: .initial, allItems: expectedItems, itemToDelete: nil))
        XCTAssertEqual(sut.state.displayItems, sut.state.allItems)
        XCTAssertEqual(deleterSpy.deleteContactCalls, [])
        XCTAssertEqual(deleterSpy.deleteContactGroupCalls, [ContactGroupItem.advisorsGroup.id])
    }

    func testOnDeleteItemActionForContactItem_WhenSearchIsActive_ItUpdatesStateCorrectlyAndTriggersContactDeletion() {
        sut = makeSUT(search: .active(query: ""))

        let itemToDelete: ContactItemType = .contact(.vip)
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    itemToDelete
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
        ]
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)
        sut.handle(action: .onDeleteItem(.contact(.vip)))

        XCTAssertEqual(sut.state, .init(search: .active(query: ""), allItems: groupedItems, itemToDelete: itemToDelete))
        XCTAssertEqual(sut.state.displayItems, [.init(groupedBy: "", items: groupedItems.flatMap(\.items))])
        XCTAssertEqual(deleterSpy.deleteContactCalls, [])
        XCTAssertEqual(deleterSpy.deleteContactGroupCalls, [])

        simulateSuccessfulOnDeleteItemAlertAction(.contact(.vip), from: groupedItems)

        let expectedItems: [GroupedContacts] = [
            .init(
                groupedBy: "A",
                items: [
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            )
        ]

        XCTAssertEqual(sut.state, .init(search: .active(query: ""), allItems: expectedItems, itemToDelete: nil))
        XCTAssertEqual(sut.state.displayItems, [.init(groupedBy: "", items: expectedItems.flatMap(\.items))])
        XCTAssertEqual(deleterSpy.deleteContactCalls, [ContactItem.vip.id])
        XCTAssertEqual(deleterSpy.deleteContactGroupCalls, [])
    }

    func testOnDeleteItemActionForContactItem_AndContactDeletionFails_ItRevertsStateToTheOneBeforeDeletion() {
        let itemToDelete: ContactItemType = .contact(.vip)
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    itemToDelete
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
        ]
        stubbedContacts = groupedItems

        deleterSpy.stubbedDeleteContactsErrors = [
            ContactItem.vip.id: .other(.network)
        ]

        sut.handle(action: .onLoad)
        sut.handle(action: .onDeleteItem(itemToDelete))
        sut.handle(action: .onDeleteItemAlertAction(.confirm))

        createdLiveQueryCallbackWrapper?.onUpdate(contacts: groupedItems)

        XCTAssertEqual(sut.state, .init(search: .initial, allItems: groupedItems, itemToDelete: nil))
        XCTAssertEqual(sut.state.displayItems, groupedItems)
        XCTAssertEqual(deleterSpy.deleteContactCalls, [ContactItem.vip.id])
        XCTAssertEqual(deleterSpy.deleteContactGroupCalls, [])
    }

    func testOnDeleteItemActionForContactGroupItem_AndContactGroupDeletionFails_ItRevertsStateToTheOneBeforeDeletion() {
        let itemToDelete: ContactItemType = .group(.advisorsGroup)
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    itemToDelete,
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
        ]
        stubbedContacts = groupedItems

        deleterSpy.stubbedDeleteContactGroupErrors = [
            ContactGroupItem.advisorsGroup.id: .other(.network)
        ]

        sut.handle(action: .onLoad)
        sut.handle(action: .onDeleteItem(itemToDelete))
        sut.handle(action: .onDeleteItemAlertAction(.confirm))

        createdLiveQueryCallbackWrapper?.onUpdate(contacts: groupedItems)

        XCTAssertEqual(sut.state, .init(search: .initial, allItems: groupedItems, itemToDelete: nil))
        XCTAssertEqual(sut.state.displayItems, groupedItems)
        XCTAssertEqual(deleterSpy.deleteContactCalls, [])
        XCTAssertEqual(deleterSpy.deleteContactGroupCalls, [ContactGroupItem.advisorsGroup.id])
    }

    func testOnDeleteItemActionForContactGroupItem_AndCancelsDeletion_ItDoesNotTriggerContactGroupDeletion() {
        let itemToDelete: ContactItemType = .group(.advisorsGroup)
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    itemToDelete,
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
        ]
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)
        sut.handle(action: .onDeleteItem(itemToDelete))
        sut.handle(action: .onDeleteItemAlertAction(.cancel))

        createdLiveQueryCallbackWrapper?.onUpdate(contacts: groupedItems)

        XCTAssertEqual(sut.state, .init(search: .initial, allItems: groupedItems, itemToDelete: nil))
        XCTAssertEqual(sut.state.displayItems, groupedItems)
        XCTAssertEqual(deleterSpy.deleteContactCalls, [])
        XCTAssertEqual(deleterSpy.deleteContactGroupCalls, [])
    }

    // MARK: - `onTapItem` action

    func testOnTapItemAction_WhenTapOnContact_ItNavigatesToContactDetails() {
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .contact(.aliceAdams),
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
        ]
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)
        sut.handle(action: .onTapItem(.contact(.amandaArcher)))

        XCTAssertEqual(sut.router.stack, [.contactDetails(.amandaArcher)])
    }

    func testOnTapItemAction_WhenTapOnContactGroup_ItNavigatesToContactGroupDetails() {
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .contact(.aliceAdams),
                    .group(.advisorsGroup),
                    .contact(.andrewAllen),
                    .contact(.amandaArcher),
                ]
            ),
        ]
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)
        sut.handle(action: .onTapItem(.group(.advisorsGroup)))

        XCTAssertEqual(sut.router.stack, [.contactGroupDetails(ContactGroupItem.advisorsGroup)])
    }

    // MARK: - `goBack` action

    func testGoBack_ItCleansUpTheStack() {
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            )
        ]
        stubbedContacts = groupedItems

        sut.handle(action: .onLoad)
        sut.handle(action: .onTapItem(.contact(.vip)))
        sut.handle(action: .goBack)

        XCTAssertEqual(sut.router.stack, [])
    }

    // MARK: - Private

    private func makeSUT(search: ContactsScreenState.Search) -> ContactsStateStore {
        .init(
            state: .init(search: search, allItems: []),
            mailUserSession: .testInstance(),
            contactsWrappers: .init(
                contactsProvider: .init(allContacts: { _ in .ok(self.stubbedContacts) }),
                contactDeleter: { id, _ in
                    self.deleterSpy.deleteContactCalls.append(id)

                    if let error = self.deleterSpy.stubbedDeleteContactsErrors[id] {
                        return .error(error)
                    } else {
                        return .ok
                    }
                },
                contactGroupDeleter: { id, _ in
                    self.deleterSpy.deleteContactGroupCalls.append(id)

                    if let error = self.deleterSpy.stubbedDeleteContactGroupErrors[id] {
                        return .error(error)
                    } else {
                        return .ok
                    }
                },
                contactsWatcher: .init(watch: { _, callback in
                    self.watchContactsCallback = callback
                    return WatchContactListResult.ok(.init(contactList: [], handle: .init(noPointer: .init())))
                })
            ),
            makeContactsLiveQuery: {
                let wrapper = ContactsLiveQueryCallbackWrapper()
                self.createdLiveQueryCallbackWrapper = wrapper
                return wrapper
            }
        )
    }

    private func simulateSuccessfulOnDeleteItemAlertAction(
        _ item: ContactItemType,
        from groupedContacts: [GroupedContacts]
    ) {
        sut.handle(action: .onDeleteItemAlertAction(.confirm))

        let updatedItems = deleting(item: item, from: groupedContacts)

        createdLiveQueryCallbackWrapper?.onUpdate(contacts: updatedItems)
    }

    private func deleting(item itemToDelete: ContactItemType, from items: [GroupedContacts]) -> [GroupedContacts] {
        items.compactMap { groupedContacts in
            let filteredItems = groupedContacts.items.filter { item in item != itemToDelete }
            return filteredItems.isEmpty ? nil : groupedContacts.copy(items: filteredItems)
        }
    }

}

private class DeleterSpy {
    var stubbedDeleteContactsErrors: [Id: ActionError] = [:]
    var stubbedDeleteContactGroupErrors: [Id: ActionError] = [:]

    var deleteContactCalls: [Id] = []
    var deleteContactGroupCalls: [Id] = []
}
