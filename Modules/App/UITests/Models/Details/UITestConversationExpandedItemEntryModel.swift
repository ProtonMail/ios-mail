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

struct UITestConversationExpandedItemEntryModel: ApplicationHolder {
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

    private var senderAddress: XCUIElement {
        rootItem.staticTexts[Identifiers.senderAddress]
    }

    private var dateText: XCUIElement {
        rootItem.staticTexts[Identifiers.date]
    }

    private var recipientsSummary: XCUIElement {
        rootItem.staticTexts[Identifiers.recipientsSummary]
    }

    private var threeDotsButton: XCUIElement {
        rootItem.buttons[Identifiers.threeDotsButton]
    }

    // MARK: - Actions

    func toggleItem() {
        withItemDisplayed { senderName.tap() }
    }

    func tapThreeDots() {
        withItemDisplayed { threeDotsButton.tap() }
    }

    private func scrollTo() -> Bool {
        UITestVisibilityHelper.shared.findElement(element: rootItem, parent: parent)
    }

    // MARK: - Assertions

    func isDisplayed() {
        withItemDisplayed { XCTAssertTrue(rootItem.waitUntilShown()) }
    }

    func hasSenderName(_ name: String) {
        withItemDisplayed { XCTAssertEqual(senderName.label, name) }
    }

    func hasSenderAddress(_ address: String) {
        withItemDisplayed { XCTAssertEqual(senderAddress.label, address) }
    }

    func hasDate(_ date: String) {
        withItemDisplayed { XCTAssertEqual(dateText.label, date) }
    }

    func hasRecipientsSummary(_ value: String) {
        withItemDisplayed { XCTAssertEqual(recipientsSummary.label, value) }
    }

    func withItemDisplayed(block: () -> Void) {
        XCTAssertTrue(scrollTo())
        block()
    }
}

private struct Identifiers {
    static let parent = "detail.rootItem"
    static let rootItem = "detail.cell.expanded"
    static let senderName = "detail.header.sender.name"
    static let senderAddress = "detail.header.sender.address"
    static let date = "detail.header.date"
    static let recipientsSummary = "detail.header.recipients.summary"
    static let threeDotsButton = "detail.header.button.actions"
}
