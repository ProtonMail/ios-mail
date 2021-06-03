//
//  Waits.swift
//  ProtonMailUITests
//
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import XCTest

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

    open func forElementExistance(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line) -> Bool {
        return waitSoftForCondition(element, Predicate.exists, file, line)
    }

    @discardableResult
    open func forElementToBeEnabled(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        return waitForCondition(element, Predicate.enabled, file, line)
    }

    @discardableResult
    open func forElementToBeHittable(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        return waitForCondition(element, Predicate.hittable, file, line)
    }

    @discardableResult
    open func forElementToDisappear(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        return waitForCondition(element, Predicate.doesNotExist, file, line)
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
