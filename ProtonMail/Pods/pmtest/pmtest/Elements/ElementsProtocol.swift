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

private var app: XCUIApplication = XCUIApplication()

/**
 * Collection of all XCUIElement types that can be used in UI testing.
 */
public protocol ElementsProtocol {}

public extension ElementsProtocol {

    private func getApp(bundleIdentifier: String? = nil) -> XCUIApplication {
        if let bundleIdentifier = bundleIdentifier {
            app = XCUIApplication(bundleIdentifier: bundleIdentifier)
        } else {
            app = XCUIApplication()
        }
        return app
    }

    /**
     UiDevice instance which can be used to invoke device functions.
     */
    func device() -> UiDevice {
        return UiDevice()
    }

    /**
     Specify which bundle to use when locating the element.
     */
    func inBundleIdentifier(_ bundleIdentifier: String? = nil) -> ElementsProtocol {
        app = getApp(bundleIdentifier: bundleIdentifier)
        return self
    }

    func acttivityIndicator() -> UiElement { UiElement(getApp().activityIndicators) }
    func acttivityIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().activityIndicators) }
    func activityIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().activityIndicators) }

    func alert() -> UiElement { UiElement(getApp().alerts) }
    func alert(_ identifier: String) -> UiElement { UiElement(identifier, getApp().alerts) }
    func alert(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().alerts) }

    func browser() -> UiElement { UiElement(getApp().browsers) }
    func browser(_ identifier: String) -> UiElement { UiElement(identifier, getApp().browsers) }
    func browser(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().browsers) }

    func button() -> UiElement { UiElement(getApp().buttons) }
    func button(_ identifier: String) -> UiElement { UiElement(identifier, getApp().buttons) }
    func button(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().buttons) }

    func cell() -> UiElement { UiElement(getApp().cells) }
    func cell(_ identifier: String) -> UiElement { UiElement(identifier, getApp().cells) }
    func cell(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().cells) }

    func checkBox() -> UiElement { UiElement(getApp().checkBoxes) }
    func checkBox(_ identifier: String) -> UiElement { UiElement(identifier, getApp().checkBoxes) }
    func checkBox(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().checkBoxes) }

    func collectionView() -> UiElement { UiElement(getApp().collectionViews) }
    func collectionView(_ identifier: String) -> UiElement { UiElement(identifier, getApp().collectionViews) }
    func collectionView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().collectionViews) }

    func colorWell() -> UiElement { UiElement(getApp().colorWells) }
    func colorWell(_ identifier: String) -> UiElement { UiElement(identifier, getApp().colorWells) }
    func colorWell(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().colorWells) }

    func comboBox() -> UiElement { UiElement(getApp().comboBoxes) }
    func comboBox(_ identifier: String) -> UiElement { UiElement(identifier, getApp().comboBoxes) }
    func comboBox(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().comboBoxes) }

    func datePicker() -> UiElement { UiElement(getApp().datePickers) }
    func datePicker(_ identifier: String) -> UiElement { UiElement(identifier, getApp().datePickers) }
    func datePicker(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().datePickers) }

    func decrementArrow() -> UiElement { UiElement(getApp().decrementArrows) }
    func decrementArrow(_ identifier: String) -> UiElement { UiElement(identifier, getApp().decrementArrows) }
    func decrementArrow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().decrementArrows) }

    func dialog() -> UiElement { UiElement(getApp().dialogs) }
    func dialog(_ identifier: String) -> UiElement { UiElement(identifier, getApp().dialogs) }
    func dialog(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().dialogs) }

    func disclosedChildRow() -> UiElement { UiElement(getApp().disclosedChildRows) }
    func disclosedChildRow(_ identifier: String) -> UiElement { UiElement(identifier, getApp().disclosedChildRows) }
    func disclosedChildRow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().disclosedChildRows) }

    func disclosureTriangle() -> UiElement { UiElement(getApp().disclosureTriangles) }
    func disclosureTriangle(_ identifier: String) -> UiElement { UiElement(identifier, getApp().disclosureTriangles) }
    func disclosureTriangle(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().disclosureTriangles) }

    func dockItem() -> UiElement { UiElement(getApp().dockItems) }
    func dockItem(_ identifier: String) -> UiElement { UiElement(identifier, getApp().dockItems) }
    func dockItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().dockItems) }

    func drawer() -> UiElement { UiElement(getApp().drawers) }
    func drawer(_ identifier: String) -> UiElement { UiElement(identifier, getApp().drawers) }
    func drawer(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().drawers) }

    func grid() -> UiElement { UiElement(getApp().grids) }
    func grid(_ identifier: String) -> UiElement { UiElement(identifier, getApp().grids) }
    func grid(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().grids) }

    func group() -> UiElement { UiElement(getApp().groups) }
    func group(_ identifier: String) -> UiElement { UiElement(identifier, getApp().groups) }
    func group(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().groups) }

    func handle() -> UiElement { UiElement(getApp().handles) }
    func handle(_ identifier: String) -> UiElement { UiElement(identifier, getApp().handles) }
    func handle(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().handles) }

    func helpTag() -> UiElement { UiElement(getApp().helpTags) }
    func helpTag(_ identifier: String) -> UiElement { UiElement(identifier, getApp().helpTags) }
    func helpTag(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().helpTags) }

    func icon() -> UiElement { UiElement(getApp().icons) }
    func icon(_ identifier: String) -> UiElement { UiElement(identifier, getApp().icons) }
    func icon(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().icons) }

    func image() -> UiElement { UiElement(getApp().images) }
    func image(_ identifier: String) -> UiElement { UiElement(identifier, getApp().images) }
    func image(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().images) }

    func incrementArrow() -> UiElement { UiElement(getApp().incrementArrows) }
    func incrementArrow(_ identifier: String) -> UiElement { UiElement(identifier, getApp().incrementArrows) }
    func incrementArrow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().incrementArrows) }

    func keyboard() -> UiElement { UiElement(getApp().keyboards) }
    func keyboard(_ identifier: String) -> UiElement { UiElement(identifier, getApp().keyboards) }
    func keyboard(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().keyboards) }

    func key() -> UiElement { UiElement(getApp().keys) }
    func key(_ identifier: String) -> UiElement { UiElement(identifier, getApp().keys) }
    func key(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().keys) }

    func layoutArea() -> UiElement { UiElement(getApp().layoutAreas) }
    func layoutArea(_ identifier: String) -> UiElement { UiElement(identifier, getApp().layoutAreas) }
    func layoutArea(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().layoutAreas) }

    func layoutItem() -> UiElement { UiElement(getApp().layoutItems) }
    func layoutItem(_ identifier: String) -> UiElement { UiElement(identifier, getApp().layoutItems) }
    func layoutItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().layoutItems) }

    func levelIndicator() -> UiElement { UiElement(getApp().levelIndicators) }
    func levelIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().levelIndicators) }
    func levelIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().levelIndicators) }

    func link() -> UiElement { UiElement(getApp().links) }
    func link(_ identifier: String) -> UiElement { UiElement(identifier, getApp().links) }
    func link(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().links) }

    func map() -> UiElement { UiElement(getApp().maps) }
    func map(_ identifier: String) -> UiElement { UiElement(identifier, getApp().maps) }
    func map(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().maps) }

    func matte() -> UiElement { UiElement(getApp().mattes) }
    func matte(_ identifier: String) -> UiElement { UiElement(identifier, getApp().mattes) }
    func matte(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().mattes) }

    func menuBar() -> UiElement { UiElement(getApp().menuBars) }
    func menuBar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().menuBars) }
    func menuBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().menuBars) }

    func menuBarItem() -> UiElement { UiElement(getApp().menuBarItems) }
    func menuBarItem(_ identifier: String) -> UiElement { UiElement(identifier, getApp().menuBarItems) }
    func menuBarItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().menuBarItems) }

    func menuButton() -> UiElement { UiElement(getApp().menuButtons) }
    func menuButton(_ identifier: String) -> UiElement { UiElement(identifier, getApp().menuButtons) }
    func menuButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().menuButtons) }

    func menuItem() -> UiElement { UiElement(getApp().menuItems) }
    func menuItem(_ identifier: String) -> UiElement { UiElement(identifier, getApp().menuItems) }
    func menuItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().menuItems) }

    func menu() -> UiElement { UiElement(getApp().menus) }
    func menu(_ identifier: String) -> UiElement { UiElement(identifier, getApp().menus) }
    func menu(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().menus) }

    func navigationBar() -> UiElement { UiElement(getApp().navigationBars) }
    func navigationBar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().navigationBars) }
    func navigationBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().navigationBars) }

    func otherElement() -> UiElement { UiElement(getApp().otherElements) }
    func otherElement(_ identifier: String) -> UiElement { UiElement(identifier, getApp().otherElements) }
    func otherElement(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().otherElements) }

    func outline() -> UiElement { UiElement(getApp().outlines) }
    func outline(_ identifier: String) -> UiElement { UiElement(identifier, getApp().outlines) }
    func outline(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().outlines) }

    func outlineRow() -> UiElement { UiElement(getApp().outlineRows) }
    func outlineRow(_ identifier: String) -> UiElement { UiElement(identifier, getApp().outlineRows) }
    func outlineRow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().outlineRows) }

    func pageIndicator() -> UiElement { UiElement(getApp().pageIndicators) }
    func pageIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().pageIndicators) }
    func pageIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().pageIndicators) }

    func picker() -> UiElement { UiElement(getApp().pickers) }
    func picker(_ identifier: String) -> UiElement { UiElement(identifier, getApp().pickers) }
    func picker(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().pickers) }

    func pickerWheel() -> UiElement { UiElement(getApp().pickerWheels) }
    func pickerWheel(_ identifier: String) -> UiElement { UiElement(identifier, getApp().pickerWheels) }
    func pickerWheel(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().pickerWheels) }

    func popover() -> UiElement { UiElement(getApp().popovers) }
    func popover(_ identifier: String) -> UiElement { UiElement(identifier, getApp().popovers) }
    func popover(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().popovers) }

    func popUpButton() -> UiElement { UiElement(getApp().popUpButtons) }
    func popUpButton(_ identifier: String) -> UiElement { UiElement(identifier, getApp().popUpButtons) }
    func popUpButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().popUpButtons) }

    func progressIndicator() -> UiElement { UiElement(getApp().progressIndicators) }
    func progressIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().progressIndicators) }
    func progressIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().progressIndicators) }

    func radioButton() -> UiElement { UiElement(getApp().radioButtons) }
    func radioButton(_ identifier: String) -> UiElement { UiElement(identifier, getApp().radioButtons) }
    func radioButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().radioButtons) }

    func radioGroup() -> UiElement { UiElement(getApp().radioGroups) }
    func radioGroup(_ identifier: String) -> UiElement { UiElement(identifier, getApp().radioGroups) }
    func radioGroup(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().radioGroups) }

    func ratingIndicator() -> UiElement { UiElement(getApp().ratingIndicators) }
    func ratingIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().ratingIndicators) }
    func ratingIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().ratingIndicators) }

    func relevanceIndicator() -> UiElement { UiElement(getApp().relevanceIndicators) }
    func relevanceIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().relevanceIndicators) }
    func relevanceIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().relevanceIndicators) }

    func rulerMarker() -> UiElement { UiElement(getApp().rulerMarkers) }
    func rulerMarker(_ identifier: String) -> UiElement { UiElement(identifier, getApp().rulerMarkers) }
    func rulerMarker(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().rulerMarkers) }

    func ruler() -> UiElement { UiElement(getApp().rulers) }
    func ruler(_ identifier: String) -> UiElement { UiElement(identifier, getApp().rulers) }
    func ruler(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().rulers) }

    func scrollBar() -> UiElement { UiElement(getApp().scrollBars) }
    func scrollBar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().scrollBars) }
    func scrollBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().scrollBars) }

    func scrollView() -> UiElement { UiElement(getApp().scrollViews) }
    func scrollView(_ identifier: String) -> UiElement { UiElement(identifier, getApp().scrollViews) }
    func scrollView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().scrollViews) }

    func searchField() -> UiElement { UiElement(getApp().searchFields) }
    func searchField(_ identifier: String) -> UiElement { UiElement(identifier, getApp().searchFields) }
    func searchField(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().searchFields) }

    func secureTextField() -> UiElement { UiElement(getApp().secureTextFields) }
    func secureTextField(_ identifier: String) -> UiElement { UiElement(identifier, getApp().secureTextFields) }
    func secureTextField(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().secureTextFields) }

    func segmentedControl() -> UiElement { UiElement(getApp().segmentedControls) }
    func segmentedControl(_ identifier: String) -> UiElement { UiElement(identifier, getApp().segmentedControls) }
    func segmentedControl(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().segmentedControls) }

    func sheet() -> UiElement { UiElement(getApp().sheets) }
    func sheet(_ identifier: String) -> UiElement { UiElement(identifier, getApp().sheets) }
    func sheet(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().sheets) }

    func slider() -> UiElement { UiElement(getApp().sliders) }
    func slider(_ identifier: String) -> UiElement { UiElement(identifier, getApp().sliders) }
    func slider(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().sliders) }

    func splitGroup() -> UiElement { UiElement(getApp().splitGroups) }
    func splitGroup(_ identifier: String) -> UiElement { UiElement(identifier, getApp().splitGroups) }
    func splitGroup(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().splitGroups) }

    func splitter() -> UiElement { UiElement(getApp().splitters) }
    func splitter(_ identifier: String) -> UiElement { UiElement(identifier, getApp().splitters) }
    func splitter(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().splitters) }

    func staticText() -> UiElement { UiElement(getApp().staticTexts) }
    func staticText(_ identifier: String) -> UiElement { UiElement(identifier, getApp().staticTexts) }
    func staticText(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().staticTexts) }

    func statusBar() -> UiElement { UiElement(getApp().statusBars) }
    func statusBar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().statusBars) }
    func statusBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().statusBars) }

    func statusItem() -> UiElement { UiElement(getApp().statusItems) }
    func statusItem(_ identifier: String) -> UiElement { UiElement(identifier, getApp().statusItems) }
    func statusItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().statusItems) }

    func stepper() -> UiElement { UiElement(getApp().steppers) }
    func stepper(_ identifier: String) -> UiElement { UiElement(identifier, getApp().steppers) }
    func stepper(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().steppers) }

    func swittch() -> UiElement { UiElement(getApp().switches) }
    func swittch(_ identifier: String) -> UiElement { UiElement(identifier, getApp().switches) }
    func swittch(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().switches) }

    func tab() -> UiElement { UiElement(getApp().tabs) }
    func tab(_ identifier: String) -> UiElement { UiElement(identifier, getApp().tabs) }
    func tab(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().tabs) }

    func tabBar() -> UiElement { UiElement(getApp().tabBars) }
    func tabBar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().tabBars) }
    func tabBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().tabBars) }

    func tabGroup() -> UiElement { UiElement(getApp().tabGroups) }
    func tabGroup(_ identifier: String) -> UiElement { UiElement(identifier, getApp().tabGroups) }
    func tabGroup(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().tabGroups) }

    func table() -> UiElement { UiElement(getApp().tables) }
    func table(_ identifier: String) -> UiElement { UiElement(identifier, getApp().tables) }
    func table(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().tables) }

    func tableColumn() -> UiElement { UiElement(getApp().tableColumns) }
    func tableColumn(_ identifier: String) -> UiElement { UiElement(identifier, getApp().tableColumns) }
    func tableColumn(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().tableColumns) }

    func tableRow() -> UiElement { UiElement(getApp().tableRows) }
    func tableRow(_ identifier: String) -> UiElement { UiElement(identifier, getApp().tableRows) }
    func tableRow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().tableRows) }

    func textField() -> UiElement { UiElement(getApp().textFields) }
    func textField(_ identifier: String) -> UiElement { UiElement(identifier, getApp().textFields) }
    func textField(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().textFields) }

    func textView() -> UiElement { UiElement(getApp().textViews) }
    func textView(_ identifier: String) -> UiElement { UiElement(identifier, getApp().textViews) }
    func textView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().textViews) }

    func timeline() -> UiElement { UiElement(getApp().timelines) }
    func timeline(_ identifier: String) -> UiElement { UiElement(identifier, getApp().timelines) }
    func timeline(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().timelines) }

    func toggle() -> UiElement { UiElement(getApp().toggles) }
    func toggle(_ identifier: String) -> UiElement { UiElement(identifier, getApp().toggles) }
    func toggle(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().toggles) }

    func toolbarButton() -> UiElement { UiElement(getApp().toolbarButtons) }
    func toolbarButton(_ identifier: String) -> UiElement { UiElement(identifier, getApp().toolbarButtons) }
    func toolbarButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().toolbarButtons) }

    func toolbar() -> UiElement { UiElement(getApp().toolbars) }
    func toolbar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().toolbars) }
    func toolbar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().toolbars) }

    func touchBar() -> UiElement { UiElement(getApp().touchBars) }
    func touchBar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().touchBars) }
    func touchBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().touchBars) }

    func valueIndicator() -> UiElement { UiElement(getApp().valueIndicators) }
    func valueIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().valueIndicators) }
    func valueIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().valueIndicators) }

    func webView() -> UiElement { UiElement(getApp().webViews) }
    func webView(_ identifier: String) -> UiElement { UiElement(identifier, getApp().webViews) }
    func webView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().webViews) }

    func windows() -> UiElement { UiElement(getApp().windows) }
    func windows(_ identifier: String) -> UiElement { UiElement(identifier, getApp().windows) }
    func windows(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().windows) }
}
