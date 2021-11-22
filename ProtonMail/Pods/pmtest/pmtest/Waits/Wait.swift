//
//  Wait.swift
//
//  ProtonMail - Created on 12.10.20.
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

/**
 * Contains wait functions and wait conditions taht are used to wait for the elements.
 */
open class Wait {

    private let defaultTimeout: TimeInterval

    public init(time: TimeInterval = 10.00) {
        defaultTimeout = time
    }

    @discardableResult
    open func forElement(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        waitSoftForCondition(element, Predicate.exists, file, line)
        return element
    }

    @discardableResult
    open func forElementToBeEnabled(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        return waitForCondition(element, Predicate.enabled, file, line)
    }

    @discardableResult
    open func forElementToBeDisabled(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        return waitForCondition(element, Predicate.disabled, file, line)
    }

    @discardableResult
    open func forElementToBeHittable(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        return waitForCondition(element, Predicate.hittable, file, line)
    }

    @discardableResult
    open func forElementToDisappear(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        return waitForCondition(element, Predicate.doesNotExist, file, line)
    }
    
    @discardableResult
    open func forElementHasKeyboardFocus(_ element: XCUIElement, _ timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: Predicate.hasKeyboardFocus, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return (result == .completed)
    }

    /**
     Waits for the condition and fails the test when condition is not met.
     */
    private func waitForCondition(_ element: XCUIElement, _ predicate: NSPredicate, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: defaultTimeout)
        if result != .completed {
            let message = "Condition: \(predicate.predicateFormat) was not met for Element: \(element) after \(defaultTimeout) seconds timeout."
            XCTFail(message, file: file, line: line)
        }
        return element
    }

    /**
     Waits for the condition but don't fail the test.
     */
    @discardableResult
    private func waitSoftForCondition(_ element: XCUIElement, _ predicate: NSPredicate, _ file: StaticString = #file, _ line: UInt = #line) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: defaultTimeout)
        if result == .completed {
            return true
        } else {
            return false
        }
    }
}
