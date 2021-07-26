//
//  XCUIElement.swift
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

private let app = XCUIApplication()

/**
 * XCUIElement extensions that help to simplify the test syntax and keep it more compact.
 */
extension XCUIElement {

    /**
     * Deletes text value from the text field.
     */
    @discardableResult
    func clearText() -> XCUIElement {
        guard let stringValue = self.value as? String else {
            XCTFail("clearText() text method was applied to an element that is not a textField.")
            return self
        }
        let delete: String = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(delete)
        return self
    }

    /**
     * Returns child element that matches given locator: identifier, predicate or index.
     */
    func child(_ childElement: UiElement) -> XCUIElement {
        /// At least one of the following: identifier, predicate or index must not be nil because otherwise test will fail in UiElement() line 354.
        if childElement.getIdentifier() != nil {
            return Wait().forElement(self.children(matching: childElement.getType()).element(matching: childElement.getType(), identifier: childElement.getIdentifier()))
        } else if childElement.getPredicate() != nil {
            return Wait().forElement(self.children(matching: childElement.getType()).element(matching: childElement.getPredicate()!))
        } else {
            return Wait().forElement(self.children(matching: childElement.getType()).element(boundBy: childElement.getIndex()!))
        }
    }

    /**
     * Returns child element that matches given locator
     */
    func descendant(_ descendantElement: UiElement) -> XCUIElement {
        /// At least one of the following: identifier, predicate or index must not be nil because otherwise test will fail in UiElement() line 354.
        if descendantElement.getIdentifier() != nil {
            return Wait().forElement(self.descendants(matching: descendantElement.getType()).element(matching: descendantElement.getType(), identifier: descendantElement.getIdentifier()))
        } else if descendantElement.getPredicate() != nil {
            return Wait().forElement(self.descendants(matching: descendantElement.getType()).element(matching: descendantElement.getPredicate()!))
        } else {
            return Wait().forElement(self.descendants(matching: descendantElement.getType()).element(boundBy: descendantElement.getIndex()!))
        }
    }
}
