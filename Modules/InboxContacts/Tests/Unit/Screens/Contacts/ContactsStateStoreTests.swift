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
import Foundation
import InboxCore
import InboxTesting
import proton_app_uniffi
import Testing

@MainActor
final class ContactsStateStoreTests {
    private lazy var sut: ContactsStateStore = makeSUT(search: .initial)
    private var stubbedContacts: [GroupedContacts] = []
    private var watchContactsCallback: ContactsLiveQueryCallback?
    private var createdLiveQueryCallbackWrapper: ContactsLiveQueryCallbackWrapper?
    private let deleterSpy: DeleterSpy = .init()

    @Test
    func testInit_ItDoesNotStartWatchingContacts() {
        #expect(createdLiveQueryCallbackWrapper == nil)
        #expect(watchContactsCallback == nil)
    }

    @Test
    func testState_ItHasCorrectInitialState() {
        let expectedState = ContactsScreenState(
            search: .init(query: "", isActive: false),
            allItems: [],
            displayCreateContactSheet: false,
            createContactURL: .none
        )

        #expect(sut.state == expectedState)
        #expect(sut.state.displayItems == expectedState.allItems)
    }

    // MARK: - `onLoad` action

    @Test
    func testOnLoadAction_ItStartsWatchingContactsUpdates() async throws {
        await sut.handle(action: .onLoad)

        let callbackWrapper = try #require(createdLiveQueryCallbackWrapper)

        #expect(callbackWrapper === watchContactsCallback)
    }

    @Test
    func testOnLoadAction_ItLoadsAllContacts() async {
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

        await sut.handle(action: .onLoad)

        #expect(
            sut.state
                == .init(
                    search: .initial,
                    allItems: groupedItems,
                    displayCreateContactSheet: false,
                    createContactURL: .none
                )
        )
        #expect(sut.state.displayItems == sut.state.allItems)
        #expect(deleterSpy.deleteContactCalls.isEmpty)
        #expect(deleterSpy.deleteContactGroupCalls.isEmpty)
    }

    @Test
    func testOnLoadAction_WhenContainsSpecificSearchPhrase_ItDisplaysFilteredItemsInOneSection() async {
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

        await sut.handle(action: .onLoad)

        let expectedDisplayItems: [GroupedContacts] = [
            .init(
                groupedBy: "",
                items: [
                    .contact(.andrewAllen),
                    .contact(.evanAndrage),
                ]
            )
        ]

        #expect(
            sut.state
                == .init(
                    search: .init(query: "Andr", isActive: true),
                    allItems: groupedItems,
                    displayCreateContactSheet: false,
                    createContactURL: .none
                )
        )
        #expect(sut.state.displayItems == expectedDisplayItems)
        #expect(deleterSpy.deleteContactCalls.isEmpty)
        #expect(deleterSpy.deleteContactGroupCalls.isEmpty)
    }

    @Test
    func testOnLoad_WhenSearchIsActiveButEmptySearchPhrase_ItDisplaysAllItemsInOneSection() async {
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

        await sut.handle(action: .onLoad)

        #expect(
            sut.state
                == .init(
                    search: .init(query: "", isActive: true),
                    allItems: groupedItems,
                    displayCreateContactSheet: false,
                    createContactURL: .none
                )
        )
        #expect(sut.state.displayItems == [.init(groupedBy: "", items: sut.state.allItems.flatMap(\.items))])
        #expect(deleterSpy.deleteContactCalls.isEmpty)
        #expect(deleterSpy.deleteContactGroupCalls.isEmpty)
    }

    // MARK: - `onDeleteItem` action

    @Test
    func testOnDeleteItemActionForGroupItem_WhenSearchIsInactive_ItUpdatesStateCorrectlyAndTriggersContactGroupDeletions() async {
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

        await sut.handle(action: .onLoad)
        await sut.handle(action: .onDeleteItem(itemToDelete))

        #expect(
            sut.state
                == .init(
                    search: .initial,
                    allItems: groupedItems,
                    itemToDelete: itemToDelete,
                    displayCreateContactSheet: false,
                    createContactURL: .none
                )
        )
        #expect(sut.state.displayItems == sut.state.allItems)

        await simulateSuccessfulOnDeleteItemAlertAction(.group(.advisorsGroup), from: groupedItems)

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

        #expect(
            sut.state
                == .init(
                    search: .initial,
                    allItems: expectedItems,
                    itemToDelete: nil,
                    displayCreateContactSheet: false,
                    createContactURL: .none
                )
        )
        #expect(sut.state.displayItems == sut.state.allItems)
        #expect(deleterSpy.deleteContactCalls.isEmpty)
        #expect(deleterSpy.deleteContactGroupCalls == [ContactGroupItem.advisorsGroup.id])
    }

    @Test
    func testOnDeleteItemActionForContactItem_WhenSearchIsActive_ItUpdatesStateCorrectlyAndTriggersContactDeletion() async {
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

        await sut.handle(action: .onLoad)
        await sut.handle(action: .onDeleteItem(.contact(.vip)))

        #expect(
            sut.state
                == .init(
                    search: .active(query: ""),
                    allItems: groupedItems,
                    itemToDelete: itemToDelete,
                    displayCreateContactSheet: false,
                    createContactURL: .none
                )
        )
        #expect(sut.state.displayItems == [.init(groupedBy: "", items: groupedItems.flatMap(\.items))])
        #expect(deleterSpy.deleteContactCalls.isEmpty)
        #expect(deleterSpy.deleteContactGroupCalls.isEmpty)

        await simulateSuccessfulOnDeleteItemAlertAction(.contact(.vip), from: groupedItems)

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

        #expect(
            sut.state
                == .init(
                    search: .active(query: ""),
                    allItems: expectedItems,
                    itemToDelete: nil,
                    displayCreateContactSheet: false,
                    createContactURL: .none
                )
        )
        #expect(sut.state.displayItems == [.init(groupedBy: "", items: expectedItems.flatMap(\.items))])
        #expect(deleterSpy.deleteContactCalls == [ContactItem.vip.id])
        #expect(deleterSpy.deleteContactGroupCalls.isEmpty)
    }

    @Test
    func testOnDeleteItemActionForContactItem_AndContactDeletionFails_ItRevertsStateToTheOneBeforeDeletion() async {
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

        await sut.handle(action: .onLoad)
        await sut.handle(action: .onDeleteItem(itemToDelete))
        await sut.handle(action: .onDeleteItemAlertAction(.confirm))

        await createdLiveQueryCallbackWrapper?.delegate?(groupedItems)

        #expect(
            sut.state
                == .init(
                    search: .initial,
                    allItems: groupedItems,
                    itemToDelete: nil,
                    displayCreateContactSheet: false,
                    createContactURL: .none
                )
        )
        #expect(sut.state.displayItems == groupedItems)
        #expect(deleterSpy.deleteContactCalls == [ContactItem.vip.id])
        #expect(deleterSpy.deleteContactGroupCalls.isEmpty)
    }

    @Test
    func testOnDeleteItemActionForContactGroupItem_AndContactGroupDeletionFails_ItRevertsStateToTheOneBeforeDeletion() async {
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

        await sut.handle(action: .onLoad)
        await sut.handle(action: .onDeleteItem(itemToDelete))
        await sut.handle(action: .onDeleteItemAlertAction(.confirm))

        await createdLiveQueryCallbackWrapper?.delegate?(groupedItems)

        #expect(
            sut.state
                == .init(
                    search: .initial,
                    allItems: groupedItems,
                    itemToDelete: nil,
                    displayCreateContactSheet: false,
                    createContactURL: .none
                )
        )
        #expect(sut.state.displayItems == groupedItems)
        #expect(deleterSpy.deleteContactCalls.isEmpty)
        #expect(deleterSpy.deleteContactGroupCalls == [ContactGroupItem.advisorsGroup.id])
    }

    @Test
    func testOnDeleteItemActionForContactGroupItem_AndCancelsDeletion_ItDoesNotTriggerContactGroupDeletion() async {
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

        await sut.handle(action: .onLoad)
        await sut.handle(action: .onDeleteItem(itemToDelete))
        await sut.handle(action: .onDeleteItemAlertAction(.cancel))

        await createdLiveQueryCallbackWrapper?.delegate?(groupedItems)

        #expect(
            sut.state
                == .init(
                    search: .initial,
                    allItems: groupedItems,
                    itemToDelete: nil,
                    displayCreateContactSheet: false,
                    createContactURL: .none
                )
        )
        #expect(sut.state.displayItems == groupedItems)
        #expect(deleterSpy.deleteContactCalls.isEmpty)
        #expect(deleterSpy.deleteContactGroupCalls.isEmpty)
    }

    // MARK: - `onTapItem` action

    @Test
    func testOnTapItemAction_WhenTapOnContact_ItNavigatesToContactDetails() async {
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

        await sut.handle(action: .onLoad)
        await sut.handle(action: .onTapItem(.contact(.amandaArcher)))

        #expect(sut.router.stack == [.contactDetails(.init(ContactItem.amandaArcher))])
    }

    @Test
    func testOnTapItemAction_WhenTapOnContactGroup_ItNavigatesToContactGroupDetails() async {
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

        await sut.handle(action: .onLoad)
        await sut.handle(action: .onTapItem(.group(.advisorsGroup)))

        #expect(sut.router.stack == [.contactGroupDetails(.advisorsGroup)])
    }

    // MARK: - `goBack` action

    @Test
    func testGoBack_ItCleansUpTheStack() async {
        let groupedItems: [GroupedContacts] = [
            .init(
                groupedBy: "#",
                items: [
                    .contact(.vip)
                ]
            )
        ]
        stubbedContacts = groupedItems

        await sut.handle(action: .onLoad)
        await sut.handle(action: .onTapItem(.contact(.vip)))
        await sut.handle(action: .goBack)

        #expect(sut.router.stack.isEmpty)
    }

    // MARK: - `createTapped` action

    @Test
    func testCreateTappedAction_ItDisplaysCreateContactSheet() async {
        await sut.handle(action: .onLoad)
        await sut.handle(action: .createTapped)

        #expect(sut.state.displayCreateContactSheet)
    }

    // MARK: - `createSheetAction` action

    @Test
    func testCreateSheetAction_WhenOpenWebView_ItClosesSheetAndSetsCreateContactState() async {
        await sut.handle(action: .onLoad)
        await sut.handle(action: .createTapped)
        await sut.handle(action: .createSheetAction(.openSafari))

        #expect(sut.state.displayCreateContactSheet == false)
        #expect(sut.state.createContactURL?.url == URL(string: "https://mail.\(ApiConfig.current.envId.domain)/inbox#create-contact")!)
    }

    @Test
    func testCreateSheetAction_WhenDismiss_ItClosesSheetAndDoesNotSetCreateContactState() async {
        await sut.handle(action: .onLoad)
        await sut.handle(action: .createTapped)
        await sut.handle(action: .createSheetAction(.dismiss))

        #expect(sut.state.displayCreateContactSheet == false)
        #expect(sut.state.createContactURL == nil)
    }

    // MARK: - `dismissCreateSheet` action

    @Test
    func testDismissCreateSheetAction_ItResetsCreateContactState() async {
        await sut.handle(action: .onLoad)
        await sut.handle(action: .createTapped)
        await sut.handle(action: .createSheetAction(.openSafari))
        await sut.handle(action: .dismissCreateSheet)

        #expect(sut.state.createContactURL == nil)
    }

    // MARK: - Private

    private func makeSUT(search: ContactsScreenState.Search) -> ContactsStateStore {
        .init(
            state: .init(search: search, allItems: [], displayCreateContactSheet: false, createContactURL: .none),
            mailUserSession: .testInstance(),
            contactsWrappers: .init(
                contactsProvider: .init(allContacts: { [unowned self] _ in .ok(stubbedContacts) }),
                contactDeleter: { [unowned self] id, _ in
                    deleterSpy.deleteContactCalls.append(id)

                    if let error = deleterSpy.stubbedDeleteContactsErrors[id] {
                        return .error(error)
                    } else {
                        return .ok
                    }
                },
                contactGroupDeleter: { [unowned self] id, _ in
                    deleterSpy.deleteContactGroupCalls.append(id)

                    if let error = deleterSpy.stubbedDeleteContactGroupErrors[id] {
                        return .error(error)
                    } else {
                        return .ok
                    }
                },
                contactsWatcher: .init(watch: { [unowned self] _, callback in
                    watchContactsCallback = callback
                    return WatchContactListResult.ok(.init(contactList: [], handle: .init(noPointer: .init())))
                })
            ),
            makeContactsLiveQuery: { [unowned self] in
                let wrapper = ContactsLiveQueryCallbackWrapper()
                createdLiveQueryCallbackWrapper = wrapper
                return wrapper
            }
        )
    }

    private func simulateSuccessfulOnDeleteItemAlertAction(
        _ item: ContactItemType,
        from groupedContacts: [GroupedContacts]
    ) async {
        await sut.handle(action: .onDeleteItemAlertAction(.confirm))

        let updatedItems = deleting(item: item, from: groupedContacts)

        await createdLiveQueryCallbackWrapper?.delegate?(updatedItems)
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
