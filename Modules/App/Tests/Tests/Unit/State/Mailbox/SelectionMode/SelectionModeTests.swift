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
import XCTest

final class SelectionModeTests: XCTestCase {
    private var sut: SelectionMode!

    override func setUp() {
        super.setUp()

        sut = .init()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func testInit() {
        XCTAssertEqual(sut.selectionState.hasItems, false)
    }

    // MARK: SelectionModeState

    func testHasSelectedItems_whenNoItems_itReturnsFalse() {
        XCTAssertEqual(sut.selectionState.hasItems, false)
        XCTAssertEqual(sut.selectionState.selectedItems, Set())
    }

    func testHasSelectedItems_whenThereAreItems_itReturnsTrue() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1),
            .testData(id: 2),
        ]
        items.forEach { sut.selectionModifier.addMailboxItem($0) }

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))

        sut.selectionModifier.removeMailboxItem(items[1])

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, [items[0]])
    }

    // MARK: SelectionModeStateModifier

    func testAddMailboxItem_itAddsTheItem() {
        XCTAssertEqual(sut.selectionState.hasItems, false)

        let item = MailboxSelectedItem.testData(id: 1, isRead: false, isStarred: true)
        sut.selectionModifier.addMailboxItem(item)

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, [item])
    }

    func testRemoveMailboxItem_itRemovesTheItem() {
        let item = MailboxSelectedItem.testData(id: 1, isRead: false, isStarred: true)
        sut.selectionModifier.addMailboxItem(item)

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, [item])

        sut.selectionModifier.removeMailboxItem(item)
        XCTAssertEqual(sut.selectionState.hasItems, false)
        XCTAssertEqual(sut.selectionState.selectedItems, Set())
    }

    @MainActor
    func testRefreshSelectedItemsStatus_whenStatusDoesChange_itKeepsTheSameItemSelectionWithNewStatus() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: false, isStarred: false),
            .testData(id: 2, isRead: false, isStarred: false),
        ]
        items.forEach { sut.selectionModifier.addMailboxItem($0) }
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))

        sut.selectionModifier.refreshSelectedItemsStatus(
            newMailboxItems: [
                makeMailboxItemCellUIModel(id: 1, isRead: true, isStarred: true),
                makeMailboxItemCellUIModel(id: 2, isRead: true, isStarred: true),
            ]
        )
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(Set(sut.selectionState.selectedItems.map(\.id)), Set(items.map(\.id)))

        sut.selectionState.selectedItems.forEach { selectedItem in
            XCTAssertEqual(selectedItem.isRead, true)
            XCTAssertEqual(selectedItem.isStarred, true)
        }
    }

    @MainActor
    func testRefreshSelectedItemsStatus_whenStatusDoesNotChange_itKeepsTheSameItemSelection() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: true, isStarred: true),
            .testData(id: 2, isRead: true, isStarred: true),
        ]
        items.forEach { sut.selectionModifier.addMailboxItem($0) }
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))

        sut.selectionModifier.refreshSelectedItemsStatus(newMailboxItems: [
            makeMailboxItemCellUIModel(id: 1, isRead: true, isStarred: true),
            makeMailboxItemCellUIModel(id: 2, isRead: true, isStarred: true),
        ])

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))
    }

    @MainActor
    func testRefreshSelectedItemsStatus_whenLessItemsAreReturned_itRemovesTheNotReturnedItemsFromSelection() {
        let item1 = MailboxSelectedItem.testData(id: 1, isRead: true, isStarred: true)
        let item2 = MailboxSelectedItem.testData(id: 2, isRead: true, isStarred: true)
        [item1, item2].forEach { sut.selectionModifier.addMailboxItem($0) }
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, [item1, item2])

        sut.selectionModifier.refreshSelectedItemsStatus(newMailboxItems: [makeMailboxItemCellUIModel(id: 1, isRead: true, isStarred: true)])
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, [item1])

        sut.selectionModifier.refreshSelectedItemsStatus(newMailboxItems: [])
        XCTAssertEqual(sut.selectionState.hasItems, false)
        XCTAssertEqual(sut.selectionState.selectedItems, [])
    }

    @MainActor
    func testRefreshSelectedItemsStatus_whenMoreItemsAreReturned_itDoesNotAddTheNewItemsToTheSelection() {
        sut.selectionModifier.refreshSelectedItemsStatus(newMailboxItems: [makeMailboxItemCellUIModel(id: 1, isRead: true, isStarred: true)])
        XCTAssertEqual(sut.selectionState.hasItems, false)
        XCTAssertEqual(sut.selectionState.selectedItems, [])
    }

    func testExitSelectionMode_itRemovesAllSelectedItems() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isStarred: false),
            .testData(id: 2, isStarred: false),
        ]
        items.forEach { sut.selectionModifier.addMailboxItem($0) }
        XCTAssertEqual(sut.selectionState.hasItems, true)

        sut.selectionModifier.exitSelectionMode()
        XCTAssertEqual(sut.selectionState.hasItems, false)
        XCTAssertEqual(sut.selectionState.selectedItems, [])
    }

    // MARK: Selection limit

    func testWhenSelectionLimitIsReached_cannotSelectMoreItemsUntilRoomIsGiven() {
        let items: [MailboxSelectedItem] = (0...101).map { .testData(id: $0) }

        for item in items {
            sut.selectionModifier.addMailboxItem(item)
        }

        XCTAssertEqual(sut.selectionState.selectedItems, Set(items[0..<100]))

        sut.selectionModifier.removeMailboxItem(items[0])
        sut.selectionModifier.addMailboxItem(items[100])

        XCTAssertEqual(sut.selectionState.selectedItems, Set(items[1..<101]))
    }

    func testAddMailboxItem_reportsSuccess() {
        let items: [MailboxSelectedItem] = (0...101).map { .testData(id: $0) }

        let results: [Bool] = items.map(sut.selectionModifier.addMailboxItem)

        XCTAssertEqual(results[0..<100], .init(repeating: true, count: 100))
        XCTAssertEqual(results[100], false)
    }

    // MARK: Select All

    func testInSelectAllMode_whenDeselectingAllAtOnce_HasItemsRemainsTrue() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1),
            .testData(id: 2),
        ]

        sut.selectionModifier.enterSelectAllMode(selecting: items)
        sut.selectionModifier.deselectAll(stayingInSelectAllMode: true)

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, [])
    }

    func testInSelectAllMode_whenRemovingSingleItem_selectAllModeIsEnded() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1),
            .testData(id: 2),
        ]

        sut.selectionModifier.enterSelectAllMode(selecting: items)
        sut.selectionModifier.removeMailboxItem(items[0])

        XCTAssertEqual(sut.selectionState.isSelectAllEnabled, false)
    }

    func testInSelectAllMode_whenExitingSelectAllMode_selectionIsPreserved() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1),
            .testData(id: 2),
        ]

        sut.selectionModifier.enterSelectAllMode(selecting: items)
        sut.selectionModifier.exitSelectAllMode()

        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))
        XCTAssertEqual(sut.selectionState.isSelectAllEnabled, false)
    }

    func testInSelectAllMode_whenExitingSelectionMode_everythingIsCleared() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1),
            .testData(id: 2),
        ]

        sut.selectionModifier.enterSelectAllMode(selecting: items)
        sut.selectionModifier.exitSelectionMode()

        XCTAssertEqual(sut.selectionState.selectedItems, [])
        XCTAssertEqual(sut.selectionState.isSelectAllEnabled, false)
    }

    func testEnteringSelectAllModeRespectsSelectionLimit() {
        let items: [MailboxSelectedItem] = (0...101).map { .testData(id: $0) }

        sut.selectionModifier.enterSelectAllMode(selecting: items)

        XCTAssertEqual(sut.selectionState.selectedItems, Set(items[0..<100]))
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
            attachmentsUIModel: .init(),
            attachmentsCount: 0,
            expirationDate: nil,
            snoozeDate: nil,
            isDraftMessage: false,
            shouldUseSnoozedColorForDate: false
        )
    }
}
