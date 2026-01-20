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
    // MARK: UI Elements

    private var hamburgerButton: XCUIElement {
        application.buttons[Identifiers.hamburgerButton].firstMatch
    }

    private var backButton: XCUIElement {
        application.buttons[Identifiers.backButton].firstMatch
    }

    private var toolbarTitle: XCUIElement {
        application.staticTexts[Identifiers.titleText].firstMatch
    }

    // MARK: Actions

    func openSidebarMenu() {
        hamburgerButton.tap()
    }
}

private struct Identifiers {
    static let hamburgerButton = "main.toolbar.hamburgerButton"
    static let backButton = "main.toolbar.backButton"
    static let titleText = "main.toolbar.titleText"
}
