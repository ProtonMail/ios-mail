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

final class SelectionModeStateTests: XCTestCase {
    private var sut: SelectionModeState!

    override func setUp() {
        sut = .init()
    }

    func testInit() {
        XCTAssertEqual(sut.hasSelectedItems, false)
        XCTAssertEqual(sut.selectionStatus.readStatus, .noneRead)
        XCTAssertEqual(sut.selectionStatus.starStatus, .noneStarred)
    }

    func testAddMailboxItem_itAddsTheItem() {
        XCTAssertEqual(sut.hasSelectedItems, false)

        let item = MailboxSelectedItem.testData(id: 1, isRead: false, isStarred: true)
        sut.addMailboxItem(item)

        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectedItems, [item])
    }

    func testAddMailboxItem_whenChangesTheSelectionStatus_itUpdatesTheStatus() {
        sut.addMailboxItem(.testData(id: 1, isRead: false, isStarred: false))
        XCTAssertEqual(sut.selectionStatus.readStatus, .noneRead)
        XCTAssertEqual(sut.selectionStatus.starStatus, .noneStarred)

        sut.addMailboxItem(.testData(id: 2, isRead: true, isStarred: true))
        XCTAssertEqual(sut.selectionStatus.readStatus, .someRead)
        XCTAssertEqual(sut.selectionStatus.starStatus, .someStarred)
    }

    func testRemoveMailboxItem_itRemovesTheItem() {
        let item = MailboxSelectedItem.testData(id: 1, isRead: false, isStarred: true)
        sut.addMailboxItem(item)

        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectedItems, [item])

        sut.removeMailboxItem(item)
        XCTAssertEqual(sut.hasSelectedItems, false)
        XCTAssertEqual(sut.selectedItems, Set())
    }

    func testRemoveMailboxItem_whenChangesTheSelectionStatus_itUpdatesTheStatus() {
        let item1 = MailboxSelectedItem.testData(id: 1, isRead: true, isStarred: true)
        let item2 = MailboxSelectedItem.testData(id: 2, isRead: false, isStarred: false)

        [item1, item2].forEach(sut.addMailboxItem(_:))
        XCTAssertEqual(sut.selectionStatus.readStatus, .someRead)
        XCTAssertEqual(sut.selectionStatus.starStatus, .someStarred)

        sut.removeMailboxItem(item2)
        XCTAssertEqual(sut.selectionStatus.readStatus, .allRead)
        XCTAssertEqual(sut.selectionStatus.starStatus, .allStarred)
    }

    func testHasSelectedItems_whenNoItems_itReturnsFalse() {
        XCTAssertEqual(sut.hasSelectedItems, false)
        XCTAssertEqual(sut.selectedItems, Set())
    }

    func testHasSelectedItems_whenThereAreItems_itReturnsTrue() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1),
            .testData(id: 2),
        ]
        items.forEach(sut.addMailboxItem(_:))

        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectedItems, Set(items))

        sut.removeMailboxItem(items[1])

        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectedItems, [items[0]])
    }

    func testSelectionReadStatus_whenAllRead_itReturnsAllRead() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: true),
            .testData(id: 2, isRead: true),
        ]
        items.forEach(sut.addMailboxItem(_:))

        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectionStatus.readStatus, .allRead)
    }

    func testSelectionReadStatus_whenMixedReadStatus_itReturnsSomeRead() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: true),
            .testData(id: 2, isRead: false),
        ]
        items.forEach(sut.addMailboxItem(_:))

        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectionStatus.readStatus, .someRead)
    }

    func testSelectionReadStatus_whenNoneRead_itReturnsNoneRead() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: false),
            .testData(id: 2, isRead: false),
        ]
        items.forEach(sut.addMailboxItem(_:))

        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectionStatus.readStatus, .noneRead)
    }

    func testSelectionStarStatus_whenAllStarred_itReturnsAllStarred() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isStarred: true),
            .testData(id: 2, isStarred: true),
        ]
        items.forEach(sut.addMailboxItem(_:))

        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectionStatus.starStatus, .allStarred)
    }

    func testSelectionStarStatus_whenMixedStarStatus_itReturnsSomeStarred() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isStarred: false),
            .testData(id: 2, isStarred: true),
        ]
        items.forEach(sut.addMailboxItem(_:))

        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectionStatus.starStatus, .someStarred)
    }

    func testSelectionStarStatus_whenNoneStarred_itReturnsNoneStarred() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isStarred: false),
            .testData(id: 2, isStarred: false),
        ]
        items.forEach(sut.addMailboxItem(_:))

        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectionStatus.starStatus, .noneStarred)
    }

    func testRefreshSelectedItemsStatus_whenStatusDoesChanges_itChangesTheSelectionStatus() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: false, isStarred: false),
            .testData(id: 2, isRead: false, isStarred: false),
        ]
        items.forEach(sut.addMailboxItem(_:))
        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectedItems, Set(items))
        XCTAssertEqual(sut.selectionStatus.readStatus, .noneRead)
        XCTAssertEqual(sut.selectionStatus.starStatus, .noneStarred)

        sut.refreshSelectedItemsStatus { _ in
            let newItems = items.map {
                MailboxSelectedItem(id: $0.id, isRead: !$0.isRead, isStarred: !$0.isStarred)
            }
            return Set(newItems)
        }
        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectedItems, Set(items))
        XCTAssertEqual(sut.selectionStatus.readStatus, .allRead)
        XCTAssertEqual(sut.selectionStatus.starStatus, .allStarred)
    }

    func testRefreshSelectedItemsStatus_whenStatusDoesNotChange_itKeepsTheSelectionStatus() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: true, isStarred: true),
            .testData(id: 2, isRead: true, isStarred: true),
        ]
        items.forEach(sut.addMailboxItem(_:))
        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectedItems, Set(items))
        XCTAssertEqual(sut.selectionStatus.readStatus, .allRead)
        XCTAssertEqual(sut.selectionStatus.starStatus, .allStarred)

        sut.refreshSelectedItemsStatus { _ in
            return Set(items)
        }
        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectedItems, Set(items))
        XCTAssertEqual(sut.selectionStatus.readStatus, .allRead)
        XCTAssertEqual(sut.selectionStatus.starStatus, .allStarred)
    }

    func testRefreshSelectedItemsStatus_whenLessItemsAreReturned_itRemovesTheNotReturnedItemsFromSelection() {
        let item1 = MailboxSelectedItem.testData(id: 1, isRead: true, isStarred: true)
        let item2 = MailboxSelectedItem.testData(id: 2, isRead: true, isStarred: true)
        [item1, item2].forEach(sut.addMailboxItem(_:))
        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectedItems, [item1, item2])

        sut.refreshSelectedItemsStatus { _ in
            return [item1]
        }
        XCTAssertEqual(sut.hasSelectedItems, true)
        XCTAssertEqual(sut.selectedItems, [item1])

        sut.refreshSelectedItemsStatus { _ in
            return []
        }
        XCTAssertEqual(sut.hasSelectedItems, false)
        XCTAssertEqual(sut.selectedItems, [])
    }

    func testRefreshSelectedItemsStatus_whenSelectedItemsDoNotChange_itDoesNotTriggerHasSelectedItemsPublisher() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: true, isStarred: true),
            .testData(id: 2, isRead: true, isStarred: true),
        ]
        items.forEach(sut.addMailboxItem(_:))

        let observation = sut.$hasSelectedItems.dropFirst().sink { newValue in
            XCTFail("hasSelectedItems should not send a value if it does not change the value")
        }

        sut.refreshSelectedItemsStatus { _ in
            return Set(items)
        }
    }

    func testExitSelectionMode_itRemovesAllSelectedItems() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isStarred: false),
            .testData(id: 2, isStarred: false),
        ]
        items.forEach(sut.addMailboxItem(_:))
        XCTAssertEqual(sut.hasSelectedItems, true)

        sut.exitSelectionMode()
        XCTAssertEqual(sut.hasSelectedItems, false)
        XCTAssertEqual(sut.selectedItems, [])
    }
}
