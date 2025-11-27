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

extension SystemPreviewRobot {
    // MARK: UI Elements

    private var topLabel: XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", "Actions Menu")
        return application.buttons.containing(predicate).firstMatch
    }

    private var shareButton: XCUIElement {
        application.buttons[UITestSystemIdentifiers.shareButton]
    }

    private var markupButton: XCUIElement {
        application.switches[UITestSystemIdentifiers.markupButton]
    }

    private var doneButton: XCUIElement {
        application.navigationBars.buttons.firstMatch
    }

    private var loadingIndicator: XCUIElement {
        application.activityIndicators.firstMatch
    }

    // MARK: Actions

    func tapDoneButton() {
        doneButton.tap()
    }

    // MARK: Assertions

    func verifyLoading() {
        XCTAssertTrue(loadingIndicator.exists)
    }

    func verifyGone() {
        XCTAssertTrue(topLabel.waitUntilGone())
        XCTAssertTrue(shareButton.waitUntilGone())
        XCTAssertTrue(markupButton.waitUntilGone())
    }

    /// Since it's a system component, we assume that it is shown if top label, share and markup buttons are shown.
    @discardableResult func verifyShown(withAttachmentName name: String) -> Self {
        XCTAssertTrue(loadingIndicator.waitUntilGone())

        XCTAssertTrue(topLabel.waitForExistence(timeout: buttonsTimeout))
        XCTAssertTrue(topLabel.label.contains(name))

        XCTAssertTrue(shareButton.waitForExistence(timeout: buttonsTimeout))
        XCTAssertTrue(shareButton.exists)

        XCTAssertTrue(markupButton.waitForExistence(timeout: buttonsTimeout))
        XCTAssertTrue(markupButton.exists)

        XCTAssertTrue(doneButton.exists)

        return self
    }

    private var buttonsTimeout: TimeInterval { 2 }
}
