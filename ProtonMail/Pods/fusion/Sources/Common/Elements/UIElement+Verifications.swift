//
//  UIElement+Verifications.swift
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

    @discardableResult
    public func checkExists(file: StaticString = #filePath, line: UInt = #line) -> UIElement {
        XCTAssertTrue(
            uiElement()!.exists,
            "Expected element \(uiElement().debugDescription) to exist but it doesn't.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func checkIsHittable(file: StaticString = #filePath, line: UInt = #line) -> UIElement {
        XCTAssertTrue(
            uiElement()!.isHittable,
            "Expected element \(uiElement().debugDescription) to be hittable but it is not.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func checkDoesNotExist(file: StaticString = #filePath, line: UInt = #line) -> UIElement {
        shouldWaitForExistance = false
        XCTAssertFalse(
            uiElement()!.exists,
            "Expected element \(uiElement().debugDescription) to not exist but it exists.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func checkDisabled(file: StaticString = #filePath, line: UInt = #line) -> UIElement {
        XCTAssertFalse(
            uiElement()!.isEnabled,
            "Expected element \(uiElement().debugDescription) to be in disabled state but it is enabled.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func checkEnabled(file: StaticString = #filePath, line: UInt = #line) -> UIElement {
        XCTAssertTrue(
            uiElement()!.isEnabled,
            "Expected element \(uiElement().debugDescription) to be in enabled state but it is disabled.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func checkHasChild(_ element: UIElement, file: StaticString = #filePath, line: UInt = #line) -> UIElement {
        let parent = uiElement()!
        let locatedElement = parent.child(element)
        XCTAssertTrue(
            locatedElement.exists,
            "Expected to find a child element: \"\(element.uiElement().debugDescription)\" but found nothing.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func checkHasDescendant(_ element: UIElement, file: StaticString = #filePath, line: UInt = #line) -> UIElement {
        let ancestor = uiElement()!
        let locatedElement = ancestor.descendant(element)
        XCTAssertTrue(
            locatedElement.exists,
            "Expected to find descendant element: \"\(element.uiElement().debugDescription)\" but found nothing.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func checkHasLabel(_ label: String, file: StaticString = #filePath, line: UInt = #line) -> UIElement {
        let labelValue = uiElement()!.label
        XCTAssertTrue(
            labelValue == label,
            "Expected Element text label to be: \"\(label)\", but found: \"\(labelValue)\"",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func checkContainsLabel(_ label: String, file: StaticString = #filePath, line: UInt = #line) -> UIElement {
        let labelValue = uiElement()!.label
        XCTAssertTrue(
            labelValue.contains(label),
            "Expected Element text label to contain: \"\(label)\", but found: \"\(labelValue)\"",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func checkHasValue(_ value: String, file: StaticString = #filePath, line: UInt = #line) -> UIElement {
        guard let stringValue = uiElement()!.value as? String else {
            XCTFail("Element doesn't have text value.")
            return self
        }
        XCTAssertTrue(
            stringValue == value,
            "Expected Element text value to be: \"\(value)\", but found: \"\(stringValue)\"",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func checkHasTitle(_ title: String, file: StaticString = #filePath, line: UInt = #line) -> UIElement {
        let stringValue = uiElement()!.title
        XCTAssertTrue(
            stringValue == title, "Expected Element title to be: \"\(title)\", but found: \"\(stringValue)\"",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func checkSelected(file: StaticString = #filePath, line: UInt = #line) -> UIElement {
        XCTAssertTrue(
            uiElement()!.isSelected == true,
            "Expected Element to be selected, but it is not",
            file: file,
            line: line
        )
        return self
    }

    @available(*, deprecated, renamed: "waitUntilExists", message: "`wait` has been renamed to `waitUntilExists`.")
    @discardableResult
    public func wait(
        time: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UIElement {
        waitUntilExists(time: time, file: file, line: line)
    }

    @discardableResult
    public func waitUntilExists(
        time: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UIElement {
        shouldWaitForExistance = false
        Wait(time: time).forElement(uiElement()!, file, line)
        return self
    }

    @discardableResult
    public func waitForDisabled(
        time: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UIElement {
        Wait(time: time).forElementToBeDisabled(uiElement()!, file, line)
        return self
    }

    @discardableResult
    public func waitForHittable(
        time: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UIElement {
        Wait(time: time).forElementToBeHittable(uiElement()!, file, line)
        return self
    }

    @discardableResult
    public func waitForNotHittable(
        time: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UIElement {
        Wait(time: time).forElementToBeNotHittable(uiElement()!, file, line)
        return self
    }

    @discardableResult
    public func waitForEnabled(
        time: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UIElement {
        Wait(time: time).forElementToBeEnabled(uiElement()!, file, line)
        return self
    }

    @discardableResult
    public func waitForFocused(
        time: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UIElement {
        Wait(time: time).forHavingKeyboardFocus(uiElement()!, file, line)
        return self
    }

    @discardableResult
    public func waitUntilGone(
        time: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UIElement {
        shouldWaitForExistance = false
        Wait(time: time).forElementToDisappear(uiElement()!, file, line)
        return self
    }
}
