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
            let element = app.staticTexts[identifier]
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
        
        class func swipeSwipeUpUntilVisibleByIdentifier(_ identifier: String) -> XCUIElement {
            return app.cells[identifier].swipeUpUntilVisible()
        }
        
        class func swipeDownUpUntilVisibleByIdentifier(_ identifier: String) -> XCUIElement {
            return app.cells[identifier].swipeUpUntilVisible()
        }
    }
    
    class menuItem {
        @discardableResult
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.menuItems[identifier]
            element.tap()
            return element
        }
    }
    
    class other {
        @discardableResult
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.otherElements[identifier]
            element.tap()
            return element
        }
        
        @discardableResult
        class func tapByIdentifier(_ identifier: String, _ index: Int) -> XCUIElement {
            let element = app.otherElements.matching(identifier: identifier).element(boundBy: index)
            element.tap()
            return element
        }
        
        class func tapIfExists(_ identifier: String) {
            let element = app.otherElements[identifier]
            if (Wait().forElement(element, #file, #line, 2)) {
                element.tap()
            }
        }
    }
    
    class pickerWheel {
        class func setPickerWheelValue(pickerWheelIndex: Int, value: Int, dimension: String) {
            app.pickerWheels.element(boundBy: pickerWheelIndex).adjust(toPickerWheelValue: "\(value) \(dimension)")
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
    
    class system {
        class func saveToClipBoard(_ text: String) {
            UIPasteboard.general.string = text
        }
    }
    
    class tableView {
        class func swipeDownByIdentifier(_ identifier: String) {
            let topEdge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
            let toCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            topEdge.press(forDuration: 0, thenDragTo: toCoordinate)
        }
    }
    
    class textField {
        
        var perform: XCUIElement
        init(_ identifier: String) {
            self.perform = app.textFields[identifier]
        }
        
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
        
        class func typeTextByIdentifier(_ identifier: String, _ text: String) -> XCUIElement {
            let element = app.textFields[identifier]
            element.typeText(text)
            return element
        }
    }
    
    class wait {
        
        @discardableResult
        static func forButtonWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.buttons[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        @discardableResult
        static func forCellWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.cells[identifier]
            XCUIApplication().scrollViews.textFields.element(boundBy: 1)
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
        
        @discardableResult
        static func forImageWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.images[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
    }
}

extension XCUIElement {
    
    @discardableResult
    func swipeUpUntilVisible(maxAttempts: Int = 5) -> XCUIElement {
        var eventCount = 0
        let table = app.tables.element

        while eventCount <= maxAttempts, !self.isVisible {
            table.swipeUp()
            eventCount += 1
        }
        return self
    }
    
    @discardableResult
    func swipeDownUntilVisible(maxAttempts: Int = 5) -> XCUIElement {
        var eventCount = 0
        let table = app.tables.element

        while eventCount <= maxAttempts, !self.isVisible {
            table.swipeDown()
            eventCount += 1
        }
        return self
    }
    
    private var isVisible: Bool {
        guard self.exists && !self.frame.isEmpty else { return false }
        return app.windows.element(boundBy: 0).frame.contains(self.frame)
    }
}

extension XCUIElement {
    /**
     Deletes text value from text field.
     */
    func clear() -> XCUIElement {
        guard let stringValue = self.value as? String else {
            XCTFail("clear() text method was used on a field that is not textField.")
            return self
        }
        let delete: String = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(delete)
        return self
    }
    
    func type(_ text: String) -> XCUIElement {
        self.typeText(text)
        return self
    }
    
    func click() -> XCUIElement {
        self.tap()
        return self
    }
}
