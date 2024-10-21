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
        let items: [ID] = [
            .init(value: 1),
            .init(value: 2)
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

        let item = ID(value: 1)
        sut.selectionModifier.addMailboxItem(item)

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, [item])
    }

    func testRemoveMailboxItem_itRemovesTheItem() {
        let item = ID(value: 1)
        sut.selectionModifier.addMailboxItem(item)

        XCTAssertEqual(sut.selectionState.hasItems, true)
        XCTAssertEqual(sut.selectionState.selectedItems, [item])

        sut.selectionModifier.removeMailboxItem(item)
        XCTAssertEqual(sut.selectionState.hasItems, false)
        XCTAssertEqual(sut.selectionState.selectedItems, Set())
    }

    func testRefreshSelectedItemsStatus_whenStatusDoesNotChange_itKeepsTheSelectionStatus() {
        let items: [ID] = [
            .init(value: 1),
            .init(value: 2)
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

    func testExitSelectionMode_itRemovesAllSelectedItems() {
        let items: [ID] = [
            .init(value: 1),
            .init(value: 2)
        ]
        items.forEach(sut.selectionModifier.addMailboxItem(_:))
        XCTAssertEqual(sut.selectionState.hasItems, true)

        sut.selectionModifier.exitSelectionMode()
        XCTAssertEqual(sut.selectionState.hasItems, false)
        XCTAssertEqual(sut.selectionState.selectedItems, [])
    }
}
