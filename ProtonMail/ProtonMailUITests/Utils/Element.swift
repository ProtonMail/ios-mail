//
//  UI.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 23.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

let app = XCUIApplication()

/**
 
 */
struct Element {
    
    class assert {
        static func buttonWithIdentifierExists(_ identifier: String, file: StaticString = #file, line: UInt = #line) {
            let element = app.buttons[identifier]
            XCTAssertTrue(element.exists, "Button element \(element.debugDescription) does not exist.", file: file, line: line)
        }
        
        static func textFieldWithIdentifierExists(_ identifier: String, file: StaticString = #file, line: UInt = #line) {
            let element = app.textFields[identifier]
            XCTAssertTrue(element.exists, "TextField element \(element.debugDescription) does not exist.", file: file, line: line)
        }
        
        static func staticTextWithIdentifierExists(_ identifier: String, file: StaticString = #file, line: UInt = #line) {
            let element = app.textFields[identifier]
            XCTAssertTrue(element.exists, "StaticText element \(element.debugDescription) does not exist.", file: file, line: line)
        }
    }
    
    class button {
        @discardableResult
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.buttons[identifier]
            element.tap()
            return element
        }
    }
    
    class cell {
        class func tapByIdentifier(_ identifier: String) {
            app.cells[identifier].tap()
        }
        
        class func swipeLeftByIdentifier(_ identifier: String) {
            app.cells[identifier].swipeLeft()
        }
    }
    
    class other {
        @discardableResult
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.otherElements[identifier]
            element.tap()
            return element
        }
    }
    
    class secureTextField {
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.secureTextFields[identifier]
            element.tap()
            return element
        }
        
        class func typeTextByIdentifier(_ text: String) {
            app.textFields[text].tap()
        }
    }
    
    class staticText {
        @discardableResult
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.staticTexts[identifier]
            element.tap()
            return element
        }
        
        class func tapByIndex(_ index: Int) -> XCUIElement {
            let element = app.staticTexts.element(boundBy: index)
            element.tap()
            return element
        }
    }
    
    class textField {
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.textFields[identifier]
            element.tap()
            return element
        }
        
        class func tapByIndex(_ index: Int) -> XCUIElement {
            let element = app.textFields.element(boundBy: index)
            element.tap()
            return element
        }
    }
    
    class wait {
        @discardableResult
        static func forCellWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.cells[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        @discardableResult
        static func forButtonWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.buttons[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        @discardableResult
        static func forHittableButton(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.buttons[identifier]
            Wait().forElementToBeHittable(element, file, line)
            return element
        }
        
        @discardableResult
        static func forCellWithIdentifierToDisappear(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.buttons[identifier]
            Wait().forElementToDisappear(element, file, line)
            return element
        }
        
        @discardableResult
        static func forOtherFieldWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.otherElements[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        @discardableResult
        static func forStaticTextFieldWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.staticTexts[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        @discardableResult
        static func forSecureTextFieldWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.secureTextFields[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        @discardableResult
        static func forTextFieldWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.textFields[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        static func forTableViewWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) {
            let element = app.tables[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
        }
    }
}
