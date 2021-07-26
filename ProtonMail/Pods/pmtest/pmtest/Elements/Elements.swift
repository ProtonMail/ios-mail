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
    
    private var app: XCUIApplication = XCUIApplication()
    
    public init() {}
    
    public init(bundleIdentifier: String? = nil) {
        if let bundleIdentifier = bundleIdentifier {
            self.app = XCUIApplication(bundleIdentifier: bundleIdentifier)
        } else {
            self.app = XCUIApplication()
        }
    }

    public func acttivityIndicator() -> UiElement { UiElement(app.activityIndicators) }
    public func acttivityIndicator(_ identifier: String) -> UiElement { UiElement(identifier, app.activityIndicators) }
    public func activityIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.activityIndicators) }

    public func alert() -> UiElement { UiElement(app.alerts) }
    public func alert(_ identifier: String) -> UiElement { UiElement(identifier, app.alerts) }
    public func alert(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.alerts) }

    public func browser() -> UiElement { UiElement(app.browsers) }
    public func browser(_ identifier: String) -> UiElement { UiElement(identifier, app.browsers) }
    public func browser(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.browsers) }

    public func button() -> UiElement { UiElement(app.buttons) }
    public func button(_ identifier: String) -> UiElement { UiElement(identifier, app.buttons) }
    public func button(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.buttons) }

    public func cell() -> UiElement { UiElement(app.cells) }
    public func cell(_ identifier: String) -> UiElement { UiElement(identifier, app.cells) }
    public func cell(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.cells) }

    public func checkBox() -> UiElement { UiElement(app.checkBoxes) }
    public func checkBox(_ identifier: String) -> UiElement { UiElement(identifier, app.checkBoxes) }
    public func checkBox(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.checkBoxes) }

    public func collectionView() -> UiElement { UiElement(app.collectionViews) }
    public func collectionView(_ identifier: String) -> UiElement { UiElement(identifier, app.collectionViews) }
    public func collectionView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.collectionViews) }

    public func colorWell() -> UiElement { UiElement(app.colorWells) }
    public func colorWell(_ identifier: String) -> UiElement { UiElement(identifier, app.colorWells) }
    public func colorWell(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.colorWells) }

    public func comboBox() -> UiElement { UiElement(app.comboBoxes) }
    public func comboBox(_ identifier: String) -> UiElement { UiElement(identifier, app.comboBoxes) }
    public func comboBox(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.comboBoxes) }

    public func datePicker() -> UiElement { UiElement(app.datePickers) }
    public func datePicker(_ identifier: String) -> UiElement { UiElement(identifier, app.datePickers) }
    public func datePicker(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.datePickers) }

    public func decrementArrow() -> UiElement { UiElement(app.decrementArrows) }
    public func decrementArrow(_ identifier: String) -> UiElement { UiElement(identifier, app.decrementArrows) }
    public func decrementArrow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.decrementArrows) }

    public func dialog() -> UiElement { UiElement(app.dialogs) }
    public func dialog(_ identifier: String) -> UiElement { UiElement(identifier, app.dialogs) }
    public func dialog(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.dialogs) }

    public func disclosedChildRow() -> UiElement { UiElement(app.disclosedChildRows) }
    public func disclosedChildRow(_ identifier: String) -> UiElement { UiElement(identifier, app.disclosedChildRows) }
    public func disclosedChildRow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.disclosedChildRows) }

    public func disclosureTriangle() -> UiElement { UiElement(app.disclosureTriangles) }
    public func disclosureTriangle(_ identifier: String) -> UiElement { UiElement(identifier, app.disclosureTriangles) }
    public func disclosureTriangle(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.disclosureTriangles) }

    public func dockItem() -> UiElement { UiElement(app.dockItems) }
    public func dockItem(_ identifier: String) -> UiElement { UiElement(identifier, app.dockItems) }
    public func dockItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.dockItems) }

    public func drawer() -> UiElement { UiElement(app.drawers) }
    public func drawer(_ identifier: String) -> UiElement { UiElement(identifier, app.drawers) }
    public func drawer(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.drawers) }

    public func grid() -> UiElement { UiElement(app.grids) }
    public func grid(_ identifier: String) -> UiElement { UiElement(identifier, app.grids) }
    public func grid(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.grids) }

    public func group() -> UiElement { UiElement(app.groups) }
    public func group(_ identifier: String) -> UiElement { UiElement(identifier, app.groups) }
    public func group(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.groups) }

    public func handle() -> UiElement { UiElement(app.handles) }
    public func handle(_ identifier: String) -> UiElement { UiElement(identifier, app.handles) }
    public func handle(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.handles) }

    public func helpTag() -> UiElement { UiElement(app.helpTags) }
    public func helpTag(_ identifier: String) -> UiElement { UiElement(identifier, app.helpTags) }
    public func helpTag(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.helpTags) }

    public func icon() -> UiElement { UiElement(app.icons) }
    public func icon(_ identifier: String) -> UiElement { UiElement(identifier, app.icons) }
    public func icon(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.icons) }

    public func image() -> UiElement { UiElement(app.images) }
    public func image(_ identifier: String) -> UiElement { UiElement(identifier, app.images) }
    public func image(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.images) }

    public func incrementArrow() -> UiElement { UiElement(app.incrementArrows) }
    public func incrementArrow(_ identifier: String) -> UiElement { UiElement(identifier, app.incrementArrows) }
    public func incrementArrow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.incrementArrows) }

    public func keyboard() -> UiElement { UiElement(app.keyboards) }
    public func keyboard(_ identifier: String) -> UiElement { UiElement(identifier, app.keyboards) }
    public func keyboard(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.keyboards) }

    public func key() -> UiElement { UiElement(app.keys) }
    public func key(_ identifier: String) -> UiElement { UiElement(identifier, app.keys) }
    public func key(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.keys) }

    public func layoutArea() -> UiElement { UiElement(app.layoutAreas) }
    public func layoutArea(_ identifier: String) -> UiElement { UiElement(identifier, app.layoutAreas) }
    public func layoutArea(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.layoutAreas) }

    public func layoutItem() -> UiElement { UiElement(app.layoutItems) }
    public func layoutItem(_ identifier: String) -> UiElement { UiElement(identifier, app.layoutItems) }
    public func layoutItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.layoutItems) }

    public func levelIndicator() -> UiElement { UiElement(app.levelIndicators) }
    public func levelIndicator(_ identifier: String) -> UiElement { UiElement(identifier, app.levelIndicators) }
    public func levelIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.levelIndicators) }

    public func link() -> UiElement { UiElement(app.links) }
    public func link(_ identifier: String) -> UiElement { UiElement(identifier, app.links) }
    public func link(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.links) }

    public func map() -> UiElement { UiElement(app.maps) }
    public func map(_ identifier: String) -> UiElement { UiElement(identifier, app.maps) }
    public func map(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.maps) }

    public func matte() -> UiElement { UiElement(app.mattes) }
    public func matte(_ identifier: String) -> UiElement { UiElement(identifier, app.mattes) }
    public func matte(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.mattes) }

    public func menuBar() -> UiElement { UiElement(app.menuBars) }
    public func menuBar(_ identifier: String) -> UiElement { UiElement(identifier, app.menuBars) }
    public func menuBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.menuBars) }

    public func menuBarItem() -> UiElement { UiElement(app.menuBarItems) }
    public func menuBarItem(_ identifier: String) -> UiElement { UiElement(identifier, app.menuBarItems) }
    public func menuBarItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.menuBarItems) }

    public func menuButton() -> UiElement { UiElement(app.menuButtons) }
    public func menuButton(_ identifier: String) -> UiElement { UiElement(identifier, app.menuButtons) }
    public func menuButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.menuButtons) }

    public func menuItem() -> UiElement { UiElement(app.menuItems) }
    public func menuItem(_ identifier: String) -> UiElement { UiElement(identifier, app.menuItems) }
    public func menuItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.menuItems) }

    public func menu() -> UiElement { UiElement(app.menus) }
    public func menu(_ identifier: String) -> UiElement { UiElement(identifier, app.menus) }
    public func menu(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.menus) }

    public func navigationBar() -> UiElement { UiElement(app.navigationBars) }
    public func navigationBar(_ identifier: String) -> UiElement { UiElement(identifier, app.navigationBars) }
    public func navigationBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.navigationBars) }

    public func otherElement() -> UiElement { UiElement(app.otherElements) }
    public func otherElement(_ identifier: String) -> UiElement { UiElement(identifier, app.otherElements) }
    public func otherElement(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.otherElements) }

    public func outline() -> UiElement { UiElement(app.outlines) }
    public func outline(_ identifier: String) -> UiElement { UiElement(identifier, app.outlines) }
    public func outline(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.outlines) }

    public func outlineRow() -> UiElement { UiElement(app.outlineRows) }
    public func outlineRow(_ identifier: String) -> UiElement { UiElement(identifier, app.outlineRows) }
    public func outlineRow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.outlineRows) }

    public func pageIndicator() -> UiElement { UiElement(app.pageIndicators) }
    public func pageIndicator(_ identifier: String) -> UiElement { UiElement(identifier, app.pageIndicators) }
    public func pageIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.pageIndicators) }

    public func picker() -> UiElement { UiElement(app.pickers) }
    public func picker(_ identifier: String) -> UiElement { UiElement(identifier, app.pickers) }
    public func picker(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.pickers) }

    public func pickerWheel() -> UiElement { UiElement(app.pickerWheels) }
    public func pickerWheel(_ identifier: String) -> UiElement { UiElement(identifier, app.pickerWheels) }
    public func pickerWheel(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.pickerWheels) }

    public func popover() -> UiElement { UiElement(app.popovers) }
    public func popover(_ identifier: String) -> UiElement { UiElement(identifier, app.popovers) }
    public func popover(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.popovers) }

    public func popUpButton() -> UiElement { UiElement(app.popUpButtons) }
    public func popUpButton(_ identifier: String) -> UiElement { UiElement(identifier, app.popUpButtons) }
    public func popUpButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.popUpButtons) }

    public func progressIndicator() -> UiElement { UiElement(app.progressIndicators) }
    public func progressIndicator(_ identifier: String) -> UiElement { UiElement(identifier, app.progressIndicators) }
    public func progressIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.progressIndicators) }

    public func radioButton() -> UiElement { UiElement(app.radioButtons) }
    public func radioButton(_ identifier: String) -> UiElement { UiElement(identifier, app.radioButtons) }
    public func radioButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.radioButtons) }

    public func radioGroup() -> UiElement { UiElement(app.radioGroups) }
    public func radioGroup(_ identifier: String) -> UiElement { UiElement(identifier, app.radioGroups) }
    public func radioGroup(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.radioGroups) }

    public func ratingIndicator() -> UiElement { UiElement(app.ratingIndicators) }
    public func ratingIndicator(_ identifier: String) -> UiElement { UiElement(identifier, app.ratingIndicators) }
    public func ratingIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.ratingIndicators) }

    public func relevanceIndicator() -> UiElement { UiElement(app.relevanceIndicators) }
    public func relevanceIndicator(_ identifier: String) -> UiElement { UiElement(identifier, app.relevanceIndicators) }
    public func relevanceIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.relevanceIndicators) }

    public func rulerMarker() -> UiElement { UiElement(app.rulerMarkers) }
    public func rulerMarker(_ identifier: String) -> UiElement { UiElement(identifier, app.rulerMarkers) }
    public func rulerMarker(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.rulerMarkers) }

    public func ruler() -> UiElement { UiElement(app.rulers) }
    public func ruler(_ identifier: String) -> UiElement { UiElement(identifier, app.rulers) }
    public func ruler(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.rulers) }

    public func scrollBar() -> UiElement { UiElement(app.scrollBars) }
    public func scrollBar(_ identifier: String) -> UiElement { UiElement(identifier, app.scrollBars) }
    public func scrollBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.scrollBars) }

    public func scrollView() -> UiElement { UiElement(app.scrollViews) }
    public func scrollView(_ identifier: String) -> UiElement { UiElement(identifier, app.scrollViews) }
    public func scrollView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.scrollViews) }

    public func searchField() -> UiElement { UiElement(app.searchFields) }
    public func searchField(_ identifier: String) -> UiElement { UiElement(identifier, app.searchFields) }
    public func searchField(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.searchFields) }

    public func secureTextField() -> UiElement { UiElement(app.secureTextFields) }
    public func secureTextField(_ identifier: String) -> UiElement { UiElement(identifier, app.secureTextFields) }
    public func secureTextField(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.secureTextFields) }

    public func segmentedControl() -> UiElement { UiElement(app.segmentedControls) }
    public func segmentedControl(_ identifier: String) -> UiElement { UiElement(identifier, app.segmentedControls) }
    public func segmentedControl(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.segmentedControls) }

    public func sheet() -> UiElement { UiElement(app.sheets) }
    public func sheet(_ identifier: String) -> UiElement { UiElement(identifier, app.sheets) }
    public func sheet(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.sheets) }

    public func slider() -> UiElement { UiElement(app.sliders) }
    public func slider(_ identifier: String) -> UiElement { UiElement(identifier, app.sliders) }
    public func slider(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.sliders) }

    public func splitGroup() -> UiElement { UiElement(app.splitGroups) }
    public func splitGroup(_ identifier: String) -> UiElement { UiElement(identifier, app.splitGroups) }
    public func splitGroup(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.splitGroups) }

    public func splitter() -> UiElement { UiElement(app.splitters) }
    public func splitter(_ identifier: String) -> UiElement { UiElement(identifier, app.splitters) }
    public func splitter(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.splitters) }

    public func staticText() -> UiElement { UiElement(app.staticTexts) }
    public func staticText(_ identifier: String) -> UiElement { UiElement(identifier, app.staticTexts) }
    public func staticText(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.staticTexts) }

    public func statusBar() -> UiElement { UiElement(app.statusBars) }
    public func statusBar(_ identifier: String) -> UiElement { UiElement(identifier, app.statusBars) }
    public func statusBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.statusBars) }

    public func statusItem() -> UiElement { UiElement(app.statusItems) }
    public func statusItem(_ identifier: String) -> UiElement { UiElement(identifier, app.statusItems) }
    public func statusItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.statusItems) }

    public func stepper() -> UiElement { UiElement(app.steppers) }
    public func stepper(_ identifier: String) -> UiElement { UiElement(identifier, app.steppers) }
    public func stepper(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.steppers) }

    public func swittch() -> UiElement { UiElement(app.switches) }
    public func swittch(_ identifier: String) -> UiElement { UiElement(identifier, app.switches) }
    public func swittch(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.switches) }

    public func tab() -> UiElement { UiElement(app.tabs) }
    public func tab(_ identifier: String) -> UiElement { UiElement(identifier, app.tabs) }
    public func tab(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.tabs) }

    public func tabBar() -> UiElement { UiElement(app.tabBars) }
    public func tabBar(_ identifier: String) -> UiElement { UiElement(identifier, app.tabBars) }
    public func tabBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.tabBars) }

    public func tabGroup() -> UiElement { UiElement(app.tabGroups) }
    public func tabGroup(_ identifier: String) -> UiElement { UiElement(identifier, app.tabGroups) }
    public func tabGroup(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.tabGroups) }

    public func table() -> UiElement { UiElement(app.tables) }
    public func table(_ identifier: String) -> UiElement { UiElement(identifier, app.tables) }
    public func table(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.tables) }

    public func tableColumn() -> UiElement { UiElement(app.tableColumns) }
    public func tableColumn(_ identifier: String) -> UiElement { UiElement(identifier, app.tableColumns) }
    public func tableColumn(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.tableColumns) }

    public func tableRow() -> UiElement { UiElement(app.tableRows) }
    public func tableRow(_ identifier: String) -> UiElement { UiElement(identifier, app.tableRows) }
    public func tableRow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.tableRows) }

    public func textField() -> UiElement { UiElement(app.textFields) }
    public func textField(_ identifier: String) -> UiElement { UiElement(identifier, app.textFields) }
    public func textField(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.textFields) }

    public func textView() -> UiElement { UiElement(app.textViews) }
    public func textView(_ identifier: String) -> UiElement { UiElement(identifier, app.textViews) }
    public func textView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.textViews) }

    public func timeline() -> UiElement { UiElement(app.timelines) }
    public func timeline(_ identifier: String) -> UiElement { UiElement(identifier, app.timelines) }
    public func timeline(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.timelines) }

    public func toggle() -> UiElement { UiElement(app.toggles) }
    public func toggle(_ identifier: String) -> UiElement { UiElement(identifier, app.toggles) }
    public func toggle(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.toggles) }

    public func toolbarButton() -> UiElement { UiElement(app.toolbarButtons) }
    public func toolbarButton(_ identifier: String) -> UiElement { UiElement(identifier, app.toolbarButtons) }
    public func toolbarButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.toolbarButtons) }

    public func toolbar() -> UiElement { UiElement(app.toolbars) }
    public func toolbar(_ identifier: String) -> UiElement { UiElement(identifier, app.toolbars) }
    public func toolbar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.toolbars) }

    public func touchBar() -> UiElement { UiElement(app.touchBars) }
    public func touchBar(_ identifier: String) -> UiElement { UiElement(identifier, app.touchBars) }
    public func touchBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.touchBars) }

    public func valueIndicator() -> UiElement { UiElement(app.valueIndicators) }
    public func valueIndicator(_ identifier: String) -> UiElement { UiElement(identifier, app.valueIndicators) }
    public func valueIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.valueIndicators) }

    public func webView() -> UiElement { UiElement(app.webViews) }
    public func webView(_ identifier: String) -> UiElement { UiElement(identifier, app.webViews) }
    public func webView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.webViews) }

    public func windows() -> UiElement { UiElement(app.windows) }
    public func windows(_ identifier: String) -> UiElement { UiElement(identifier, app.windows) }
    public func windows(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, app.windows) }
}
