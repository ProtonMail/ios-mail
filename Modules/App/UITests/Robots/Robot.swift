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

protocol Robot: ApplicationHolder {
    var rootElement: XCUIElement { get }
    func verifyShown() -> Self
    func verifyHidden()

    init()
}

extension Robot {
    private var timeout: TimeInterval { 60 }

    @discardableResult func verifyShown() -> Self {
        XCTAssert(
            rootElement.waitForExistence(timeout: timeout),
            "Root element of \(self) is not displayed."
        )

        return self
    }

    func waitMessageBySubject(subject: String) {
        let subjectText = application.staticTexts[subject].firstMatch
        subjectText.waitUntilShown()
    }

    func clickMessageBySubject(subject: String) {
        let subjectText = application.staticTexts[subject].firstMatch
        subjectText.tap()
    }

    func verifyHidden() {
        XCTAssertFalse(rootElement.isHittable, "Root element of \(self) is displayed.")
    }

    @discardableResult init(_ block: (Self) -> Void) {
        self.init()
        block(self)
    }
}
