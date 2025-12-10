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

    private var container: XCUIElement {
        application.otherElements[Identifiers.rootItem]
    }

    private var emptyTitle: XCUIElement {
        container.staticTexts[Identifiers.emptyTitle]
    }

    private var emptyDescription: XCUIElement {
        container.staticTexts[Identifiers.emptyDescription]
    }

    // MARK: Assertions

    func verifyEmptyMailboxState() {
        XCTAssertTrue(emptyTitle.isHittable)
        XCTAssertTrue(emptyDescription.isHittable)
    }
}

private struct Identifiers {
    static let rootItem = "mailbox.empty.rootItem"
    static let emptyTitle = "mailbox.empty.title"
    static let emptyDescription = "mailbox.empty.description"
}
