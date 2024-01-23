//
//  UIElement+Actions.swift
//
//  ProtonMail - Created on 02.02.21.
//
//  The MIT License
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import XCTest

extension UIElement {

    /**
     Clears the text from the targeted UI element.
     Calls `clearText()` on the located UI element and returns the current instance of `UIElement`.
     */
    public func clearText() -> UIElement {
        return performAction { $0.clearText() }
    }

    /**
     Performs a double-tap gesture on the located UI element.
     Returns the current instance of `UIElement` for chaining further actions.
     */
    @discardableResult
    public func doubleTap() -> UIElement {
        return performAction { $0.doubleTap() }
    }

    /**
     Taps the located UI element multiple times based on the count provided.
     Accepts an integer `count` representing the number of taps to perform.
     Returns the current instance of `UIElement` for continued action chaining.
     */
    @discardableResult
    public func multiTap(_ count: Int) -> UIElement {
        return performAction { element in
            for _ in 0..<count {
                element.tap()
            }
        }
    }

    /**
     Performs a tap gesture at the center of the located UI element.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func forceTap() -> UIElement {
        tapOnCoordinate(withOffset: .zero)
    }

    /**
     Taps at a specific coordinate offset within the located UI element.
     Accepts a `CGVector` representing the offset for the tap location.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func tapOnCoordinate(withOffset offset: CGVector) -> UIElement {
        return performAction { $0.coordinate(withNormalizedOffset: offset).tap() }
    }

    /**
     Performs a long-press gesture on the located UI element.
     Accepts an optional `TimeInterval` parameter specifying the duration of the press.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func longPress(_ timeInterval: TimeInterval = 2) -> UIElement {
        return performAction { $0.press(forDuration: timeInterval) }
    }

    /**
     Performs a force press (deep press) at the center of the located UI element.
     Accepts an optional `TimeInterval` parameter specifying the duration of the press.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func forcePress(_ timeInterval: TimeInterval = 2) -> UIElement {
        return performAction { $0.coordinate(withNormalizedOffset: .zero).press(forDuration: timeInterval) }
    }

    /**
     Performs a swipe down gesture on the located UI element.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func swipeDown() -> UIElement {
        return performAction { $0.swipeDown() }
    }

    /**
     Performs a swipe left gesture on the located UI element.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func swipeLeft() -> UIElement {
        return performAction { $0.swipeLeft() }
    }

    /**
     Performs a swipe right gesture on the located UI element.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func swipeRight() -> UIElement {
        uiElement()!.swipeRight()
        return self
    }

    /**
     Performs a swipe up gesture on the located UI element.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func swipeUp() -> UIElement {
        return performAction { $0.swipeUp() }
    }

    /**
     Taps and then swipes left on the located UI element.
     Accepts a `TimeInterval` for the duration of the initial tap and a `XCUIGestureVelocity` for the swipe speed.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func tapThenSwipeLeft( _ forDuration: TimeInterval, _ speed: XCUIGestureVelocity) -> UIElement {
        return performAction {
            let start = $0.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            let finish = $0.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
            start.press(forDuration: forDuration, thenDragTo: finish, withVelocity: speed, thenHoldForDuration: 0.1)
        }
    }

    /**
     Taps and then swipes right on the located UI element.
     Similar to `tapThenSwipeLeft`, but swipes in the opposite direction.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func tapThenSwipeRight( _ forDuration: TimeInterval, _ speed: XCUIGestureVelocity) -> UIElement {
        return performAction {
            let start = $0.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
            let finish = $0.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            start.press(forDuration: forDuration, thenDragTo: finish, withVelocity: speed, thenHoldForDuration: 0.1)
        }
    }

    /**
     Taps and then swipes down on the located UI element.
     Parameters and behavior similar to `tapThenSwipeLeft`, but swipes downwards.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func tapThenSwipeDown( _ forDuration: TimeInterval, _ speed: XCUIGestureVelocity) -> UIElement {
        return performAction {
            let start = $0.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            let finish = $0.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
            start.press(forDuration: forDuration, thenDragTo: finish, withVelocity: speed, thenHoldForDuration: 0.1)
        }
    }

    /**
     Taps and then swipes up on the located UI element.
     Parameters and behavior similar to `tapThenSwipeLeft`, but swipes upwards.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func tapThenSwipeUp( _ forDuration: TimeInterval, _ speed: XCUIGestureVelocity) -> UIElement {
        return performAction {
            let start =  $0.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
            let finish = $0.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            start.press(forDuration: forDuration, thenDragTo: finish, withVelocity: speed, thenHoldForDuration: 0.1)
        }
    }

    /**
     Performs a single tap gesture on the located UI element.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func tap() -> UIElement {
        return performAction { $0.tap() }
    }

    /**
     Taps the located UI element if it exists.
     Checks for the element's existence before performing the tap action.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func tapIfExists() -> UIElement {
        return performAction { element in
            if Wait().forElement(element).exists {
                element.tap()
            }
        }
    }

    /**
     Attempts to focus the keyboard on the located UI element, retrying up to a specified number of times.
     Accepts an integer `retries` representing the maximum number of attempts.
     Fails the test if unable to set focus after the specified retries.
     Returns the current instance of `UIElement`.
     */
    @discardableResult
    public func forceKeyboardFocus(_ retries: Int = 5) -> UIElement {
        guard let element = uiElement() else { return self }
        element.tap()
        for _ in 0..<retries where !Wait().hasKeyboardFocus(element) {
            element.tap()
        }
        if !Wait().hasKeyboardFocus(element) {
            XCTFail("Unable to set the keyboard focus to element: \(String(describing: element.debugDescription))")
        }
        return self
    }

    /**
     Swipes up on a designated swipe area until the located UI element is visible.
     Accepts an integer `maxAttempts` specifying the maximum number of swipe attempts.
     Returns the current instance
     */
    @discardableResult
    public func swipeUpUntilVisible(maxAttempts: Int = 5) -> UIElement {
        let swipeArea = focusedTable ?? currentApp!
        for _ in 0..<maxAttempts where !isVisible {
            swipeArea.swipeUp()
        }
        return self
    }

    /**
     Swipes down on a designated swipe area until the located UI element is visible.
     Accepts an integer `maxAttempts` specifying the maximum number of swipe attempts.
     Returns the current instance
     */
    @discardableResult
    public func swipeDownUntilVisible(maxAttempts: Int = 5) -> UIElement {
        let swipeArea = focusedTable ?? currentApp!
        for _ in 0..<maxAttempts where !isVisible {
            swipeArea.swipeDown()
        }
        return self
    }

    /**
     A computed property that determines whether the located UI element is visible in the current UI context.
     Checks if the element exists and its frame is not empty.
     Then, it verifies if the element's frame is within the bounds of the current application's main window.
     Returns `true` if the element is visible; otherwise, returns `false`.
     */
    private var isVisible: Bool {
        guard uiElement()!.exists && !uiElement()!.frame.isEmpty else { return false }
        return currentApp!.windows.element(boundBy: 0).frame.contains(uiElement()!.frame)
    }

    @discardableResult
    private func performAction(_ action: (XCUIElement) -> Void) -> UIElement {
        if let element = uiElement() {
            action(element)
        }
        return self
    }

}
