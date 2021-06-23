//
//  Elements.swift
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
 * Collection of all XCUIElement types that can be used in UI testing.
 */
open class Elements {
    
    public init() {}

    public func acttivityIndicator() -> UiElement { UiElement(XCUIApplication().activityIndicators) }
    public func acttivityIndicator(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().activityIndicators) }
    public func activityIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().activityIndicators) }

    public func alert() -> UiElement { UiElement(XCUIApplication().alerts) }
    public func alert(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().alerts) }
    public func alert(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().alerts) }

    public func browser() -> UiElement { UiElement(XCUIApplication().browsers) }
    public func browser(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().browsers) }
    public func browser(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().browsers) }

    public func button() -> UiElement { UiElement(XCUIApplication().buttons) }
    public func button(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().buttons) }
    public func button(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().buttons) }

    public func cell() -> UiElement { UiElement(XCUIApplication().cells) }
    public func cell(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().cells) }
    public func cell(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().cells) }

    public func checkBox() -> UiElement { UiElement(XCUIApplication().checkBoxes) }
    public func checkBox(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().checkBoxes) }
    public func checkBox(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().checkBoxes) }

    public func collectionView() -> UiElement { UiElement(XCUIApplication().collectionViews) }
    public func collectionView(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().collectionViews) }
    public func collectionView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().collectionViews) }

    public func colorWell() -> UiElement { UiElement(XCUIApplication().colorWells) }
    public func colorWell(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().colorWells) }
    public func colorWell(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().colorWells) }

    public func comboBox() -> UiElement { UiElement(XCUIApplication().comboBoxes) }
    public func comboBox(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().comboBoxes) }
    public func comboBox(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().comboBoxes) }

    public func datePicker() -> UiElement { UiElement(XCUIApplication().datePickers) }
    public func datePicker(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().datePickers) }
    public func datePicker(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().datePickers) }

    public func decrementArrow() -> UiElement { UiElement(XCUIApplication().decrementArrows) }
    public func decrementArrow(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().decrementArrows) }
    public func decrementArrow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().decrementArrows) }

    public func dialog() -> UiElement { UiElement(XCUIApplication().dialogs) }
    public func dialog(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().dialogs) }
    public func dialog(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().dialogs) }

    public func disclosedChildRow() -> UiElement { UiElement(XCUIApplication().disclosedChildRows) }
    public func disclosedChildRow(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().disclosedChildRows) }
    public func disclosedChildRow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().disclosedChildRows) }

    public func disclosureTriangle() -> UiElement { UiElement(XCUIApplication().disclosureTriangles) }
    public func disclosureTriangle(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().disclosureTriangles) }
    public func disclosureTriangle(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().disclosureTriangles) }

    public func dockItem() -> UiElement { UiElement(XCUIApplication().dockItems) }
    public func dockItem(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().dockItems) }
    public func dockItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().dockItems) }

    public func drawer() -> UiElement { UiElement(XCUIApplication().drawers) }
    public func drawer(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().drawers) }
    public func drawer(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().drawers) }

    public func grid() -> UiElement { UiElement(XCUIApplication().grids) }
    public func grid(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().grids) }
    public func grid(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().grids) }

    public func group() -> UiElement { UiElement(XCUIApplication().groups) }
    public func group(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().groups) }
    public func group(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().groups) }

    public func handle() -> UiElement { UiElement(XCUIApplication().handles) }
    public func handle(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().handles) }
    public func handle(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().handles) }

    public func helpTag() -> UiElement { UiElement(XCUIApplication().helpTags) }
    public func helpTag(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().helpTags) }
    public func helpTag(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().helpTags) }

    public func icon() -> UiElement { UiElement(XCUIApplication().icons) }
    public func icon(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().icons) }
    public func icon(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().icons) }

    public func image() -> UiElement { UiElement(XCUIApplication().images) }
    public func image(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().images) }
    public func image(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().images) }

    public func incrementArrow() -> UiElement { UiElement(XCUIApplication().incrementArrows) }
    public func incrementArrow(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().incrementArrows) }
    public func incrementArrow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().incrementArrows) }

    public func keyboard() -> UiElement { UiElement(XCUIApplication().keyboards) }
    public func keyboard(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().keyboards) }
    public func keyboard(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().keyboards) }

    public func key() -> UiElement { UiElement(XCUIApplication().keys) }
    public func key(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().keys) }
    public func key(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().keys) }

    public func layoutArea() -> UiElement { UiElement(XCUIApplication().layoutAreas) }
    public func layoutArea(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().layoutAreas) }
    public func layoutArea(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().layoutAreas) }

    public func layoutItem() -> UiElement { UiElement(XCUIApplication().layoutItems) }
    public func layoutItem(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().layoutItems) }
    public func layoutItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().layoutItems) }

    public func levelIndicator() -> UiElement { UiElement(XCUIApplication().levelIndicators) }
    public func levelIndicator(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().levelIndicators) }
    public func levelIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().levelIndicators) }

    public func link() -> UiElement { UiElement(XCUIApplication().links) }
    public func link(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().links) }
    public func link(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().links) }

    public func map() -> UiElement { UiElement(XCUIApplication().maps) }
    public func map(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().maps) }
    public func map(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().maps) }

    public func matte() -> UiElement { UiElement(XCUIApplication().mattes) }
    public func matte(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().mattes) }
    public func matte(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().mattes) }

    public func menuBar() -> UiElement { UiElement(XCUIApplication().menuBars) }
    public func menuBar(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().menuBars) }
    public func menuBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().menuBars) }

    public func menuBarItem() -> UiElement { UiElement(XCUIApplication().menuBarItems) }
    public func menuBarItem(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().menuBarItems) }
    public func menuBarItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().menuBarItems) }

    public func menuButton() -> UiElement { UiElement(XCUIApplication().menuButtons) }
    public func menuButton(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().menuButtons) }
    public func menuButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().menuButtons) }

    public func menuItem() -> UiElement { UiElement(XCUIApplication().menuItems) }
    public func menuItem(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().menuItems) }
    public func menuItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().menuItems) }

    public func menu() -> UiElement { UiElement(XCUIApplication().menus) }
    public func menu(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().menus) }
    public func menu(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().menus) }

    public func navigationBar() -> UiElement { UiElement(XCUIApplication().navigationBars) }
    public func navigationBar(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().navigationBars) }
    public func navigationBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().navigationBars) }

    public func otherElement() -> UiElement { UiElement(XCUIApplication().otherElements) }
    public func otherElement(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().otherElements) }
    public func otherElement(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().otherElements) }

    public func outline() -> UiElement { UiElement(XCUIApplication().outlines) }
    public func outline(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().outlines) }
    public func outline(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().outlines) }

    public func outlineRow() -> UiElement { UiElement(XCUIApplication().outlineRows) }
    public func outlineRow(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().outlineRows) }
    public func outlineRow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().outlineRows) }

    public func pageIndicator() -> UiElement { UiElement(XCUIApplication().pageIndicators) }
    public func pageIndicator(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().pageIndicators) }
    public func pageIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().pageIndicators) }

    public func picker() -> UiElement { UiElement(XCUIApplication().pickers) }
    public func picker(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().pickers) }
    public func picker(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().pickers) }

    public func pickerWheel() -> UiElement { UiElement(XCUIApplication().pickerWheels) }
    public func pickerWheel(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().pickerWheels) }
    public func pickerWheel(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().pickerWheels) }

    public func popover() -> UiElement { UiElement(XCUIApplication().popovers) }
    public func popover(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().popovers) }
    public func popover(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().popovers) }

    public func popUpButton() -> UiElement { UiElement(XCUIApplication().popUpButtons) }
    public func popUpButton(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().popUpButtons) }
    public func popUpButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().popUpButtons) }

    public func progressIndicator() -> UiElement { UiElement(XCUIApplication().progressIndicators) }
    public func progressIndicator(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().progressIndicators) }
    public func progressIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().progressIndicators) }

    public func radioButton() -> UiElement { UiElement(XCUIApplication().radioButtons) }
    public func radioButton(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().radioButtons) }
    public func radioButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().radioButtons) }

    public func radioGroup() -> UiElement { UiElement(XCUIApplication().radioGroups) }
    public func radioGroup(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().radioGroups) }
    public func radioGroup(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().radioGroups) }

    public func ratingIndicator() -> UiElement { UiElement(XCUIApplication().ratingIndicators) }
    public func ratingIndicator(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().ratingIndicators) }
    public func ratingIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().ratingIndicators) }

    public func relevanceIndicator() -> UiElement { UiElement(XCUIApplication().relevanceIndicators) }
    public func relevanceIndicator(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().relevanceIndicators) }
    public func relevanceIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().relevanceIndicators) }

    public func rulerMarker() -> UiElement { UiElement(XCUIApplication().rulerMarkers) }
    public func rulerMarker(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().rulerMarkers) }
    public func rulerMarker(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().rulerMarkers) }

    public func ruler() -> UiElement { UiElement(XCUIApplication().rulers) }
    public func ruler(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().rulers) }
    public func ruler(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().rulers) }

    public func scrollBar() -> UiElement { UiElement(XCUIApplication().scrollBars) }
    public func scrollBar(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().scrollBars) }
    public func scrollBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().scrollBars) }

    public func scrollView() -> UiElement { UiElement(XCUIApplication().scrollViews) }
    public func scrollView(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().scrollViews) }
    public func scrollView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().scrollViews) }

    public func searchField() -> UiElement { UiElement(XCUIApplication().searchFields) }
    public func searchField(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().searchFields) }
    public func searchField(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().searchFields) }

    public func secureTextField() -> UiElement { UiElement(XCUIApplication().secureTextFields) }
    public func secureTextField(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().secureTextFields) }
    public func secureTextField(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().secureTextFields) }

    public func segmentedControl() -> UiElement { UiElement(XCUIApplication().segmentedControls) }
    public func segmentedControl(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().segmentedControls) }
    public func segmentedControl(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().segmentedControls) }

    public func sheet() -> UiElement { UiElement(XCUIApplication().sheets) }
    public func sheet(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().sheets) }
    public func sheet(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().sheets) }

    public func slider() -> UiElement { UiElement(XCUIApplication().sliders) }
    public func slider(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().sliders) }
    public func slider(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().sliders) }

    public func splitGroup() -> UiElement { UiElement(XCUIApplication().splitGroups) }
    public func splitGroup(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().splitGroups) }
    public func splitGroup(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().splitGroups) }

    public func splitter() -> UiElement { UiElement(XCUIApplication().splitters) }
    public func splitter(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().splitters) }
    public func splitter(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().splitters) }

    public func staticText() -> UiElement { UiElement(XCUIApplication().staticTexts) }
    public func staticText(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().staticTexts) }
    public func staticText(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().staticTexts) }

    public func statusBar() -> UiElement { UiElement(XCUIApplication().statusBars) }
    public func statusBar(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().statusBars) }
    public func statusBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().statusBars) }

    public func statusItem() -> UiElement { UiElement(XCUIApplication().statusItems) }
    public func statusItem(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().statusItems) }
    public func statusItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().statusItems) }

    public func stepper() -> UiElement { UiElement(XCUIApplication().steppers) }
    public func stepper(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().steppers) }
    public func stepper(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().steppers) }

    public func swittch() -> UiElement { UiElement(XCUIApplication().switches) }
    public func swittch(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().switches) }
    public func swittch(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().switches) }

    public func tab() -> UiElement { UiElement(XCUIApplication().tabs) }
    public func tab(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().tabs) }
    public func tab(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().tabs) }

    public func tabBar() -> UiElement { UiElement(XCUIApplication().tabBars) }
    public func tabBar(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().tabBars) }
    public func tabBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().tabBars) }

    public func tabGroup() -> UiElement { UiElement(XCUIApplication().tabGroups) }
    public func tabGroup(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().tabGroups) }
    public func tabGroup(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().tabGroups) }

    public func table() -> UiElement { UiElement(XCUIApplication().tables) }
    public func table(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().tables) }
    public func table(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().tables) }

    public func tableColumn() -> UiElement { UiElement(XCUIApplication().tableColumns) }
    public func tableColumn(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().tableColumns) }
    public func tableColumn(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().tableColumns) }

    public func tableRow() -> UiElement { UiElement(XCUIApplication().tableRows) }
    public func tableRow(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().tableRows) }
    public func tableRow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().tableRows) }

    public func textField() -> UiElement { UiElement(XCUIApplication().textFields) }
    public func textField(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().textFields) }
    public func textField(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().textFields) }

    public func textView() -> UiElement { UiElement(XCUIApplication().textViews) }
    public func textView(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().textViews) }
    public func textView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().textViews) }

    public func timeline() -> UiElement { UiElement(XCUIApplication().timelines) }
    public func timeline(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().timelines) }
    public func timeline(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().timelines) }

    public func toggle() -> UiElement { UiElement(XCUIApplication().toggles) }
    public func toggle(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().toggles) }
    public func toggle(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().toggles) }

    public func toolbarButton() -> UiElement { UiElement(XCUIApplication().toolbarButtons) }
    public func toolbarButton(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().toolbarButtons) }
    public func toolbarButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().toolbarButtons) }

    public func toolbar() -> UiElement { UiElement(XCUIApplication().toolbars) }
    public func toolbar(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().toolbars) }
    public func toolbar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().toolbars) }

    public func touchBar() -> UiElement { UiElement(XCUIApplication().touchBars) }
    public func touchBar(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().touchBars) }
    public func touchBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().touchBars) }

    public func valueIndicator() -> UiElement { UiElement(XCUIApplication().valueIndicators) }
    public func valueIndicator(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().valueIndicators) }
    public func valueIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().valueIndicators) }

    public func webView() -> UiElement { UiElement(XCUIApplication().webViews) }
    public func webView(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().webViews) }
    public func webView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().webViews) }

    public func windows() -> UiElement { UiElement(XCUIApplication().windows) }
    public func windows(_ identifier: String) -> UiElement { UiElement(identifier, XCUIApplication().windows) }
    public func windows(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, XCUIApplication().windows) }
}
