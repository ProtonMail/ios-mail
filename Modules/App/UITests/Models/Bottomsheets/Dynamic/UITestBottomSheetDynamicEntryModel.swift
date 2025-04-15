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

struct UITestBottomSheetDynamicEntryModel: ApplicationHolder {
    let section: Int
    let index: Int
    let text: String

    // MARK: UI Elements

    private var rootElement: XCUIElement {
        application.otherElements[Identifiers.actionRoot(section: section, index: index)]
    }

    private var actionIcon: XCUIElement {
        rootElement.images[Identifiers.actionIcon]
    }

    private var actionText: XCUIElement {
        rootElement.staticTexts[Identifiers.actionText]
    }

    // MARK: Actions

    func tap() {
        rootElement.tap()
    }

    // MARK: Assertions

    func hasIcon() {
        XCTAssert(actionIcon.exists)
    }

    func hasText(_ value: String) {
        XCTAssertEqual(actionText.label, value)
    }

    func isShown() {
        XCTAssert(rootElement.exists)
    }
}

private struct Identifiers {
    static let actionPickerSection = "actionPicker.section"
    static let actionIcon = "actionPicker.action.icon"
    static let actionText = "actionPicker.action.text"

    static func actionRoot(section: Int, index: Int) -> String {
        "actionPicker.section\(section).action\(index)"
    }
}
