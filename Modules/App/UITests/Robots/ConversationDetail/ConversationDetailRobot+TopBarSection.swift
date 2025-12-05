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

extension ConversationDetailRobot {
    // MARK: UI Elements

    private var backButton: XCUIElement {
        application.buttons[Identifiers.backButton].firstMatch
    }

    private var starButton: XCUIElement {
        application.buttons[Identifiers.starButton].firstMatch
    }

    private var subjectLine: XCUIElement {
        application.staticTexts[Identifiers.subjectText].firstMatch
    }

    // MARK: Actions

    func tapBackButton() {
        backButton.tap()
    }

    func tapBackChevronButton() {
        application.buttons[Identifiers.backChevronButton].firstMatch.tap()
    }

    func tapStarButton() {
        starButton.tap()
    }

    // MARK: Assertions

    func hasTopBarItems() {
        XCTAssertTrue(backButton.isHittable)
        XCTAssertTrue(starButton.isHittable)
    }

    func hasSubjectLine() {
        XCTAssertTrue(subjectLine.isHittable)
    }
}

private struct Identifiers {
    static let backChevronButton = "chevron.backward"
    static let backButton = "detail.backButton"
    static let starButton = "detail.starButton"
    static let subjectText = "detail.subjectText"
}
