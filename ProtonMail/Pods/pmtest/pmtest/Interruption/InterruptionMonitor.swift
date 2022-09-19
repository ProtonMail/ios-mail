//
//  InterruptionHandler.swift
//
//  ProtonMail - Created on 03.06.21.
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

import XCTest

extension XCTestCase {
    /**
     * Registers UI interruption monitor for a single XCUIElement and taps on it if triggered.
     *
     * Sample usage:
     *  let dontAllowButton = XCUIApplication().buttons["Don’t Allow"].firstMatch
     *  addUIMonitor(elementToTap: dontAllowButton)
     *
     * To unregister use: removeUIInterruptionMonitor(monitor).
     */
    @discardableResult
    open func addUIMonitor(elementToTap: XCUIElement) -> NSObjectProtocol {
        return addUIInterruptionMonitor(withDescription: "Handle UI interruprion") { _ -> Bool in
            if elementToTap.exists {
                elementToTap.tap()
            }
            return true
        }
    }

    /**
     * Registers UI interruption monitor for a multiple XCUIElements and taps on them if triggered.
     *
     * Sample usage:
     *  let buttons = XCUIApplication().buttons
     *  let identifiers = ["Don’t Allow", "OK"]
     *  addUIMonitor(elementsQuery: buttons, identifiers: identifiers)
     *
     * To unregister use: removeUIInterruptionMonitor(monitor)
     */
    @discardableResult
    open func addUIMonitor(elementQueryToTap: XCUIElementQuery, identifiers: [String]) -> NSObjectProtocol {
        return addUIInterruptionMonitor(withDescription: "Handle UI interruprions") { _ -> Bool in
            for (identifier) in identifiers {
                let element = elementQueryToTap[identifier].firstMatch
                if element.exists {
                    element.tap()
                    break
                }
            }
            return true
        }
    }
}
