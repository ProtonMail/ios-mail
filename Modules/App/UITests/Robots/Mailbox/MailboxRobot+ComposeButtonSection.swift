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

extension MailboxRobot {
    private var composeButtonRootElement: XCUIElement {
        application.buttons[Identifiers.rootElement]
    }

    private var composeButtonIcon: XCUIElement {
        composeButtonRootElement.images[Identifiers.icon]
    }

    private var composeButtonText: XCUIElement {
        composeButtonRootElement.staticTexts[Identifiers.text]
    }

    func tapComposeButton() {
        composeButtonRootElement.tap()
    }

    func hasComposeButtonCollapsed() {
        XCTAssertTrue(composeButtonIcon.isHittable)
        XCTAssertFalse(composeButtonText.exists)
    }

    func hasComposeButtonExpanded() {
        XCTAssertTrue(composeButtonIcon.isHittable)
        XCTAssertEqual(composeButtonText.label, "Compose")
    }

    func hasComposeButtonHidden() {
        XCTAssertFalse(composeButtonIcon.isHittable)
    }
}

private struct Identifiers {
    static let rootElement = "compose.button"
    static let icon = "compose.button.icon"
    static let text = "compose.button.text"
}
