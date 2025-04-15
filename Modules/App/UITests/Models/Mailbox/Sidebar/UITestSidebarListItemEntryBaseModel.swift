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

open class UITestSidebarListItemEntryBaseModel: ApplicationHolder {
    let parent: XCUIElement

    init(parent: XCUIElement) {
        self.parent = parent
    }

    // MARK: UI Elements

    var rootItem: XCUIElement {
        fatalError("Must be overridden by subclasses")
    }

    private var iconElement: XCUIElement {
        rootItem.children(matching: .any)[Identifiers.iconItem]
    }

    private var textElement: XCUIElement {
        rootItem.staticTexts[Identifiers.textItem]
    }

    // MARK: Actions

    func findElement() {
        XCTAssertTrue(UITestVisibilityHelper.shared.findElement(element: rootItem, parent: parent))
    }

    func tap() {
        rootItem.tap()
    }

    // MARK: Assertions

    func isNotShown() {
        XCTAssertFalse(rootItem.exists)
    }

    func isIconDisplayed() {
        XCTAssertTrue(iconElement.exists)
    }

    func isTextMatching(value: String) {
        XCTAssertEqual(value, textElement.label)
    }
}

private struct Identifiers {
    static let iconItem = "sidebar.button.icon"
    static let textItem = "sidebar.button.text"
}
