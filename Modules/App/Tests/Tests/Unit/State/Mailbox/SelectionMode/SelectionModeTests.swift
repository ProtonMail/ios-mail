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

    func testRefreshSelectedItemsStatus_whenStatusDoesChange_itKeepsTheSelectionStatus() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: false, isStarred: false),
            .testData(id: 2, isRead: false, isStarred: false),
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))

        sut.selectionModifier.refreshSelectedItemsStatus { _ in
            let newItems = items.map {
                MailboxSelectedItem(id: $0.id, isRead: !$0.isRead, isStarred: !$0.isStarred)
            }
            return Set(newItems)
        }
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(Set(sut.selectionState.selectedItems.map(\.id)), Set(items.map(\.id)))
    }

    func testRefreshSelectedItemsStatus_whenStatusDoesNotChange_itKeepsTheSelectionStatus() {
        let items: [MailboxSelectedItem] = [
            .testData(id: 1, isRead: true, isStarred: true),
            .testData(id: 2, isRead: true, isStarred: true),
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))

        sut.selectionModifier.refreshSelectedItemsStatus { _ in
            return Set(items)
        }
        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, Set(items))
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
