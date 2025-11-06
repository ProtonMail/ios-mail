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

import Foundation
@testable import ProtonMail
import Testing

@MainActor
final class SelectionModeTests {
    private var sut = SelectionMode()

    @Test
    func testInit() {
        #expect(sut.selectionState.hasItems == false)
    }

    // MARK: SelectionModeState

    @Test
    func testHasSelectedItems_whenNoItems_itReturnsFalse() {
        #expect(sut.selectionState.hasItems == false)
        #expect(sut.selectionState.selectedItems == Set())
    }

    @Test
    func testHasSelectedItems_whenThereAreItems_itReturnsTrue() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1),
            .testData(id: 2),
        ]
        items.forEach { sut.selectionModifier.addMailboxItem($0) }

        #expect(sut.selectionState.hasItems == true)
        #expect(sut.selectionState.selectedItems == Set(items))

        sut.selectionModifier.removeMailboxItem(items[1])

        #expect(sut.selectionState.hasItems == true)
        #expect(sut.selectionState.selectedItems == [items[0]])
    }

    // MARK: SelectionModeStateModifier

    @Test
    func testAddMailboxItem_itAddsTheItem() {
        #expect(sut.selectionState.hasItems == false)

        let item = MailboxSelectedItem.testData(id: 1, isRead: false, isStarred: true)
        sut.selectionModifier.addMailboxItem(item)

        #expect(sut.selectionState.hasItems == true)
        #expect(sut.selectionState.selectedItems == [item])
    }

    @Test
    func testRemoveMailboxItem_itRemovesTheItem() {
        let item = MailboxSelectedItem.testData(id: 1, isRead: false, isStarred: true)
        sut.selectionModifier.addMailboxItem(item)

        #expect(sut.selectionState.hasItems == true)
        #expect(sut.selectionState.selectedItems == [item])

        sut.selectionModifier.removeMailboxItem(item)
        #expect(sut.selectionState.hasItems == false)
        #expect(sut.selectionState.selectedItems == Set())
    }

    @Test
    func testRefreshSelectedItemsStatus_whenStatusDoesChange_itKeepsTheSameItemSelectionWithNewStatus() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: false, isStarred: false),
            .testData(id: 2, isRead: false, isStarred: false),
        ]
        items.forEach { sut.selectionModifier.addMailboxItem($0) }
        #expect(sut.selectionState.hasItems == true)
        #expect(sut.selectionState.selectedItems == Set(items))

        sut.selectionModifier.refreshSelectedItemsStatus(
            newMailboxItems: [
                makeMailboxItemCellUIModel(id: 1, isRead: true, isStarred: true),
                makeMailboxItemCellUIModel(id: 2, isRead: true, isStarred: true),
            ]
        )
        #expect(sut.selectionState.hasItems == true)
        #expect(Set(sut.selectionState.selectedItems.map(\.id)) == Set(items.map(\.id)))

        sut.selectionState.selectedItems.forEach { selectedItem in
            #expect(selectedItem.isRead == true)
            #expect(selectedItem.isStarred == true)
        }
    }

    @Test
    func testRefreshSelectedItemsStatus_whenStatusDoesNotChange_itKeepsTheSameItemSelection() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: true, isStarred: true),
            .testData(id: 2, isRead: true, isStarred: true),
        ]
        items.forEach { sut.selectionModifier.addMailboxItem($0) }
        #expect(sut.selectionState.hasItems == true)
        #expect(sut.selectionState.selectedItems == Set(items))

        sut.selectionModifier.refreshSelectedItemsStatus(newMailboxItems: [
            makeMailboxItemCellUIModel(id: 1, isRead: true, isStarred: true),
            makeMailboxItemCellUIModel(id: 2, isRead: true, isStarred: true),
        ])

        #expect(sut.selectionState.hasItems == true)
        #expect(sut.selectionState.selectedItems == Set(items))
    }

    @Test
    func testRefreshSelectedItemsStatus_whenLessItemsAreReturned_itRemovesTheNotReturnedItemsFromSelection() {
        let item1 = MailboxSelectedItem.testData(id: 1, isRead: true, isStarred: true)
        let item2 = MailboxSelectedItem.testData(id: 2, isRead: true, isStarred: true)
        [item1, item2].forEach { sut.selectionModifier.addMailboxItem($0) }
        #expect(sut.selectionState.hasItems == true)
        #expect(sut.selectionState.selectedItems == [item1, item2])

        sut.selectionModifier.refreshSelectedItemsStatus(newMailboxItems: [makeMailboxItemCellUIModel(id: 1, isRead: true, isStarred: true)])
        #expect(sut.selectionState.hasItems == true)
        #expect(sut.selectionState.selectedItems == [item1])

        sut.selectionModifier.refreshSelectedItemsStatus(newMailboxItems: [])
        #expect(sut.selectionState.hasItems == false)
        #expect(sut.selectionState.selectedItems == [])
    }

    @Test
    func testRefreshSelectedItemsStatus_whenMoreItemsAreReturned_itDoesNotAddTheNewItemsToTheSelection() {
        sut.selectionModifier.refreshSelectedItemsStatus(newMailboxItems: [makeMailboxItemCellUIModel(id: 1, isRead: true, isStarred: true)])
        #expect(sut.selectionState.hasItems == false)
        #expect(sut.selectionState.selectedItems == [])
    }

    @Test
    func testExitSelectionMode_itRemovesAllSelectedItems() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isStarred: false),
            .testData(id: 2, isStarred: false),
        ]
        items.forEach { sut.selectionModifier.addMailboxItem($0) }
        #expect(sut.selectionState.hasItems == true)

        sut.selectionModifier.exitSelectionMode()
        #expect(sut.selectionState.hasItems == false)
        #expect(sut.selectionState.selectedItems == [])
    }

    // MARK: Selection limit

    @Test
    func testWhenSelectionLimitIsReached_cannotSelectMoreItemsUntilRoomIsGiven() {
        let items: [MailboxSelectedItem] = (0...101).map { .testData(id: $0) }

        for item in items {
            sut.selectionModifier.addMailboxItem(item)
        }

        #expect(sut.selectionState.selectedItems == Set(items[0..<100]))

        sut.selectionModifier.removeMailboxItem(items[0])
        sut.selectionModifier.addMailboxItem(items[100])

        #expect(sut.selectionState.selectedItems == Set(items[1..<101]))
    }

    @Test
    func testAddMailboxItem_reportsSuccess() {
        let items: [MailboxSelectedItem] = (0...101).map { .testData(id: $0) }

        let results: [Bool] = items.map(sut.selectionModifier.addMailboxItem)

        #expect(results[0..<100] == .init(repeating: true, count: 100))
        #expect(results[100] == false)
    }

    // MARK: Select All

    @Test
    func testInSelectAllMode_whenDeselectingAllAtOnce_HasItemsRemainsTrue() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1),
            .testData(id: 2),
        ]

        sut.selectionModifier.enterSelectAllMode(selecting: items)
        sut.selectionModifier.deselectAll(stayingInSelectAllMode: true)

        #expect(sut.selectionState.hasItems == true)
        #expect(sut.selectionState.selectedItems == [])
    }

    @Test
    func testInSelectAllMode_whenRemovingSingleItem_selectAllModeIsEnded() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1),
            .testData(id: 2),
        ]

        sut.selectionModifier.enterSelectAllMode(selecting: items)
        sut.selectionModifier.removeMailboxItem(items[0])

        #expect(sut.selectionState.isSelectAllEnabled == false)
    }

    @Test
    func testInSelectAllMode_whenExitingSelectAllMode_selectionIsPreserved() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1),
            .testData(id: 2),
        ]

        sut.selectionModifier.enterSelectAllMode(selecting: items)
        sut.selectionModifier.exitSelectAllMode()

        #expect(sut.selectionState.selectedItems == Set(items))
        #expect(sut.selectionState.isSelectAllEnabled == false)
    }

    @Test
    func testInSelectAllMode_whenExitingSelectionMode_everythingIsCleared() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1),
            .testData(id: 2),
        ]

        sut.selectionModifier.enterSelectAllMode(selecting: items)
        sut.selectionModifier.exitSelectionMode()

        #expect(sut.selectionState.selectedItems == [])
        #expect(sut.selectionState.isSelectAllEnabled == false)
    }

    @Test
    func testEnteringSelectAllModeRespectsSelectionLimit() {
        let items: [MailboxSelectedItem] = (0...101).map { .testData(id: $0) }

        sut.selectionModifier.enterSelectAllMode(selecting: items)

        #expect(sut.selectionState.selectedItems == Set(items[0..<100]))
    }
}

extension SelectionModeTests {

    private func makeMailboxItemCellUIModel(id: UInt64, isRead: Bool, isStarred: Bool) -> MailboxItemCellUIModel {
        MailboxItemCellUIModel(
            id: .init(value: id),
            conversationID: .random(),
            type: .conversation,
            avatar: .init(info: .init(initials: "", color: .blue), type: .other),
            emails: "",
            subject: "",
            date: Date(),
            locationIcon: nil,
            isRead: isRead,
            isStarred: isStarred,
            isSelected: [false, false, Bool.random()].randomElement()!,
            isSenderProtonOfficial: Bool.random(),
            messagesCount: [0, 2, 3].randomElement()!,
            labelUIModel: .init(labelModels: []),
            attachments: .init(
                previewables: [],
                containsCalendarInvitation: false,
                totalCount: 0
            ),
            expirationDate: nil,
            snoozeDate: nil,
            isDraftMessage: false,
            shouldUseSnoozedColorForDate: false
        )
    }
}
