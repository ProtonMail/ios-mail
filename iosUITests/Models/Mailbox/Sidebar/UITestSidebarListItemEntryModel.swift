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

struct UITestSidebarListItemEntryModel: ApplicationHolder {
    let label: String

    // MARK: UI Elements

    private var rootItem: XCUIElement {
        let predicate = NSPredicate(format: "label BEGINSWITH[c] %@", label)
        return application.buttons.containing(predicate).firstMatch
    }

    private var iconElement: XCUIElement {
        rootItem.images[Identifiers.iconItem]
    }

    private var textElement: XCUIElement {
        rootItem.staticTexts[Identifiers.textItem]
    }

    private var badgeElement: XCUIElement {
        rootItem.staticTexts[Identifiers.badgeItem]
    }

    // MARK: Actions

    func tap() {
        rootItem.tap()
    }

    // MARK: Assertions

    func isIconDisplayed() {
        XCTAssertTrue(iconElement.exists)
    }

    func isTextMatching(value: String) {
        XCTAssertEqual(value, textElement.label)
    }

    func isBadgeShown(value: String) {
        XCTAssertEqual(value, badgeElement.label)
    }

    func isBadgeNotShown() {
        XCTAssertEqual("", badgeElement.label)
    }
}

private struct Identifiers {
    static let buttonItem = "sidebar.button.container"
    static let iconItem = "sidebar.button.folderIcon"
    static let badgeItem = "sidebar.button.badgeIcon"
    static let textItem = "sidebar.button.labelText"
}
