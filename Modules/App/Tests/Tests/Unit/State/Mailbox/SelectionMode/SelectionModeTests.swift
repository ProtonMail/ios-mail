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
        sut = .init()
    }

    func testInit() {
        XCTAssertEqual(sut.selectionState.hasItems, false)
        XCTAssertEqual(sut.selectionState.collectionStatus.readStatus, .noneRead)
        XCTAssertEqual(sut.selectionState.collectionStatus.starStatus, .noneStarred)
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
        items.forEach(sut.selectionModifier.addMailboxItem(_:))

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))

        sut.selectionModifier.removeMailboxItem(items[1])

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, [items[0]])
    }

    func testSelectionReadStatus_whenAllRead_itReturnsAllRead() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: true),
            .testData(id: 2, isRead: true),
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.collectionStatus.readStatus, .allRead)
    }

    func testSelectionReadStatus_whenMixedReadStatus_itReturnsSomeRead() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: true),
            .testData(id: 2, isRead: false),
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.collectionStatus.readStatus, .someRead)
    }

    func testSelectionReadStatus_whenNoneRead_itReturnsNoneRead() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: false),
            .testData(id: 2, isRead: false),
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.collectionStatus.readStatus, .noneRead)
    }

    func testSelectionStarStatus_whenAllStarred_itReturnsAllStarred() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isStarred: true),
            .testData(id: 2, isStarred: true),
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.collectionStatus.starStatus, .allStarred)
    }

    func testSelectionStarStatus_whenMixedStarStatus_itReturnsSomeStarred() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isStarred: false),
            .testData(id: 2, isStarred: true),
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.collectionStatus.starStatus, .someStarred)
    }

    func testSelectionStarStatus_whenNoneStarred_itReturnsNoneStarred() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isStarred: false),
            .testData(id: 2, isStarred: false),
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.collectionStatus.starStatus, .noneStarred)
    }

    // MARK: SelectionModeStateModifier

    func testAddMailboxItem_itAddsTheItem() {
        XCTAssertEqual(sut.selectionState.hasItems, false)

        let item = MailboxSelectedItem.testData(id: 1, isRead: false, isStarred: true)
        sut.selectionModifier.addMailboxItem(item)

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, [item])
    }

    func testAddMailboxItem_whenChangesTheSelectionStatus_itUpdatesTheStatus() {
        sut.selectionModifier.addMailboxItem(.testData(id: 1, isRead: false, isStarred: false))
        XCTAssertEqual(sut.selectionState.collectionStatus.readStatus, .noneRead)
        XCTAssertEqual(sut.selectionState.collectionStatus.starStatus, .noneStarred)

        sut.selectionModifier.addMailboxItem(.testData(id: 2, isRead: true, isStarred: true))
        XCTAssertEqual(sut.selectionState.collectionStatus.readStatus, .someRead)
        XCTAssertEqual(sut.selectionState.collectionStatus.starStatus, .someStarred)
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

    func testRemoveMailboxItem_whenChangesTheSelectionStatus_itUpdatesTheStatus() {
        let item1 = MailboxSelectedItem.testData(id: 1, isRead: true, isStarred: true)
        let item2 = MailboxSelectedItem.testData(id: 2, isRead: false, isStarred: false)

        [item1, item2].forEach(sut.selectionModifier.addMailboxItem(_:))
        XCTAssertEqual(sut.selectionState.collectionStatus.readStatus, .someRead)
        XCTAssertEqual(sut.selectionState.collectionStatus.starStatus, .someStarred)

        sut.selectionModifier.removeMailboxItem(item2)
        XCTAssertEqual(sut.selectionState.collectionStatus.readStatus, .allRead)
        XCTAssertEqual(sut.selectionState.collectionStatus.starStatus, .allStarred)
    }

    func testRefreshSelectedItemsStatus_whenStatusDoesChanges_itChangesTheSelectionStatus() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: false, isStarred: false),
            .testData(id: 2, isRead: false, isStarred: false),
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))
        XCTAssertEqual(sut.selectionState.collectionStatus.readStatus, .noneRead)
        XCTAssertEqual(sut.selectionState.collectionStatus.starStatus, .noneStarred)

        sut.selectionModifier.refreshSelectedItemsStatus { _ in
            let newItems = items.map {
                MailboxSelectedItem(id: $0.id, isRead: !$0.isRead, isStarred: !$0.isStarred)
            }
            return Set(newItems)
        }
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))
        XCTAssertEqual(sut.selectionState.collectionStatus.readStatus, .allRead)
        XCTAssertEqual(sut.selectionState.collectionStatus.starStatus, .allStarred)
    }

    func testRefreshSelectedItemsStatus_whenStatusDoesNotChange_itKeepsTheSelectionStatus() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: true, isStarred: true),
            .testData(id: 2, isRead: true, isStarred: true),
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))
        XCTAssertEqual(sut.selectionState.collectionStatus.readStatus, .allRead)
        XCTAssertEqual(sut.selectionState.collectionStatus.starStatus, .allStarred)

        sut.selectionModifier.refreshSelectedItemsStatus { _ in
            return Set(items)
        }
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))
        XCTAssertEqual(sut.selectionState.collectionStatus.readStatus, .allRead)
        XCTAssertEqual(sut.selectionState.collectionStatus.starStatus, .allStarred)
    }

    func testRefreshSelectedItemsStatus_whenLessItemsAreReturned_itRemovesTheNotReturnedItemsFromSelection() {
        let item1 = MailboxSelectedItem.testData(id: 1, isRead: true, isStarred: true)
        let item2 = MailboxSelectedItem.testData(id: 2, isRead: true, isStarred: true)
        [item1, item2].forEach(sut.selectionModifier.addMailboxItem(_:))
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, [item1, item2])

        sut.selectionModifier.refreshSelectedItemsStatus { _ in
            return [item1]
        }
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, [item1])

        sut.selectionModifier.refreshSelectedItemsStatus { _ in
            return []
        }
        XCTAssertEqual(sut.selectionState.hasItems, false)
        XCTAssertEqual(sut.selectionState.selectedItems, [])
    }

    func testRefreshSelectedItemsStatus_whenSelectedItemsDoNotChange_itDoesNotTriggerHasSelectedItemsPublisher() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: true, isStarred: true),
            .testData(id: 2, isRead: true, isStarred: true),
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))

        let observation = sut.selectionState.$hasItems.dropFirst().sink { newValue in
            XCTFail("hasSelectedItems should not send a value if it does not change the value")
        }

        sut.selectionModifier.refreshSelectedItemsStatus { _ in
            return Set(items)
        }
    }

    func testExitSelectionMode_itRemovesAllSelectedItems() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isStarred: false),
            .testData(id: 2, isStarred: false),
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))
        XCTAssertEqual(sut.selectionState.hasItems, true)

        sut.selectionModifier.exitSelectionMode()
        XCTAssertEqual(sut.selectionState.hasItems, false)
        XCTAssertEqual(sut.selectionState.selectedItems, [])
    }
}
