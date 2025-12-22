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

import XCTest

extension OnboardingRobot {
    private var actionButton: XCUIElement {
        rootElement.buttons[Identifiers.actionButton]
    }

    func dismissIfDisplayed() {
        var nextActionAttempts = 0

        // Keep a threshold and make the test fail if for some reason the root element is not dismissed.
        while rootElement.isHittable && nextActionAttempts < nextActionThreshold {
            nextActionAttempts += 1
            actionButton.tap()
        }
    }
}

private let nextActionThreshold = 5

private struct Identifiers {
    static let actionButton = "onboarding.actionButton"
}
