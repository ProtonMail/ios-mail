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
 Represents single XCUIElement and provides an interface for performing actions or checks.
 By default each XCUIElement that is referenced by this class already has a wait functionality in place except check functions or checkDoesNotExist() function.
 Check functions assume that element was already located before check is called. checkDoesNotExist() function shouldn't wait for the element.
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

    internal var elementType: XCUIElement.ElementType
    internal var uiElementQuery: XCUIElementQuery?
    internal var ancestorElement: XCUIElement?
    internal var parentElement: XCUIElement?
    internal var locatedElement: XCUIElement?
    internal var index: Int?
    internal var identifier: String?
    internal var childElement: UIElement?
    internal var descendantElement: UIElement?
    internal var elementEnabled: Bool?
    internal var elementDisabled: Bool?
    internal var elementHittable: Bool?
    internal var predicate: NSPredicate?
    internal var matchedPredicate: NSPredicate?
    internal var labelPredicate: NSPredicate?
    internal var titlePredicate: NSPredicate?
    internal var valuePredicate: NSPredicate?
    internal var focusedTable: XCUIElement?
    internal var containsType: XCUIElement.ElementType?
    internal var containsIdentifier: String?
    internal var containsPredicate: NSPredicate?
    internal var containLabel: String?
    internal var shouldUseFirstMatch: Bool = false
    internal var shouldWaitForExistance = true

    // MARK: - Element Properties
    /**
     Returns the label of the located UI element.

     This method retrieves the `label` property of the element found by `uiElement()`.
     It's typically used to access the textual description of the element, often visible to the user.
     Returns `nil` if the element is not found or does not have a label.
     */
    public func label() -> String? {
        return uiElement()?.label
    }

    /**
     Returns the placeholder value of the located UI element, if available.

     This method retrieves the `placeholderValue` of the element, which is often used in text fields to provide a hint to the user.
     Returns `nil` if the element is not found or does not have a placeholder value.
     */
    public func placeholderValue() -> String? {
        return uiElement()?.placeholderValue
    }

    /**
     Retrieves the title of the located UI element.

     This method is used to access the `title` property of the element, which is typically used in buttons, navigation bars, etc.
     Returns `nil` if the element is not found or does not have a title.
     */
    public func title() -> String? {
        return uiElement()?.title
    }

    /**
     Returns the value of the located UI element.

     This method accesses the `value` property of the element, which can represent different types of data depending on the element's nature (e.g., the text of a text field).
     Returns `nil` if the element is not found or does not have a value.
     */
    public func value() -> Any? {
        return uiElement()?.value
    }

    /**
     Checks whether the located UI element exists in the UI hierarchy.

     This method evaluates if the element identified by `uiElement()` currently exists.
     Returns `false` if the element does not exist.
     */
    public func exists() -> Bool {
        return uiElement()?.exists ?? false
    }

    /**
     Determines if the located UI element is enabled.

     This method checks the `isEnabled` property, which indicates whether the element is currently enabled and can accept user interactions.
     Returns `false` if the element is not found or is disabled.
     */
    public func enabled() -> Bool {
        return uiElement()?.isEnabled ?? false
    }

    /**
     Checks if the located UI element is hittable (i.e., can be tapped).

     This method evaluates the `isHittable` property to determine if the element can be tapped or clicked in the current UI state.
     Returns `false` if the element is not found or is not hittable.
     */
    public func hittable() -> Bool {
        return uiElement()?.isHittable ?? false
    }

    /**
     Determines if the located UI element is selected.

     This method assesses the `isSelected` property, indicating if the element is in a selected state (common in buttons, toggle switches, etc.).
     Returns `false` if the element is not found or is not selected.
     */
    public func selected() -> Bool {
        return uiElement()?.isSelected ?? false
    }

    /**
     Counts the number of child elements of the located UI element.

     This method returns the count of child elements of any type (`ElementType.any`) for the element located by `uiElement()`.
     Returns `0` if the element is not found or has no children.
     */
    public func childrenCount() -> Int {
        return uiElement()?.children(matching: .any).count ?? 0
    }

    /**
     Counts the number of child elements of a specific type for the located UI element.

     This method takes an `XCUIElement.ElementType` and returns the count of child elements of that type.
     Returns `0` if the element is not found or has no children of the specified type.
     */
    public func childrenCountByType(_ type: XCUIElement.ElementType) -> Int {
        return uiElement()?.children(matching: type).count ?? 0
    }

    /**
     Counts the number of child elements that match a given predicate for the located UI element.

     This method accepts an `NSPredicate` and an optional `XCUIElement.ElementType` (defaults to `.any`).
     It returns the count of child elements that match the predicate and element type.
     Returns `0` if the element is not found or no children match the criteria.
     */
    public func childrenCountByPredicate(_ predicate: NSPredicate, _ type: XCUIElement.ElementType? = nil) -> Int {
        let elementType = type ?? .any
        return uiElement()?.children(matching: elementType).matching(predicate).count ?? 0
    }

    /**
     Counts the number of descendant elements that match a given predicate for the located UI element.

     Similar to `childrenCountByPredicate`, but evaluates all descendants (not just direct children) matching the provided `NSPredicate` and `XCUIElement.ElementType`.
     Returns `0` if the element is not found or no descendants match the criteria.
     */
    public func descendantsCountByPredicate(_ predicate: NSPredicate, _ type: XCUIElement.ElementType? = nil) -> Int {
        let elementType = type ?? .any
        return uiElement()?.descendants(matching: elementType).matching(predicate).count ?? 0
    }

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

    @discardableResult
    internal func updateProperty(_ updateBlock: () -> Void) -> UIElement {
        updateBlock()
        return self
    }

    /**
     The core function responsible for locating a specific XCUIElement.

     This function orchestrates the process of finding a user interface element within an iOS application's UI hierarchy. It performs several key actions in a sequence:

     - Initially, it checks if the element has already been located (`locatedElement`). If found, it returns this element immediately, bypassing additional processing.

     - The function then applies a set of filters using `applyFilters()`. These filters narrow down the search based on criteria like identifiers, predicates, element state (enabled/disabled), and other attributes. The filtering process is crucial in identifying the correct element within potentially complex UI structures.

     - It checks for conflicting parameters (such as having both `elementDisabled` and `elementEnabled` set to true) using `checkForConflictingParameters()`. If any conflicts are found, it fails the test to prevent ambiguous or erroneous behavior.

     - The function then attempts to locate the element based on its index in the UI hierarchy using `locateElementByIndex()`. This step involves determining the specific instance of an element when multiple similar elements exist.

     - Finally, the function returns the located element. If `shouldWaitForExistance` is set to true, it waits for the element's existence before returning. This waiting mechanism is useful in scenarios where UI elements might take some time to appear due to network latency, animations, or other asynchronous operations.

     This function is marked as `internal`, meaning it can be accessed within the same module but not from outside it.
     */
    internal func uiElement() -> XCUIElement? {
        // Check if element is already located
        if let locatedElement = locatedElement {
            shouldWaitForExistance = false
            return locatedElement
        }

        // Apply filters based on provided criteria
        applyFilters()

        // Fail test if conflicting parameters are used
        checkForConflictingParameters()

        // Locate element by index and return it
        locatedElement = locateElementByIndex()

        // Handle child element if specified
        if let child = childElement {
            locatedElement = locatedElement?.child(child)
        }
        // Handle descendant element if specified
        else if let descendant = descendantElement {
            locatedElement = locatedElement?.descendant(descendant)
        }

        return shouldWaitForExistance ? Wait().forElement(locatedElement!) : locatedElement!
    }

    /**
     Applies filters to the XCUIElementQuery based on whether elements are enabled or disabled.
     This function checks the `elementDisabled` and `elementEnabled` properties.
     - If `elementDisabled` is true, it filters out all elements that are not disabled.
     - If `elementEnabled` is true, it filters out all elements that are not enabled.
     */
    private func applyEnabledDisabledFilter() {
        if let elementDisabled = elementDisabled {
            if elementDisabled {
                uiElementQuery = uiElementQuery?.matching(Predicate.disabled)
            }
        }

        if let elementEnabled = elementEnabled {
            if elementEnabled {
                uiElementQuery = uiElementQuery?.matching(Predicate.enabled)
            }
        }
    }

    /**
     Applies additional filters to the XCUIElementQuery based on label, title, value, and custom predicates.
     This function uses the `labelPredicate`, `titlePredicate`, `valuePredicate`, and `matchedPredicate`.
     - Each predicate is applied to the query to narrow down the search based on the specific attributes
     of the XCUIElements, such as their labels, titles, or values.
     */
    private func applyLabelTitleValuePredicates() {
        if labelPredicate != nil {
            uiElementQuery = uiElementQuery?.matching(labelPredicate!)
        }

        if titlePredicate != nil {
            uiElementQuery = uiElementQuery?.matching(titlePredicate!)
        }

        if valuePredicate != nil {
            uiElementQuery = uiElementQuery?.matching(valuePredicate!)
        }

        if matchedPredicate != nil {
            uiElementQuery = uiElementQuery?.matching(matchedPredicate!)
        }
    }

    /**
     Applies filters to the XCUIElementQuery based on containment criteria.
     This function checks for various containment conditions:
     - If both `containsType` and `containsIdentifier` are set, it filters elements containing a specific type with a specific identifier.
     - If `containsPredicate` is set, it filters elements that satisfy the given predicate.
     - If `containLabel` is set, it filters elements whose label contains the specified text.
     */
    private func applyContainsFilters() {
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
    }

    /**
     Locates and returns an XCUIElement based on its index within the query.
     - If `index` is specified, the function returns the element at that specific index.
     - If `shouldUseFirstMatch` is true and no index is specified, it returns the first matching element.
     - If neither index is specified nor `shouldUseFirstMatch` is true, it returns the single element expected to be found.
     */
    private func locateElementByIndex() -> XCUIElement? {
        if let index = index {
            return uiElementQuery!.element(boundBy: index)
        } else if shouldUseFirstMatch {
            return uiElementQuery!.element.firstMatch
        } else {
            return uiElementQuery!.element
        }
    }

    enum FilterType {
        case identifier(String)
        case predicate(NSPredicate)
    }

    /**
     Applies a series of filters to the XCUIElementQuery based on the properties set in the class.

     This function performs the following actions in sequence:
     - If an `identifier` is set, it applies an identifier-based filter.
     - If an `identifier` is not set but a `predicate` is, it applies a predicate-based filter.
     - It applies filters based on the `elementDisabled` and `elementEnabled` states.
     - Additional filters are applied for `labelPredicate`, `titlePredicate`, `valuePredicate`, and any custom predicates.
     - It checks if `elementHittable` is set to true and applies a hittability filter if necessary.
     - Finally, it applies any filters based on containment criteria, such as sub-elements that need to be present in the target element.
     */
    private func applyFilters() {
        // Filter based on identifier, predicate, and isEnabled/isDisabled state
        if let identifier = identifier {
            applyFilter(.identifier(identifier))
        } else if let predicate = predicate {
            applyFilter(.predicate(predicate))
        }
        applyEnabledDisabledFilter()

        // Additional filters for label, title, value, and custom predicates
        applyLabelTitleValuePredicates()

        // Filters based on hittability and sub-elements
        if elementHittable ?? false {
            uiElementQuery = uiElementQuery?.matching(Predicate.hittable)
        }
        applyContainsFilters()
    }

    /**
     A generic function to apply a specific filter to the XCUIElementQuery.

     This function takes a `FilterType` enumeration which can be either `.identifier` or `.predicate`:
     - For `.identifier`, it applies a filter that matches elements with the given identifier.
     - For `.predicate`, it applies a filter based on the provided NSPredicate object.

     If a `focusedTable` is set, the filter is applied within the scope of this table; otherwise, it's applied to the entire `uiElementQuery`.
     */
    private func applyFilter(_ filter: FilterType) {
        switch filter {
        case .identifier(let identifier):
            uiElementQuery = focusedTableQuery()?.matching(identifier: identifier) ?? uiElementQuery!.matching(identifier: identifier)
        case .predicate(let predicate):
            uiElementQuery = focusedTableQuery()?.matching(predicate) ?? uiElementQuery!.matching(predicate)
        }
    }

    /**
     Verifies if there are any conflicting parameters set and triggers a test failure if found.

     This function checks for the simultaneous presence of `elementDisabled` and `elementEnabled` properties.
     As these two properties are mutually exclusive (an element cannot be both enabled and disabled at the same time),
     the function triggers an XCTFail with a message indicating the conflict if both are true.
     */
    private func checkForConflictingParameters() {
        if let elementDisabled = elementDisabled, let elementEnabled = elementEnabled, elementDisabled && elementEnabled {
            XCTFail("Conflicting isEnabled and isDisabled parameters.", file: #file, line: #line)
        }
    }

    /**
     Constructs and returns a query for a focused table, if it exists.

     This function is used to narrow down the search scope to a specific table when such a focus is necessary.
     - It checks if a `focusedTable` is set.
     - If set, it creates and returns a query that targets descendants of the focused table that match the element type set in the class.
     - If no focused table is specified, the function returns `nil`, indicating that no focused table query is needed.
     */
    private func focusedTableQuery() -> XCUIElementQuery? {
        guard let focusedTable = focusedTable else { return nil }
        return currentApp!.tables[focusedTable.identifier].descendants(matching: self.elementType)
    }
}
