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

class UITestSidebarListItemEntryModel: UITestSidebarListItemEntryBaseModel {
    let label: String

    init(parent: XCUIElement, label: String) {
        self.label = label
        super.init(parent: parent)
    }

    // MARK: UI Elements

    override var rootItem: XCUIElement {
        let predicate = NSPredicate(format: "label BEGINSWITH[c] %@", label)
        return application.buttons.containing(predicate).firstMatch
    }

    private var badgeElement: XCUIElement {
        rootItem.staticTexts[Identifiers.badgeItem]
    }

    private var chevronButton: XCUIElement {
        rootItem.buttons[Identifiers.chevron]
    }

    // MARK: Actions

    func tapChevron() {
        chevronButton.tap()
    }

    // MARK: Assertions

    func isBadgeShown(value: String) {
        XCTAssertEqual(value, badgeElement.label)
    }

    func isBadgeNotShown() {
        XCTAssertFalse(badgeElement.exists)
    }

    func isChevronShown() {
        XCTAssertTrue(chevronButton.exists)
    }

    func isChevronNotShown() {
        XCTAssertFalse(chevronButton.exists)
    }
}

private struct Identifiers {
    static let badgeItem = "sidebar.button.badgeIcon"
    static let chevron = "sidebar.button.chevron"
}
