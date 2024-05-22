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
    private var actionsGroup: XCUIElement {
        rootElement.otherElements[Identifiers.rootItem]
    }

    private var actionButton1: XCUIElement {
        actionsGroup.buttons[Identifiers.button1]
    }

    private var actionButton2: XCUIElement {
        actionsGroup.buttons[Identifiers.button2]
    }

    private var actionButton3: XCUIElement {
        actionsGroup.buttons[Identifiers.button3]
    }

    private var actionButton4: XCUIElement {
        actionsGroup.buttons[Identifiers.button4]
    }

    private var actionButton5: XCUIElement {
        actionsGroup.buttons[Identifiers.button5]
    }

    func tapAction1() {
        actionButton1.tap()
    }

    func tapAction2() {
        actionButton2.tap()
    }

    func tapAction3() {
        actionButton3.tap()
    }

    func tapAction4() {
        actionButton4.tap()
    }

    func tapAction5() {
        actionButton5.tap()
    }

    func verifyActionBarElements() {
        XCTAssertTrue(actionButton1.isHittable)
        XCTAssertTrue(actionButton2.isHittable)
        XCTAssertTrue(actionButton3.isHittable)
        XCTAssertTrue(actionButton4.isHittable)
        XCTAssertTrue(actionButton5.isHittable)
    }

    func verifyActionBarNotShown() {
        XCTAssertFalse(actionsGroup.isHittable)
    }
}

private struct Identifiers {
    static let rootItem = "mailbox.actionBar.rootItem"
    static let button1 = "mailbox.actionBar.button1"
    static let button2 = "mailbox.actionBar.button2"
    static let button3 = "mailbox.actionBar.button3"
    static let button4 = "mailbox.actionBar.button4"
    static let button5 = "mailbox.actionBar.button5"
}
