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
            let element = app.buttons[identifier].firstMatch
            XCTAssertTrue(element.exists, "Button element \(element.debugDescription) does not exist.", file: file, line: line)
        }
        
        static func textFieldWithIdentifierExists(_ identifier: String, file: StaticString = #file, line: UInt = #line) {
            let element = app.textFields[identifier].firstMatch
            XCTAssertTrue(element.exists, "TextField element \(element.debugDescription) does not exist.", file: file, line: line)
        }
        
        static func staticTextWithIdentifierExists(_ identifier: String, file: StaticString = #file, line: UInt = #line) {
            let element = app.staticTexts[identifier].firstMatch
            XCTAssertTrue(element.exists, "StaticText element \(element.debugDescription) does not exist.", file: file, line: line)
        }
        
        static func staticTextWithIdentifierDoesNotExists(_ identifier: String, file: StaticString = #file, line: UInt = #line) {
            let element = app.staticTexts[identifier].firstMatch
            XCTAssertFalse(element.exists, "StaticText element \(element.debugDescription) exists.", file: file, line: line)
        }
        
        static func cellWithIdentifierExists(_ identifier: String, file: StaticString = #file, line: UInt = #line) {
            let element = app.cells[identifier].firstMatch
            XCTAssertTrue(element.exists, "Cell element \(element.debugDescription) does not exist but it should.", file: file, line: line)
        }
        
        static func cellWithIdentifierDoesNotExists(_ identifier: String, file: StaticString = #file, line: UInt = #line) {
            let element = app.cells[identifier].firstMatch
            XCTAssertFalse(element.exists, "Cell element \(element.debugDescription) exists but it should not.", file: file, line: line)
        }
        
        static func switchByIndexHasValue(_ index: Int, _ value: Int, file: StaticString = #file, line: UInt = #line) {
            let element = app.switches.element(boundBy: index)
            XCTAssertTrue(Int((element.value as? String)!) == value, "Switch element \(element.debugDescription) should be in state \(value), but is \(element.value).", file: file, line: line)
        }
    }
    
    class button {
        @discardableResult
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.buttons[identifier].firstMatch
            element.tap()
            return element
        }
        
        @discardableResult
        class func tapByIndex(_ index: Int) -> XCUIElement {
            let element = app.buttons.element(boundBy: index)
            element.tap()
            return element
        }
    }
    
    class cell {
        class func tapByIdentifier(_ identifier: String) {
            app.cells[identifier].firstMatch.tap()
        }
        
        class func forceTapByIdentifier(_ identifier: String) {
            app.cells[identifier].firstMatch.forceTap()
        }
        
        class func tapByPosition(_ index: Int) {
            let cell = app.cells.element(boundBy: index).firstMatch
            cell.tap()
        }
        
        class func swipeLefyByIdentifier(_ identifier: String) {
            app.cells[identifier].firstMatch.swipeLeft()
        }
        
        class func longClickByPosition(_ index: Int) {
            let cell = app.cells.element(boundBy: index)
            cell.press(forDuration: 3)
        }
        
        class func getNameByIndex(_ index: Int) -> String {
            let cell = app.cells.element(boundBy: index)
            let name = cell.identifier.components(separatedBy: ".")
            let subject: String = name[1]
            return subject
        }
        
        class func getAddressByIndex(_ index: Int) -> String {
            let cell = app.cells.element(boundBy: index).firstMatch
            let name = cell.label.components(separatedBy: ",")
            let address: String = name[1]
            return address
        }
        
        class func swipeSwipeUpUntilVisibleByIdentifier(_ identifier: String) -> XCUIElement {
            return app.cells[identifier].firstMatch.swipeUpUntilVisible()
        }
        
        class func swipeDownUpUntilVisibleByIdentifier(_ identifier: String) -> XCUIElement {
            return app.cells[identifier].firstMatch.swipeUpUntilVisible()
        }
    }
    
    class menuItem {
        @discardableResult
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.menuItems[identifier].firstMatch
            element.tap()
            return element
        }
    }
    
    class other {
        @discardableResult
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.otherElements[identifier].firstMatch
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
            let element = app.otherElements[identifier].firstMatch
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
            let element = app.secureTextFields[identifier].firstMatch
            element.tap()
            return element
        }
        
        class func typeTextByIdentifier(_ identifier: String, _ text: String) {
            app.textFields[identifier].firstMatch.typeText(text)
        }
        
        class func tapByIndex(_ index: Int) -> XCUIElement {
            let element = app.secureTextFields.element(boundBy: index)
            element.tap()
            return element
        }
    }
    
    class staticText {
        @discardableResult
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.staticTexts[identifier].firstMatch
            element.tap()
            return element
        }
        
        class func tapByIndex(_ index: Int) -> XCUIElement {
            let element = app.staticTexts.element(boundBy: index)
            element.tap()
            return element
        }
        
        @discardableResult
        class func swipeLeftByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.staticTexts[identifier].firstMatch
            element.swipeLeft()
            return element
        }
        
        @discardableResult
        class func swipeRightByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.staticTexts[identifier].firstMatch
            element.swipeRight()
            return element
        }
        
        @discardableResult
        class func longClickByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.staticTexts[identifier].firstMatch
            element.press(forDuration: 3)
            return element
        }
        
        @discardableResult
        class func longClickByIndex(_ index: Int) -> XCUIElement {
            let element = app.staticTexts.element(boundBy: index)
            element.press(forDuration: 5)
            return element
        }
    }
    
    /// As "switch" is reserved swift word use "swittch" instead.
    class swittch {
        class func isEnabledByIndex(_ index: Int) -> Bool {
            let switchValue = app.switches.element(boundBy: index).value as? String
            return 1 == Int(switchValue!)
        }
        
        class func isEnabledByIdentifier(_ identifier: String) -> Bool {
            let switchValue = app.switches[identifier].firstMatch.value as? String
            return 1 == Int(switchValue!)
        }
        
        @discardableResult
        class func tapByIndex(_ index: Int) -> XCUIElement {
            let element = app.switches.element(boundBy: index)
            element.tap()
            return element
        }
        
        @discardableResult
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.switches[identifier].firstMatch
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
            self.perform = app.textFields[identifier].firstMatch
        }
        
        class func tapByIdentifier(_ identifier: String) -> XCUIElement {
            let element = app.textFields[identifier].firstMatch
            element.tap()
            return element
        }
        
        class func tapByIndex(_ index: Int) -> XCUIElement {
            let element = app.textFields.element(boundBy: index).firstMatch
            element.tap()
            return element
        }
        
        class func typeTextByIdentifier(_ identifier: String, _ text: String) -> XCUIElement {
            let element = app.textFields[identifier].firstMatch
            element.typeText(text)
            return element
        }
    }
    
    class textView {
        
        var perform: XCUIElement
        init(_ identifier: String) {
            self.perform = app.textFields[identifier]
        }

        class func tapByIndex(_ index: Int) -> XCUIElement {
            let element = app.textViews.element(boundBy: index)
            element.tap()
            return element
        }
        
        @discardableResult
        class func typeTextByIdentifier(_ identifier: String, _ text: String) -> XCUIElement {
            let element = app.textViews[identifier].firstMatch
            element.typeText(text)
            return element
        }
    }
    
    class wait {
        
        @discardableResult
        static func forButtonWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.buttons[identifier].firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        @discardableResult
        static func forCellWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.cells[identifier].firstMatch
            XCUIApplication().scrollViews.textFields.element(boundBy: 1)
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        class func forCellByIndex(_ index: Int) -> XCUIElement {
            return app.cells.element(boundBy: index).firstMatch
        }
        
        @discardableResult
        static func forCollectionViewWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.collectionViews[identifier].firstMatch
            XCUIApplication().scrollViews.textFields.element(boundBy: 1)
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        @discardableResult
        static func forHittableButton(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.buttons[identifier].firstMatch
            Wait().forElementToBeHittable(element, file, line)
            return element
        }
        
        @discardableResult
        static func forCellWithIdentifierToDisappear(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.buttons[identifier].firstMatch
            Wait().forElementToDisappear(element, file, line)
            return element
        }
        
        @discardableResult
        static func forOtherFieldWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.otherElements[identifier].firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        @discardableResult
        static func forStaticTextFieldWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.staticTexts[identifier].firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        @discardableResult
        static func forSecureTextFieldWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.secureTextFields[identifier].firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        @discardableResult
        static func forTextFieldWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.textFields[identifier].firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
        
        static func forTableViewWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) {
            let element = app.tables[identifier].firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
        }
        
        @discardableResult
        static func forImageWithIdentifier(_ identifier: String, file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10) -> XCUIElement {
            let element = app.images[identifier].firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element \(element.debugDescription) does not exist.", file: file, line: line)
            return element
        }
    }
}

extension XCUIElement {
    
    @discardableResult
    func swipeUpUntilVisible(maxAttempts: Int = 5) -> XCUIElement {
        var eventCount = 0
        let table = app.tables.element.firstMatch

        while eventCount <= maxAttempts, !self.isVisible {
            table.swipeUp()
            eventCount += 1
        }
        return self
    }
    
    @discardableResult
    func swipeDownUntilVisible(maxAttempts: Int = 5) -> XCUIElement {
        var eventCount = 0
        let table = app.tables.element.firstMatch

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
    
    func assertWithValue(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Element doesn't have text value.")
            return
        }
        XCTAssertTrue(stringValue == text, "Expected Element text value to be: \"\(text)\", but found: \"\(stringValue)\"")
    }
    
    func assertWithLabel(_ text: String) {
        guard let label = self.label as? String else {
            XCTFail("Element doesn't have text label.")
            return
        }
        XCTAssertTrue(label == text, "Expected Element text label to be: \"\(text)\", but found: \"\(label)\"")
    }
    
    func assertHasStaticTextChild(withText: String) {
        XCTAssertTrue(self.staticTexts[withText].exists, "Expected to have StaticText element with label: \"\(withText)\" but found nothing.")
    }
    
    func clickCellByIndex(_ index: Int) {
        self.cells.element(boundBy: index)
    }
    
    func forceTap() {
        coordinate(withNormalizedOffset: .zero).tap()
    }
}
