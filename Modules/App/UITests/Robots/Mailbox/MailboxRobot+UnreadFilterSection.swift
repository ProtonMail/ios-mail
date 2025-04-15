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
    private var unreadCountRootElement: XCUIElement {
        application.buttons[Identifiers.rootItem]
    }

    private var unreadCountLabel: XCUIElement {
        unreadCountRootElement.staticTexts[Identifiers.countLabel]
    }

    private var unreadCountValue: XCUIElement {
        unreadCountRootElement.staticTexts[Identifiers.countValue]
    }

    func tapUnreadFilter() {
        unreadCountRootElement.tap()
    }

    func hasUnreadFilterShown(withUnreadCount count: String) {
        XCTAssertTrue(unreadCountRootElement.waitUntilShown())
        XCTAssertEqual(unreadCountLabel.label, "Unread")
        XCTAssertEqual(unreadCountValue.label, count)
    }

    func hasNoUnreadFilterShown() {
        XCTAssertTrue(unreadCountRootElement.waitUntilGone())
    }
}

private struct Identifiers {
    static let rootItem = "unread.filter.button"
    static let countLabel = "unread.filter.label"
    static let countValue = "unread.filter.value"
}
