//
//  UiElement.swift
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
open class UiElement {

    init(_ query: XCUIElementQuery) {
        self.uiElementQuery = query
    }

    init(_ identifier: String, _ query: XCUIElementQuery) {
        self.uiElementQuery = query
        self.identifier = identifier
    }

    init(_ predicate: NSPredicate, _ query: XCUIElementQuery) {
        self.uiElementQuery = query
        self.predicate = predicate
    }

    internal var uiElementQuery: XCUIElementQuery?
    private let app = XCUIApplication()
    private var locatedElement: XCUIElement?
    private var index: Int?
    private var identifier: String?
    private var childElement: UiElement?
    private var descendantElement: UiElement?
    private var elementEnabled: Bool?
    private var elementDisabled: Bool?
    private var elementHittable: Bool?
    private var predicate: NSPredicate?
    private var matchedPredicate: NSPredicate?
    private var labelPredicate: NSPredicate?
    private var titlePredicate: NSPredicate?
    private var valuePredicate: NSPredicate?
    private var tableToSwipeInto: XCUIElement?

    internal func getType() -> XCUIElement.ElementType {
        return self.uiElement().elementType
    }

    internal func setType(_ elementQuery: XCUIElementQuery) -> UiElement {
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
    public func label() -> String {
        return locatedElement!.label
    }

    public func title() -> String {
        return locatedElement!.title
    }

    public func value() -> Any? {
        return locatedElement!.value
    }

    public func exists() -> Bool {
        return locatedElement!.exists
    }

    public func enabled() -> Bool {
        return locatedElement!.isEnabled
    }

    public func hittable() -> Bool {
        return locatedElement!.isHittable
    }
    
    public func childsCount() -> Int {
        return locatedElement!.children(matching: XCUIElement.ElementType.any).count
    }
    
    public func childsCountByType(_ type: XCUIElement.ElementType) -> Int {
        return locatedElement!.children(matching: type).count
    }

    public func selected() -> Bool {
        return locatedElement!.isSelected
    }

    /// Matchers
    public func byIndex(_ index: Int) -> UiElement {
        self.index = index
        return self
    }

    public func isEnabled() -> UiElement {
        self.elementEnabled = true
        return self
    }

    public func isDisabled() -> UiElement {
        self.elementDisabled = true
        return self
    }

    public func isHittable() -> UiElement {
        self.elementHittable = true
        return self
    }

    /**
     * Use it to specify in which table element test should swipe up or down in case of multiple tables in the layout hierarchy:
     * Example: cell(identifier).inTable(table(identifier)).swipeUpUntilVisible()
     */
    public func inTable(_ table: UiElement) -> UiElement {
        tableToSwipeInto = table.uiElement()
        return self
    }

    public func matchesPredicate(_ matchedPredicate: NSPredicate) -> UiElement {
        self.matchedPredicate = matchedPredicate
        return self
    }

    public func hasLabel(_ label: String) -> UiElement {
        return hasLabel(Predicate.labelEquals(label))
    }

    public func hasLabel(_ labelPredicate: NSPredicate) -> UiElement {
        self.labelPredicate = labelPredicate
        return self
    }

    public func hasTitle(_ title: String) -> UiElement {
        return hasTitle(Predicate.titleEquals(title))
    }

    public func hasTitle(_ titlePredicate: NSPredicate) -> UiElement {
        self.titlePredicate = titlePredicate
        return self
    }

    public func hasValue(_ value: String) -> UiElement {
        return hasValue(Predicate.valueEquals(value))
    }

    public func hasValue(_ valuePredicate: NSPredicate) -> UiElement {
        self.valuePredicate = valuePredicate
        return self
    }

    /// Actions
    public func adjust(to value: String) -> UiElement {
        Wait().forElement(uiElement()).adjust(toPickerWheelValue: "\(value)")
        return self
    }

    public func clearText() -> UiElement {
        Wait().forElement(uiElement()).clearText()
        return self
    }

    @discardableResult
    public func doubleTap() -> UiElement {
        Wait().forElement(uiElement()).doubleTap()
        return self
    }

    @discardableResult
    public func forceTap() -> UiElement {
        Wait().forElement(uiElement()).coordinate(withNormalizedOffset: .zero).tap()
        return self
    }

    @discardableResult
    public func longPress(_ timeInterval: TimeInterval = 2) -> UiElement {
        Wait().forElement(uiElement()).press(forDuration: timeInterval)
        return self
    }
    
    @discardableResult
    public func pinch(scale: CGFloat, velocity: CGFloat) -> UiElement {
        Wait().forElement(uiElement()).pinch(withScale: scale, velocity: velocity)
        return self
    }
    
    @discardableResult
    public func twoFingerTap(scale: CGFloat, velocity: CGFloat) -> UiElement {
        Wait().forElement(uiElement()).twoFingerTap()
        return self
    }

    @discardableResult
    public func swipeDown() -> UiElement {
        Wait().forElement(uiElement()).swipeDown()
        return self
    }

    @discardableResult
    public func swipeLeft() -> UiElement {
        Wait().forElement(uiElement()).swipeLeft()
        return self
    }

    @discardableResult
    public func swipeRight() -> UiElement {
        Wait().forElement(uiElement()).swipeRight()
        return self
    }

    @discardableResult
    public func swipeUp() -> UiElement {
        Wait().forElement(uiElement()).swipeUp()
        return self
    }

    @discardableResult
    public func tap() -> UiElement {
        Wait().forElement(uiElement()).tap()
        return self
    }
    
    @discardableResult
    public func tapIfExists() -> UiElement {
        let element = uiElement()
        if (Wait().forElement(element).exists) {
            element.tap()
        }
        return self
    }

    @discardableResult
    public func typeText(_ text: String) -> UiElement {
        Wait().forElement(uiElement()).typeText(text)
        return self
    }

    @discardableResult
    public func swipeUpUntilVisible(maxAttempts: Int = 5) -> UiElement {
        var eventCount = 0
        var swipeArea: XCUIElement
        
        if tableToSwipeInto != nil {
            swipeArea = tableToSwipeInto!
        } else {
            swipeArea = app
        }
        
        while eventCount <= maxAttempts, !isVisible {
            swipeArea.swipeUp()
            eventCount += 1
        }
        return self
    }

    @discardableResult
    public func swipeDownUntilVisible(maxAttempts: Int = 5) -> UiElement {
        var eventCount = 0
        var swipeArea: XCUIElement
        
        if tableToSwipeInto != nil {
            swipeArea = tableToSwipeInto!
        } else {
            swipeArea = app
        }
        
        while eventCount <= maxAttempts, !isVisible {
            swipeArea.swipeDown()
            eventCount += 1
        }
        return self
    }

    /// Allow actions on childs / descendants
    public func onChild(_ childElement: UiElement) -> UiElement {
        self.childElement = childElement
        return self
    }

    public func onDescendant(_ descendantElement: UiElement) -> UiElement {
        self.descendantElement = descendantElement
        return self
    }

    /// Checks
    @discardableResult
    public func checkExists() -> UiElement {
        XCTAssertTrue(uiElement().exists, "Expected element \(uiElement().debugDescription) to exist but it doesn't.", file: #file, line: #line)
        return self
    }

    @discardableResult
    public func checkIsHittable() -> UiElement {
        XCTAssertTrue(uiElement().isHittable, "Expected element \(uiElement().debugDescription) to be hittable but it is not.", file: #file, line: #line)
        return self
    }

    @discardableResult
    public func checkDoesNotExist() -> UiElement {
        XCTAssertFalse(uiElement().exists, "Expected element \(uiElement().debugDescription) to not exist but it exists.", file: #file, line: #line)
        return self
    }

    @discardableResult
    public func checkDisabled() -> UiElement {
        XCTAssertFalse(uiElement().isEnabled, "Expected element \(uiElement().debugDescription) to be in disabled state but it is enabled.", file: #file, line: #line)
        return self
    }
    
    @discardableResult
    public func checkEnabled() -> UiElement {
        XCTAssertTrue(uiElement().isEnabled, "Expected element \(uiElement().debugDescription) to be in enabled state but it is disabled.", file: #file, line: #line)
        return self
    }

    @discardableResult
    public func checkHasChild(_ childElement: UiElement) -> UiElement {
        let locatedElement = uiElement().child(childElement)
        XCTAssertTrue(locatedElement.exists, "Expected to find a child element: \"\(childElement.uiElement().debugDescription)\" but found nothing.")
        return self
    }

    @discardableResult
    public func checkHasDescendant(_ descendantElement: UiElement) -> UiElement {
        let locatedElement = uiElement().descendant(descendantElement)
        XCTAssertTrue(locatedElement.exists, "Expected to find descendant element: \"\(descendantElement.uiElement().debugDescription)\" but found nothing.")
        return self
    }

    @discardableResult
    public func checkHasLabel(_ label: String) -> UiElement {
        guard let labelValue = uiElement().label as? String else {
            XCTFail("Element doesn't have text label.")
            return self
        }
        XCTAssertTrue(labelValue == label, "Expected Element text label to be: \"\(label)\", but found: \"\(labelValue)\"")
        return self
    }

    @discardableResult
    public func checkHasValue(_ value: String) -> UiElement {
        guard let stringValue = uiElement().value as? String else {
            XCTFail("Element doesn't have text value.")
            return self
        }
        XCTAssertTrue(stringValue == value, "Expected Element text value to be: \"\(value)\", but found: \"\(stringValue)\"")
        return self
    }

    @discardableResult
    public func checkHasTitle(_ title: String) -> UiElement {
        guard let stringValue = uiElement().title as? String else {
            XCTFail("Element doesn't have title value.")
            return self
        }
        XCTAssertTrue(stringValue == title, "Expected Element title to be: \"\(title)\", but found: \"\(stringValue)\"")
        return self
    }

    @discardableResult
    public func checkSelected() -> UiElement {
        XCTAssertTrue(uiElement().isSelected == true, "Expected Element to be selected, but it is not")
        return self
    }

    /// Waits
    @discardableResult
    public func wait(time: TimeInterval = 10.0) -> UiElement {
        Wait(time: time).forElement(uiElement())
        return self
    }

    @discardableResult
    public func waitForDisabled(time: TimeInterval = 10.0) -> UiElement {
        Wait(time: time).forElementToBeDisabled(uiElement())
        return self
    }

    @discardableResult
    public func waitForHittable(time: TimeInterval = 10.0) -> UiElement {
        Wait(time: time).forElementToBeHittable(uiElement())
        return self
    }

    @discardableResult
    public func waitForEnabled(time: TimeInterval = 10.0) -> UiElement {
        Wait(time: time).forElementToBeEnabled(uiElement())
        return self
    }

    @discardableResult
    public func waitUntilGone(time: TimeInterval = 10.0) -> UiElement {
        Wait(time: time).forElementToDisappear(uiElement())
        return self
    }

    /**
     * The core function responsible for XCUIElement location logic.
     */
    internal func uiElement() -> XCUIElement {
        /// Return element instance if it was already located.
        if locatedElement != nil {
            return locatedElement!
        }

        /// Fail test if identifier, predicate and index are nil.
        if identifier == nil && predicate == nil && index == nil {
            XCTFail("Unable to locate an element when its identifier, predicate and element index are nil.", file: #file, line: #line)
        }

        /// Filer out XCUIElementQuery based on identifier or predicate value provided.
        if identifier != nil {
            uiElementQuery = uiElementQuery!.matching(identifier: identifier!)
        } else if predicate != nil {
            uiElementQuery = uiElementQuery!.matching(predicate!)
        }

        /// Fail test if both disabled and enbaled parameters were used.
        if elementDisabled == true && elementEnabled == true {
            XCTFail("Only one isDisabled() or isEnabled() function can be applied to query the element.", file: #file, line: #line)
        }

        /// Filer out XCUIElementQuery based on isEnabled / isDisabled state.
        if elementDisabled == true {
            uiElementQuery = uiElementQuery?.matching(Predicate.disabled)
        } else if elementEnabled == true {
            uiElementQuery = uiElementQuery?.matching(Predicate.enabled)
        }

        /// Filer out XCUIElementQuery based on element label predicate.
        if labelPredicate != nil {
            uiElementQuery = uiElementQuery?.matching(labelPredicate!)
        }

        /// Filer out XCUIElementQuery based on element title predicate.
        if titlePredicate != nil {
            uiElementQuery = uiElementQuery?.matching(titlePredicate!)
        }

        /// Filer out XCUIElementQuery based on element value predicate.
        if valuePredicate != nil {
            uiElementQuery = uiElementQuery?.matching(valuePredicate!)
        }

        /// Filer out XCUIElementQuery based on provided predicate.
        if matchedPredicate != nil {
            uiElementQuery = uiElementQuery?.matching(matchedPredicate!)
        }

        /// Filer out XCUIElementQuery based on isHittable state.
        if elementHittable == true {
            uiElementQuery = uiElementQuery?.matching(Predicate.hittable)
        }

        /// Return element from XCUIElementQuery based on its index.
        if index != nil {
             return uiElementQuery!.element(boundBy: index!)
        }

        /// Return child element based on UiElement instance provided.
        if childElement != nil {
            return uiElementQuery!.element.child(childElement!)
        }

        /// Return descendant element based on UiElement instance provided.
        if descendantElement != nil {
            return uiElementQuery!.element.descendant(descendantElement!)
        }

        locatedElement = uiElementQuery!.element

        return locatedElement!
    }

    private var isVisible: Bool {
        guard uiElement().exists && !uiElement().frame.isEmpty else { return false }
        return app.windows.element(boundBy: 0).frame.contains(uiElement().frame)
    }
}
