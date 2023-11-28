//
//  UIElement+Matchers.swift
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

extension UIElement {

    /**
     Specifies the index to use when locating the UI element.
     Sets the `index` property to the provided integer value.
     This method is useful when multiple elements match the criteria and a specific instance is needed.
     Returns the current instance of `UIElement` for continued action chaining.
     */
    public func byIndex(_ index: Int) -> UIElement {
        return updateProperty { self.index = index }
    }

    /**
     Specifies that the target element should have a specific descendant.
     Sets the `containsType`, `containsIdentifier`, and `containsPredicate` properties based on the provided `UIElement`.
     Useful for finding elements that must contain a certain sub-element.
     Returns the current instance of `UIElement`.
     */
    public func hasDescendant(_ element: UIElement) -> UIElement {
        return updateProperty {
            self.containsType = element.getType()
            self.containsIdentifier = element.getIdentifier()
            self.containsPredicate = element.getPredicate()
        }
    }

    /**
     Filters the UI elements to include only those containing a specific label.
     Sets the `containLabel` property to the provided string.
     Useful for narrowing down elements based on visible text.
     Returns the current instance of `UIElement`.
     */
    public func containsLabel(_ label: String) -> UIElement {
        return updateProperty { self.containLabel = label }
    }

    /**
     Filters the UI elements to include only those that are enabled.
     Sets the `elementEnabled` property to `true`.
     Use this method to focus on elements that are interactive and not disabled.
     Returns the current instance of `UIElement`.
     */
    public func isEnabled() -> UIElement {
        return updateProperty { self.elementEnabled = true }
    }

    /**
     Filters the UI elements to include only those that are disabled.
     Sets the `elementDisabled` property to `true`.
     Use this method to locate elements that are currently non-interactive.
     Returns the current instance of `UIElement`.
     */
    public func isDisabled() -> UIElement {
        return updateProperty { self.elementDisabled = true }
    }

    /**
     Filters the UI elements to include only those that are hittable.
     Sets the `elementHittable` property to `true`.
     Useful for ensuring that elements can be tapped or interacted with.
     Returns the current instance of `UIElement`.
     */
    public func isHittable() -> UIElement {
        return updateProperty { self.elementHittable = true }
    }

    /**
     Indicates that only the first matching element should be considered.
     Sets the `shouldUseFirstMatch` property to `true`.
     Useful when the exact order of elements is known and only the first one is relevant.
     Returns the current instance of `UIElement`.
     */
    public func firstMatch() -> UIElement {
        return updateProperty { self.shouldUseFirstMatch = true }
    }

    /**
     Specifies the table context in which to search for the UI element.
     Sets the `focusedTable` to the `XCUIElement` of the provided `UIElement`.
     Especially useful in complex layouts with multiple tables.
     Returns the current instance of `UIElement`.
     */
    public func inTable(_ table: UIElement) -> UIElement {
        return updateProperty { self.focusedTable = table.uiElement() }
    }

    /**
     Filters the UI elements based on a custom NSPredicate.
     Sets the `matchedPredicate` property to the provided predicate.
     Allows for advanced and flexible querying of UI elements.
     Returns the current instance of `UIElement`.
     */
    public func matchesPredicate(_ matchedPredicate: NSPredicate) -> UIElement {
        return updateProperty { self.matchedPredicate = matchedPredicate }
    }

    /**
     Filters the UI elements to include only those with a specific label.
     Converts the provided string to a label-matching NSPredicate.
     Returns the current instance of `UIElement` after applying the label filter.
     */
    public func hasLabel(_ label: String) -> UIElement {
        return hasLabel(Predicate.labelEquals(label))
    }

    /**
     Filters the UI elements to include only those that match the given label predicate.
     Sets the `labelPredicate` property to the provided NSPredicate.
     Offers flexible label-based filtering of UI elements.
     Returns the current instance of `UIElement`.
     */
    public func hasLabel(_ labelPredicate: NSPredicate) -> UIElement {
        self.labelPredicate = labelPredicate
        return self
    }

    /**
     Filters the UI elements to include only those with a specific title.
     Converts the provided string to a title-matching NSPredicate.
     Returns the current instance of `UIElement` after applying the title filter.
     */
    public func hasTitle(_ title: String) -> UIElement {
        return hasTitle(Predicate.titleEquals(title))
    }

    /**
     Filters the UI elements to include only those that match the given title predicate.
     Sets the `titlePredicate` property to the provided NSPredicate.
     Enables detailed title-based filtering of UI elements.
     Returns the current instance of `UIElement`.
     */
    public func hasTitle(_ titlePredicate: NSPredicate) -> UIElement {
        return updateProperty { self.titlePredicate = titlePredicate }
    }

    /**
     Filters the UI elements to include only those with a specific value.
     Converts the provided string to a value-matching NSPredicate.
     Returns the current instance of `UIElement` after applying the value filter.
     */
    public func hasValue(_ value: String) -> UIElement {
        return hasValue(Predicate.valueEquals(value))
    }

    /**
     Filters the UI elements to include only those that match the given value predicate.
     Sets the `valuePredicate` property to the provided NSPredicate.
     Allows for precise value-based filtering of UI elements.
     */
    public func hasValue(_ valuePredicate: NSPredicate) -> UIElement {
        return updateProperty { self.valuePredicate = valuePredicate }
    }

    /**
     Targets a specific child element for subsequent actions.
     This method sets the `childElement` property to the specified `UIElement` instance.
     It allows for chaining actions on the specified child element of the current `UIElement`.
     Returns the current instance of `UIElement` for continued action chaining.
     */
    public func onChild(_ childElement: UIElement) -> UIElement {
        return updateProperty { self.childElement = childElement }
    }

    /**
     Targets a specific descendant element for subsequent actions.
     This method sets the `descendantElement` property to the specified `UIElement` instance.
     It allows for chaining actions on a specified descendant element of the current `UIElement`.
     Returns the current instance of `UIElement` for continued action chaining.
     */
    @discardableResult
    public func onDescendant(_ descendantElement: UIElement) -> UIElement {
        return updateProperty { self.descendantElement = descendantElement }
    }
}
