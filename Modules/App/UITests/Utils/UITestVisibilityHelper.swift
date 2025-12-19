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

/// Helper to allow locating items and slightly swipe upwards or downwards depending on where the `XCUIElement` is.
///
/// It takes into account whether the element is on screen (within the `XCUIApplication` frame bounds) and if it's outside
/// the inset zones (region of the screen where system UI elements are located - Home bar and Navigation bar are two examples).
class UITestVisibilityHelper: ApplicationHolder {
    static let shared = UITestVisibilityHelper()
    private let topSafeInsetSize = 60.0
    private let bottomSafeInsetSize = 50.0

    func findElement(element: XCUIElement, parent: XCUIElement, maxAttempts: Int = 5) -> Bool {
        for _ in 1...maxAttempts {
            let visibility = evaluateElementVisibility(element: element)
            if !visibility.isWithinSafeBounds {
                switch visibility.adjustDirection {
                case .upwards:
                    parent.swipeUp(velocity: .slow)
                    continue
                case .downwards:
                    parent.swipeDown(velocity: .slow)
                    continue
                case .none:
                    return false
                }
            }
            break
        }

        return true
    }

    private func evaluateElementVisibility(element: XCUIElement) -> UITestVisibilityResult {
        let applicationFrame = application.windows.element(boundBy: 0).frame.size
        let elementFrameMinY = element.frame.minY

        if elementFrameMinY <= topSafeInsetSize {
            return UITestVisibilityResult(isWithinSafeBounds: false, adjustDirection: .downwards)
        }

        let deltaBottom = applicationFrame.height - elementFrameMinY
        if deltaBottom <= bottomSafeInsetSize {
            return UITestVisibilityResult(isWithinSafeBounds: false, adjustDirection: .upwards)
        }

        return UITestVisibilityResult(isWithinSafeBounds: true, adjustDirection: .none)
    }
}

private enum UITestAdjustDirection {
    case upwards
    case downwards
    case none
}

private struct UITestVisibilityResult {
    let isWithinSafeBounds: Bool
    let adjustDirection: UITestAdjustDirection
}
