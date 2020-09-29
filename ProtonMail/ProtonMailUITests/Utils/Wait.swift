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


import XCTest

struct Wait {
    
    private let defaultTimeout = 10.00
    
    struct Condition {
        static let enabled = "isEnabled == true"
        static let hittable = "hittable == true"
        static let doesNotExist = "exists == false"
        static let exist = "exists == true"
    }
    
    @discardableResult
    func forElement(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line, _ timeout: TimeInterval) -> Bool {
        return waitSoftForCondition(element, Condition.exist, file, line, timeout)
    }
    
    @discardableResult
    func forElementToBeEnabled(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        return waitForCondition(element, Condition.enabled, file, line)
    }
    
    @discardableResult
    func forElementToBeHittable(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        return waitForCondition(element, Condition.hittable, file, line)
    }
    
    @discardableResult
    func forElementToDisappear(_ element: XCUIElement, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        return waitForCondition(element, Condition.doesNotExist, file, line)
    }
    
    private func waitForCondition(_ element: XCUIElement, _ expression: String, _ file: StaticString = #file, _ line: UInt = #line) -> XCUIElement {
        let condition = NSPredicate(format: expression)
        let expectation = XCTNSPredicateExpectation(predicate: condition, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: defaultTimeout)
        if result != .completed {
            let message = "Condition: \(expression) was not met for Element: \(element) after \(defaultTimeout) seconds timeout."
            XCTFail(message, file: file, line: line)
        }
        return element
    }
    
    private func waitSoftForCondition(_ element: XCUIElement, _ expression: String, _ file: StaticString = #file, _ line: UInt = #line, _ timeout: TimeInterval = 5) -> Bool {
        let condition = NSPredicate(format: expression)
        let expectation = XCTNSPredicateExpectation(predicate: condition, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        if result == .completed {
            return true
        } else {
            return false
        }
    }
}
