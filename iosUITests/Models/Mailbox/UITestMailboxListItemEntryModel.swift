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

struct UITestMailboxListItemEntryModel: ApplicationHolder {
    let index: Int

    // MARK: UI Elements

    private var rootItem: XCUIElement {
        application.otherElements["\(Identifiers.cell)\(index)"]
    }

    private var avatarTextElement: XCUIElement {
        rootItem.staticTexts[Identifiers.avatarText]
    }

    private var avatarCheckedElement: XCUIElement {
        rootItem.images[Identifiers.avatarChecked]
    }

    private var senderElement: XCUIElement {
        rootItem.staticTexts[Identifiers.senderText]
    }

    private var subjectElement: XCUIElement {
        rootItem.staticTexts[Identifiers.subjectText]
    }

    private var countElement: XCUIElement {
        rootItem.staticTexts[Identifiers.countText]
    }

    private var dateElement: XCUIElement {
        rootItem.staticTexts[Identifiers.dateText]
    }

    private var starElement: XCUIElement {
        rootItem.staticTexts[Identifiers.starIcon]
    }

    // MARK: Actions

    func tap() {
        rootItem.tap()
    }

    func longPress() {
        rootItem.press(forDuration: 2)
    }

    func tapAvatar() {
        avatarTextElement.tap()
    }

    func tapCheckedAvatar() {
        avatarCheckedElement.tap()
    }
    
    func waitForExistence(timeout: TimeInterval) {
        XCTAssertTrue(rootItem.waitForExistence(timeout: timeout))
    }

    // MARK: Assertions

    func doesNotExist() {
        XCTAssertFalse(rootItem.exists)
    }
    
    func isItemSelected() {
        XCTAssertFalse(avatarTextElement.exists)
        XCTAssertTrue(avatarCheckedElement.exists)
    }

    func isItemUnselected() {
        XCTAssertTrue(avatarTextElement.exists)
        XCTAssertFalse(avatarCheckedElement.exists)
    }

    func hasInitials(_ value: String) {
        XCTAssertEqual(value, avatarTextElement.label)
    }

    func hasSenders(_ value: String) {
        XCTAssertEqual(value, senderElement.label)
    }

    func hasSubject(_ value: String) {
        XCTAssertEqual(value, subjectElement.label)
    }

    func hasDate(_ value: String) {
        XCTAssertEqual(value, dateElement.label)
    }

    func hasCount(_ value: Int) {
        XCTAssertEqual(String(value), countElement.label)
    }

    func hasNoCount() {
        XCTAssertFalse(countElement.exists)
    }
}

private struct Identifiers {
    static let cell = "mailbox.list.cell"
    static let avatarText = "avatar.text"
    static let avatarChecked = "avatar.checked"
    static let senderText = "cell.senderText"
    static let subjectText = "cell.subjectText"
    static let countText = "count.text"
    static let starIcon = "cell.starIcon"
    static let dateText = "cell.dateText"
}
