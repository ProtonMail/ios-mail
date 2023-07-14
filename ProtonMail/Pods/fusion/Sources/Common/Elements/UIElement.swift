//
//  UIElement.swift
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

/**
 * Represents single XCUIElement and provides an interface for performing actions or checks.
 * By default each XCUIElement that is referenced by this class already has a wait functionality in place except check functions or checkDoesNotExist() function.
 * Check functions assume that element was already located before check is called. checkDoesNotExist() function shouldn't wait for the element.
 */

@available(*, deprecated, message: "`UiElement` has been renamed to `UIElement`.")
typealias UiElement = UIElement

// swiftlint:disable type_body_length
open class UIElement {

    init(_ query: XCUIElementQuery, _ elementType: XCUIElement.ElementType) {
        self.uiElementQuery = query
        self.elementType = elementType
    }

    init(_ identifier: String, _ query: XCUIElementQuery, _ elementType: XCUIElement.ElementType) {
        self.uiElementQuery = query
        self.identifier = identifier
        self.elementType = elementType
    }

    init(_ predicate: NSPredicate, _ query: XCUIElementQuery, _ elementType: XCUIElement.ElementType) {
        self.uiElementQuery = query
        self.predicate = predicate
        self.elementType = elementType
    }

    private var elementType: XCUIElement.ElementType
    internal var uiElementQuery: XCUIElementQuery?
    internal var ancestorElement: XCUIElement?
    internal var parentElement: XCUIElement?
    private var locatedElement: XCUIElement?
    private var index: Int?
    private var identifier: String?
    private var childElement: UIElement?
    private var descendantElement: UIElement?
    private var elementEnabled: Bool?
    private var elementDisabled: Bool?
    private var elementHittable: Bool?
    private var predicate: NSPredicate?
    private var matchedPredicate: NSPredicate?
    private var labelPredicate: NSPredicate?
    private var titlePredicate: NSPredicate?
    private var valuePredicate: NSPredicate?
    private var focusedTable: XCUIElement?
    private var containsType: XCUIElement.ElementType?
    private var containsIdentifier: String?
    private var containsPredicate: NSPredicate?
    private var containLabel: String?
    private var shouldUseFirstMatch: Bool = false
    private var shouldWaitForExistance = true

    internal func getType() -> XCUIElement.ElementType {
        return elementType
    }

    internal func setType(_ elementQuery: XCUIElementQuery) -> UIElement {
        uiElementQuery = elementQuery
        return self
    }

    internal func getPredicate() -> NSPredicate? {
        return self.predicate
    }

    internal func getIdentifier() -> String? {
        return self.identifier
    }

    internal func getIndex() -> Int? {
        return self.index
    }

    /// Element properties
    public func label() -> String? {
        guard let element = uiElement() else {
            return nil
        }
        return element.label
    }

    public func placeholderValue() -> String? {
        guard let element = uiElement() else {
            return nil
        }
        return element.placeholderValue
    }

    public func title() -> String? {
        guard let element = uiElement() else {
            return nil
        }
        return element.title
    }

    public func value() -> Any? {
        guard let element = uiElement() else {
            return nil
        }
        return element.value
    }

    public func exists() -> Bool {
        guard let element = uiElement() else {
            return false
        }
        return element.exists
    }

    public func enabled() -> Bool {
        guard let element = uiElement() else {
            return false
        }
        return element.isEnabled
    }

    public func hittable() -> Bool {
        guard let element = uiElement() else {
            return false
        }
        return element.isHittable
    }

    public func selected() -> Bool {
        guard let element = uiElement() else {
            return false
        }
        return element.isSelected
    }

    public func childrenCount() -> Int {
        return uiElement()!.children(matching: XCUIElement.ElementType.any).count
    }

    public func childrenCountByType(_ type: XCUIElement.ElementType) -> Int {
        return uiElement()!.children(matching: type).count
    }

    /// Matchers
    public func byIndex(_ index: Int) -> UIElement {
        self.index = index
        return self
    }

    public func hasDescendant(_ element: UIElement) -> UIElement {
        self.containsType = element.getType()
        self.containsIdentifier = element.getIdentifier()
        self.containsPredicate = element.getPredicate()
        return self
    }

    public func containsLabel(_ label: String) -> UIElement {
        self.containLabel = label
        return self
    }

    public func isEnabled() -> UIElement {
        self.elementEnabled = true
        return self
    }

    public func isDisabled() -> UIElement {
        self.elementDisabled = true
        return self
    }

    public func isHittable() -> UIElement {
        self.elementHittable = true
        return self
    }

    public func firstMatch() -> UIElement {
        self.shouldUseFirstMatch = true
        return self
    }

    /**
     * Use it to specify in which table element test should swipe up or down in case of multiple tables in the layout hierarchy:
     * Example: cell(identifier).inTable(table(identifier)).swipeUpUntilVisible()
     */
    public func inTable(_ table: UIElement) -> UIElement {
        focusedTable = table.uiElement()
        return self
    }

    public func matchesPredicate(_ matchedPredicate: NSPredicate) -> UIElement {
        self.matchedPredicate = matchedPredicate
        return self
    }

    public func hasLabel(_ label: String) -> UIElement {
        return hasLabel(Predicate.labelEquals(label))
    }

    public func hasLabel(_ labelPredicate: NSPredicate) -> UIElement {
        self.labelPredicate = labelPredicate
        return self
    }

    public func hasTitle(_ title: String) -> UIElement {
        return hasTitle(Predicate.titleEquals(title))
    }

    public func hasTitle(_ titlePredicate: NSPredicate) -> UIElement {
        self.titlePredicate = titlePredicate
        return self
    }

    public func hasValue(_ value: String) -> UIElement {
        return hasValue(Predicate.valueEquals(value))
    }

    public func hasValue(_ valuePredicate: NSPredicate) -> UIElement {
        self.valuePredicate = valuePredicate
        return self
    }

    /// Actions
    public func clearText() -> UIElement {
        uiElement()!.clearText()
        return self
    }

    @discardableResult
    public func doubleTap() -> UIElement {
        uiElement()!.doubleTap()
        return self
    }

    @discardableResult
    public func multiTap(_ count: Int) -> UIElement {
        let element = uiElement()!
        for _ in 0...count {
            element.tap()
        }
        return self
    }

    @discardableResult
    public func forceTap() -> UIElement {
        tapOnCoordinate(withOffset: .zero)
    }

    @discardableResult
    public func tapOnCoordinate(withOffset offset: CGVector) -> UIElement {
        let element = uiElement()!
        element.coordinate(withNormalizedOffset: offset).tap()
        return self
    }

    @discardableResult
    public func longPress(_ timeInterval: TimeInterval = 2) -> UIElement {
        uiElement()!.press(forDuration: timeInterval)
        return self
    }

    @discardableResult
    public func forcePress(_ timeInterval: TimeInterval = 2) -> UIElement {
        uiElement()!.coordinate(withNormalizedOffset: .zero).press(forDuration: timeInterval)
        return self
    }

    @discardableResult
    public func swipeDown() -> UIElement {
        uiElement()!.swipeDown()
        return self
    }

    @discardableResult
    public func swipeLeft() -> UIElement {
        uiElement()!.swipeLeft()
        return self
    }

    @discardableResult
    public func swipeRight() -> UIElement {
        uiElement()!.swipeRight()
        return self
    }

    @discardableResult
    public func swipeUp() -> UIElement {
        uiElement()!.swipeUp()
        return self
    }

    @discardableResult
    public func tapThenSwipeLeft( _ forDuration: TimeInterval, _ speed: XCUIGestureVelocity) -> UIElement {
        let start = uiElement()!.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let finish = uiElement()!.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        start.press(forDuration: forDuration, thenDragTo: finish, withVelocity: speed, thenHoldForDuration: 0.1)
        return self
    }

    @discardableResult
    public func tapThenSwipeRight( _ forDuration: TimeInterval, _ speed: XCUIGestureVelocity) -> UIElement {
        let start = uiElement()!.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        let finish = uiElement()!.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        start.press(forDuration: forDuration, thenDragTo: finish, withVelocity: speed, thenHoldForDuration: 0.1)
        return self
    }

    @discardableResult
    public func tapThenSwipeDown( _ forDuration: TimeInterval, _ speed: XCUIGestureVelocity) -> UIElement {
        let start = uiElement()!.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let finish = uiElement()!.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        start.press(forDuration: forDuration, thenDragTo: finish, withVelocity: speed, thenHoldForDuration: 0.1)
        return self
    }

    @discardableResult
    public func tapThenSwipeUp( _ forDuration: TimeInterval, _ speed: XCUIGestureVelocity) -> UIElement {
        let start = uiElement()!.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        let finish = uiElement()!.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        start.press(forDuration: forDuration, thenDragTo: finish, withVelocity: speed, thenHoldForDuration: 0.1)
        return self
    }

    @discardableResult
    public func tap() -> UIElement {
        uiElement()!.tap()
        return self
    }

    @discardableResult
    public func tapIfExists() -> UIElement {
        let element = uiElement()!
        if Wait().forElement(element).exists {
            element.tap()
        }
        return self
    }

    @discardableResult
    public func forceKeyboardFocus(_ retries: Int = 5) -> UIElement {
        var count = 0
        uiElement()!.tap()
        // Give xctest enough time to evaluate predicate.
        while !Wait().hasKeyboardFocus(uiElement()!) {
            if count < retries {
                uiElement()!.tap()
                count += 1
            } else {
                XCTFail("Unable to set the keyboard focus to element: \(String(describing: uiElement()?.debugDescription))")
            }
        }
        return self
    }

    @discardableResult
    public func swipeUpUntilVisible(maxAttempts: Int = 5) -> UIElement {
        var eventCount = 0
        var swipeArea: XCUIElement

        if focusedTable != nil {
            swipeArea = focusedTable!
        } else {
            swipeArea = currentApp!
        }

        while eventCount <= maxAttempts, !isVisible {
            swipeArea.swipeUp()
            eventCount += 1
        }
        return self
    }

    @discardableResult
    public func swipeDownUntilVisible(maxAttempts: Int = 5) -> UIElement {
        var eventCount = 0
        var swipeArea: XCUIElement

        if focusedTable != nil {
            swipeArea = focusedTable!
        } else {
            swipeArea = currentApp!
        }

        while eventCount <= maxAttempts, !isVisible {
            swipeArea.swipeDown()
            eventCount += 1
        }
        return self
    }

    /// Allow actions on children / descendants
    public func onChild(_ childElement: UIElement) -> UIElement {
        self.childElement = childElement
        return self
    }

    @discardableResult
    public func onDescendant(_ descendantElement: UIElement) -> UIElement {
        self.descendantElement = descendantElement
        return self
    }

    /// Checks
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

    /**
     * The core function responsible for XCUIElement location logic.
     */
    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    func uiElement() -> XCUIElement? {
        /// Return element instance if it was already located.
        if locatedElement != nil {
            shouldWaitForExistance = false
            return locatedElement!
        }

        /// Filter out XCUIElementQuery based on identifier or predicate value provided.
        if identifier != nil {
            if focusedTable != nil {
                uiElementQuery = currentApp!.tables[focusedTable!.identifier].descendants(matching: self.elementType).matching(identifier: identifier!)
            }
            uiElementQuery = uiElementQuery!.matching(identifier: identifier!)
        } else if predicate != nil {
            if focusedTable != nil {
                uiElementQuery = currentApp!.tables[focusedTable!.identifier].descendants(matching: self.elementType).matching(predicate!)
            }
            uiElementQuery = uiElementQuery!.matching(predicate!)
        }

        /// Fail test if both disabled and enbaled parameters were used.
        if elementDisabled == true && elementEnabled == true {
            XCTFail("Only one isDisabled() or isEnabled() function can be applied to query the element.", file: #file, line: #line)
        }

        /// Filter out XCUIElementQuery based on isEnabled / isDisabled state.
        if elementDisabled == true {
            uiElementQuery = uiElementQuery?.matching(Predicate.disabled)
        } else if elementEnabled == true {
            uiElementQuery = uiElementQuery?.matching(Predicate.enabled)
        }

        /// Filter out XCUIElementQuery based on element label predicate.
        if labelPredicate != nil {
            uiElementQuery = uiElementQuery?.matching(labelPredicate!)
        }

        /// Filter out XCUIElementQuery based on element title predicate.
        if titlePredicate != nil {
            uiElementQuery = uiElementQuery?.matching(titlePredicate!)
        }

        /// Filter out XCUIElementQuery based on element value predicate.
        if valuePredicate != nil {
            uiElementQuery = uiElementQuery?.matching(valuePredicate!)
        }

        /// Filter out XCUIElementQuery based on provided predicate.
        if matchedPredicate != nil {
            uiElementQuery = uiElementQuery?.matching(matchedPredicate!)
        }

        /// Filter out XCUIElementQuery based on isHittable state.
        if elementHittable == true {
            uiElementQuery = uiElementQuery?.matching(Predicate.hittable)
        }

        /// Matching elements by the sub-elements it contains
        if containsType != nil && containsIdentifier != nil {
            uiElementQuery = uiElementQuery!.containing(containsType!, identifier: containsIdentifier!)
        }

        if containsPredicate != nil {
            uiElementQuery = uiElementQuery!.containing(containsPredicate!)
        }

        if containLabel != nil {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", containLabel!)
            uiElementQuery = uiElementQuery!.containing(predicate)
        }

        if index != nil {
            /// Locate  XCUIElementQuery based on its index.
            locatedElement = uiElementQuery!.element(boundBy: index!)
        } else {
            /// Return matched element of given type.
            if shouldUseFirstMatch {
                locatedElement = uiElementQuery!.element.firstMatch
            } else {
                locatedElement = uiElementQuery!.element
            }
        }

        if childElement != nil {
            /// Return child element based on UiElement instance provided.
            locatedElement = locatedElement?.child(childElement!)
        } else if descendantElement != nil {
            /// Return descendant element based on UiElement instance provided.
            locatedElement = locatedElement?.descendant(descendantElement!)
        }

        if shouldWaitForExistance {
            return Wait().forElement(locatedElement!)
        } else {
            return locatedElement!
        }
    }

    private var isVisible: Bool {
        guard uiElement()!.exists && !uiElement()!.frame.isEmpty else { return false }
        return currentApp!.windows.element(boundBy: 0).frame.contains(uiElement()!.frame)
    }
}
