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
import XCTest

struct UITestConversationCollapsedItemEntryModel: ApplicationHolder {
    let index: Int

    // MARK: UI Elements

    private var parent: XCUIElement {
        application.otherElements[Identifiers.parent]
    }

    private var rootItem: XCUIElement {
        parent.otherElements["\(Identifiers.rootItem)#\(index)"]
    }

    private var senderName: XCUIElement {
        rootItem.staticTexts[Identifiers.senderName]
    }

    private var dateText: XCUIElement {
        rootItem.staticTexts[Identifiers.date]
    }

    private var preview: XCUIElement {
        rootItem.staticTexts[Identifiers.preview]
    }

    // MARK: - Actions

    func toggleItem() {
        withItemDisplayed { rootItem.tap() }
    }

    private func scrollTo() -> Bool {
        UITestVisibilityHelper.shared.findElement(element: rootItem, parent: parent)
    }

    // MARK: - Assertions

    func isDisplayed() {
        withItemDisplayed { XCTAssertTrue(rootItem.exists) }
    }

    func hasSenderName(_ name: String) {
        withItemDisplayed { XCTAssertEqual(senderName.label, name) }
    }

    func hasDate(_ date: String) {
        withItemDisplayed { XCTAssertEqual(dateText.label, date) }
    }

    func hasPreview(_ value: String) {
        withItemDisplayed { XCTAssertEqual(preview.label, value) }
    }

    func withItemDisplayed(block: () -> Void) {
        XCTAssertTrue(scrollTo())
        block()
    }
}

private struct Identifiers {
    static let parent = "detail.rootItem"
    static let rootItem = "detail.cell.collapsed"
    static let senderName = "detail.cell.collapsed.sender.name"
    static let date = "detail.cell.collapsed.date"
    static let preview = "detail.cell.collapsed.preview"
}
