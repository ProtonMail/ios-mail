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

var currentApp: XCUIApplication?

/**
 * Collection of all XCUIElement types that can be used in UI testing.
 */
public protocol ElementsProtocol: AnyObject {
    var app: XCUIApplication { get }
}

public extension ElementsProtocol {

    var app: XCUIApplication {
        if let app = currentApp {
            return app
        } else {
            currentApp = XCUIApplication()
            return currentApp!
        }
    }

    /**
     Specify which bundle to use when locating the element.
     */
    func inBundleIdentifier(_ bundleIdentifier: String) -> ElementsProtocol {
        currentApp = XCUIApplication(bundleIdentifier: bundleIdentifier)
        return self
    }

    func activityIndicator() -> UIElement { UIElement(app.activityIndicators, XCUIElement.ElementType.activityIndicator) }
    func activityIndicator(_ identifier: String) -> UIElement { UIElement(identifier, app.activityIndicators, XCUIElement.ElementType.activityIndicator) }
    func activityIndicator(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.activityIndicators, XCUIElement.ElementType.activityIndicator) }

    func alert() -> UIElement { UIElement(app.alerts, XCUIElement.ElementType.alert) }
    func alert(_ identifier: String) -> UIElement { UIElement(identifier, app.alerts, XCUIElement.ElementType.alert) }
    func alert(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.alerts, XCUIElement.ElementType.alert) }

    func browser() -> UIElement { UIElement(app.browsers, XCUIElement.ElementType.browser) }
    func browser(_ identifier: String) -> UIElement { UIElement(identifier, app.browsers, XCUIElement.ElementType.browser) }
    func browser(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.browsers, XCUIElement.ElementType.browser) }

    func button() -> UIElement { UIElement(app.buttons, XCUIElement.ElementType.button) }
    func button(_ identifier: String) -> UIElement { UIElement(identifier, app.buttons, XCUIElement.ElementType.button) }
    func button(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.buttons, XCUIElement.ElementType.button) }

    func cell() -> UIElement { UIElement(app.cells, XCUIElement.ElementType.cell) }
    func cell(_ identifier: String) -> UIElement { UIElement(identifier, app.cells, XCUIElement.ElementType.cell) }
    func cell(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.cells, XCUIElement.ElementType.cell) }

    func checkBox() -> UIElement { UIElement(app.checkBoxes, XCUIElement.ElementType.checkBox) }
    func checkBox(_ identifier: String) -> UIElement { UIElement(identifier, app.checkBoxes, XCUIElement.ElementType.checkBox) }
    func checkBox(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.checkBoxes, XCUIElement.ElementType.checkBox) }

    func collectionView() -> UIElement { UIElement(app.collectionViews, XCUIElement.ElementType.collectionView) }
    func collectionView(_ identifier: String) -> UIElement { UIElement(identifier, app.collectionViews, XCUIElement.ElementType.collectionView) }
    func collectionView(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.collectionViews, XCUIElement.ElementType.collectionView) }

    func colorWell() -> UIElement { UIElement(app.colorWells, XCUIElement.ElementType.colorWell) }
    func colorWell(_ identifier: String) -> UIElement { UIElement(identifier, app.colorWells, XCUIElement.ElementType.colorWell) }
    func colorWell(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.colorWells, XCUIElement.ElementType.colorWell) }

    func comboBox() -> UIElement { UIElement(app.comboBoxes, XCUIElement.ElementType.comboBox) }
    func comboBox(_ identifier: String) -> UIElement { UIElement(identifier, app.comboBoxes, XCUIElement.ElementType.comboBox) }
    func comboBox(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.comboBoxes, XCUIElement.ElementType.comboBox) }

    func datePicker() -> UIElement { UIElement(app.datePickers, XCUIElement.ElementType.datePicker) }
    func datePicker(_ identifier: String) -> UIElement { UIElement(identifier, app.datePickers, XCUIElement.ElementType.datePicker) }
    func datePicker(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.datePickers, XCUIElement.ElementType.datePicker) }

    func decrementArrow() -> UIElement { UIElement(app.decrementArrows, XCUIElement.ElementType.decrementArrow) }
    func decrementArrow(_ identifier: String) -> UIElement { UIElement(identifier, app.decrementArrows, XCUIElement.ElementType.decrementArrow) }
    func decrementArrow(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.decrementArrows, XCUIElement.ElementType.decrementArrow) }

    func dialog() -> UIElement { UIElement(app.dialogs, XCUIElement.ElementType.dialog) }
    func dialog(_ identifier: String) -> UIElement { UIElement(identifier, app.dialogs, XCUIElement.ElementType.dialog) }
    func dialog(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.dialogs, XCUIElement.ElementType.dialog) }

    func disclosureTriangle() -> UIElement { UIElement(app.disclosureTriangles, XCUIElement.ElementType.disclosureTriangle) }
    func disclosureTriangle(_ identifier: String) -> UIElement { UIElement(identifier, app.disclosureTriangles, XCUIElement.ElementType.disclosureTriangle) }
    func disclosureTriangle(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.disclosureTriangles, XCUIElement.ElementType.disclosureTriangle) }

    func dockItem() -> UIElement { UIElement(app.dockItems, XCUIElement.ElementType.dockItem) }
    func dockItem(_ identifier: String) -> UIElement { UIElement(identifier, app.dockItems, XCUIElement.ElementType.dockItem) }
    func dockItem(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.dockItems, XCUIElement.ElementType.dockItem) }

    func drawer() -> UIElement { UIElement(app.drawers, XCUIElement.ElementType.drawer) }
    func drawer(_ identifier: String) -> UIElement { UIElement(identifier, app.drawers, XCUIElement.ElementType.drawer) }
    func drawer(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.drawers, XCUIElement.ElementType.drawer) }

    func grid() -> UIElement { UIElement(app.grids, XCUIElement.ElementType.grid) }
    func grid(_ identifier: String) -> UIElement { UIElement(identifier, app.grids, XCUIElement.ElementType.grid) }
    func grid(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.grids, XCUIElement.ElementType.grid) }

    func group() -> UIElement { UIElement(app.groups, XCUIElement.ElementType.group) }
    func group(_ identifier: String) -> UIElement { UIElement(identifier, app.groups, XCUIElement.ElementType.group) }
    func group(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.groups, XCUIElement.ElementType.group) }

    func handle() -> UIElement { UIElement(app.handles, XCUIElement.ElementType.handle) }
    func handle(_ identifier: String) -> UIElement { UIElement(identifier, app.handles, XCUIElement.ElementType.handle) }
    func handle(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.handles, XCUIElement.ElementType.handle) }

    func helpTag() -> UIElement { UIElement(app.helpTags, XCUIElement.ElementType.helpTag) }
    func helpTag(_ identifier: String) -> UIElement { UIElement(identifier, app.helpTags, XCUIElement.ElementType.helpTag) }
    func helpTag(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.helpTags, XCUIElement.ElementType.helpTag) }

    func icon() -> UIElement { UIElement(app.icons, XCUIElement.ElementType.icon) }
    func icon(_ identifier: String) -> UIElement { UIElement(identifier, app.icons, XCUIElement.ElementType.icon) }
    func icon(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.icons, XCUIElement.ElementType.icon) }

    func image() -> UIElement { UIElement(app.images, XCUIElement.ElementType.image) }
    func image(_ identifier: String) -> UIElement { UIElement(identifier, app.images, XCUIElement.ElementType.image) }
    func image(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.images, XCUIElement.ElementType.image) }

    func incrementArrow() -> UIElement { UIElement(app.incrementArrows, XCUIElement.ElementType.incrementArrow) }
    func incrementArrow(_ identifier: String) -> UIElement { UIElement(identifier, app.incrementArrows, XCUIElement.ElementType.incrementArrow) }
    func incrementArrow(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.incrementArrows, XCUIElement.ElementType.incrementArrow) }

    func keyboard() -> UIElement { UIElement(app.keyboards, XCUIElement.ElementType.keyboard) }
    func keyboard(_ identifier: String) -> UIElement { UIElement(identifier, app.keyboards, XCUIElement.ElementType.keyboard) }
    func keyboard(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.keyboards, XCUIElement.ElementType.keyboard) }

    func key() -> UIElement { UIElement(app.keys, XCUIElement.ElementType.key) }
    func key(_ identifier: String) -> UIElement { UIElement(identifier, app.keys, XCUIElement.ElementType.key) }
    func key(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.keys, XCUIElement.ElementType.key) }

    func layoutArea() -> UIElement { UIElement(app.layoutAreas, XCUIElement.ElementType.layoutArea) }
    func layoutArea(_ identifier: String) -> UIElement { UIElement(identifier, app.layoutAreas, XCUIElement.ElementType.layoutArea) }
    func layoutArea(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.layoutAreas, XCUIElement.ElementType.layoutArea) }

    func layoutItem() -> UIElement { UIElement(app.layoutItems, XCUIElement.ElementType.layoutItem) }
    func layoutItem(_ identifier: String) -> UIElement { UIElement(identifier, app.layoutItems, XCUIElement.ElementType.layoutItem) }
    func layoutItem(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.layoutItems, XCUIElement.ElementType.layoutItem) }

    func levelIndicator() -> UIElement { UIElement(app.levelIndicators, XCUIElement.ElementType.levelIndicator) }
    func levelIndicator(_ identifier: String) -> UIElement { UIElement(identifier, app.levelIndicators, XCUIElement.ElementType.levelIndicator) }
    func levelIndicator(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.levelIndicators, XCUIElement.ElementType.levelIndicator) }

    func link() -> UIElement { UIElement(app.links, XCUIElement.ElementType.link) }
    func link(_ identifier: String) -> UIElement { UIElement(identifier, app.links, XCUIElement.ElementType.link) }
    func link(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.links, XCUIElement.ElementType.link) }

    func map() -> UIElement { UIElement(app.maps, XCUIElement.ElementType.map) }
    func map(_ identifier: String) -> UIElement { UIElement(identifier, app.maps, XCUIElement.ElementType.map) }
    func map(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.maps, XCUIElement.ElementType.map) }

    func matte() -> UIElement { UIElement(app.mattes, XCUIElement.ElementType.matte) }
    func matte(_ identifier: String) -> UIElement { UIElement(identifier, app.mattes, XCUIElement.ElementType.matte) }
    func matte(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.mattes, XCUIElement.ElementType.matte) }

    func menuBar() -> UIElement { UIElement(app.menuBars, XCUIElement.ElementType.menuBar) }
    func menuBar(_ identifier: String) -> UIElement { UIElement(identifier, app.menuBars, XCUIElement.ElementType.menuBar) }
    func menuBar(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.menuBars, XCUIElement.ElementType.menuBar) }

    func menuBarItem() -> UIElement { UIElement(app.menuBarItems, XCUIElement.ElementType.menuBarItem) }
    func menuBarItem(_ identifier: String) -> UIElement { UIElement(identifier, app.menuBarItems, XCUIElement.ElementType.menuBarItem) }
    func menuBarItem(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.menuBarItems, XCUIElement.ElementType.menuBarItem) }

    func menuButton() -> UIElement { UIElement(app.menuButtons, XCUIElement.ElementType.menuButton) }
    func menuButton(_ identifier: String) -> UIElement { UIElement(identifier, app.menuButtons, XCUIElement.ElementType.menuButton) }
    func menuButton(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.menuButtons, XCUIElement.ElementType.menuButton) }

    func menuItem() -> UIElement { UIElement(app.menuItems, XCUIElement.ElementType.menuItem) }
    func menuItem(_ identifier: String) -> UIElement { UIElement(identifier, app.menuItems, XCUIElement.ElementType.menuItem) }
    func menuItem(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.menuItems, XCUIElement.ElementType.menuItem) }

    func menu() -> UIElement { UIElement(app.menus, XCUIElement.ElementType.menu) }
    func menu(_ identifier: String) -> UIElement { UIElement(identifier, app.menus, XCUIElement.ElementType.menu) }
    func menu(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.menus, XCUIElement.ElementType.menu) }

    func navigationBar() -> UIElement { UIElement(app.navigationBars, XCUIElement.ElementType.navigationBar) }
    func navigationBar(_ identifier: String) -> UIElement { UIElement(identifier, app.navigationBars, XCUIElement.ElementType.navigationBar) }
    func navigationBar(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.navigationBars, XCUIElement.ElementType.navigationBar) }

    func otherElement() -> UIElement { UIElement(app.otherElements, XCUIElement.ElementType.other) }
    func otherElement(_ identifier: String) -> UIElement { UIElement(identifier, app.otherElements, XCUIElement.ElementType.other) }
    func otherElement(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.otherElements, XCUIElement.ElementType.other) }

    func outline() -> UIElement { UIElement(app.outlines, XCUIElement.ElementType.outline) }
    func outline(_ identifier: String) -> UIElement { UIElement(identifier, app.outlines, XCUIElement.ElementType.outline) }
    func outline(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.outlines, XCUIElement.ElementType.outline) }

    func outlineRow() -> UIElement { UIElement(app.outlineRows, XCUIElement.ElementType.outlineRow) }
    func outlineRow(_ identifier: String) -> UIElement { UIElement(identifier, app.outlineRows, XCUIElement.ElementType.outlineRow) }
    func outlineRow(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.outlineRows, XCUIElement.ElementType.outlineRow) }

    func pageIndicator() -> UIElement { UIElement(app.pageIndicators, XCUIElement.ElementType.pageIndicator) }
    func pageIndicator(_ identifier: String) -> UIElement { UIElement(identifier, app.pageIndicators, XCUIElement.ElementType.pageIndicator) }
    func pageIndicator(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.pageIndicators, XCUIElement.ElementType.pageIndicator) }

    func picker() -> UIElement { UIElement(app.pickers, XCUIElement.ElementType.picker) }
    func picker(_ identifier: String) -> UIElement { UIElement(identifier, app.pickers, XCUIElement.ElementType.picker) }
    func picker(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.pickers, XCUIElement.ElementType.picker) }

    func pickerWheel() -> UIElement { UIElement(app.pickerWheels, XCUIElement.ElementType.pickerWheel) }
    func pickerWheel(_ identifier: String) -> UIElement { UIElement(identifier, app.pickerWheels, XCUIElement.ElementType.pickerWheel) }
    func pickerWheel(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.pickerWheels, XCUIElement.ElementType.pickerWheel) }

    func popover() -> UIElement { UIElement(app.popovers, XCUIElement.ElementType.popover) }
    func popover(_ identifier: String) -> UIElement { UIElement(identifier, app.popovers, XCUIElement.ElementType.popover) }
    func popover(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.popovers, XCUIElement.ElementType.popover) }

    func popUpButton() -> UIElement { UIElement(app.popUpButtons, XCUIElement.ElementType.popUpButton) }
    func popUpButton(_ identifier: String) -> UIElement { UIElement(identifier, app.popUpButtons, XCUIElement.ElementType.popUpButton) }
    func popUpButton(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.popUpButtons, XCUIElement.ElementType.popUpButton) }

    func progressIndicator() -> UIElement { UIElement(app.progressIndicators, XCUIElement.ElementType.progressIndicator) }
    func progressIndicator(_ identifier: String) -> UIElement { UIElement(identifier, app.progressIndicators, XCUIElement.ElementType.progressIndicator) }
    func progressIndicator(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.progressIndicators, XCUIElement.ElementType.progressIndicator) }

    func radioButton() -> UIElement { UIElement(app.radioButtons, XCUIElement.ElementType.radioButton) }
    func radioButton(_ identifier: String) -> UIElement { UIElement(identifier, app.radioButtons, XCUIElement.ElementType.radioButton) }
    func radioButton(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.radioButtons, XCUIElement.ElementType.radioButton) }

    func radioGroup() -> UIElement { UIElement(app.radioGroups, XCUIElement.ElementType.radioGroup) }
    func radioGroup(_ identifier: String) -> UIElement { UIElement(identifier, app.radioGroups, XCUIElement.ElementType.radioGroup) }
    func radioGroup(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.radioGroups, XCUIElement.ElementType.radioGroup) }

    func ratingIndicator() -> UIElement { UIElement(app.ratingIndicators, XCUIElement.ElementType.ratingIndicator) }
    func ratingIndicator(_ identifier: String) -> UIElement { UIElement(identifier, app.ratingIndicators, XCUIElement.ElementType.ratingIndicator) }
    func ratingIndicator(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.ratingIndicators, XCUIElement.ElementType.ratingIndicator) }

    func relevanceIndicator() -> UIElement { UIElement(app.relevanceIndicators, XCUIElement.ElementType.relevanceIndicator) }
    func relevanceIndicator(_ identifier: String) -> UIElement { UIElement(identifier, app.relevanceIndicators, XCUIElement.ElementType.relevanceIndicator) }
    func relevanceIndicator(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.relevanceIndicators, XCUIElement.ElementType.relevanceIndicator) }

    func rulerMarker() -> UIElement { UIElement(app.rulerMarkers, XCUIElement.ElementType.rulerMarker) }
    func rulerMarker(_ identifier: String) -> UIElement { UIElement(identifier, app.rulerMarkers, XCUIElement.ElementType.rulerMarker) }
    func rulerMarker(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.rulerMarkers, XCUIElement.ElementType.rulerMarker) }

    func ruler() -> UIElement { UIElement(app.rulers, XCUIElement.ElementType.ruler) }
    func ruler(_ identifier: String) -> UIElement { UIElement(identifier, app.rulers, XCUIElement.ElementType.ruler) }
    func ruler(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.rulers, XCUIElement.ElementType.ruler) }

    func scrollBar() -> UIElement { UIElement(app.scrollBars, XCUIElement.ElementType.scrollBar) }
    func scrollBar(_ identifier: String) -> UIElement { UIElement(identifier, app.scrollBars, XCUIElement.ElementType.scrollBar) }
    func scrollBar(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.scrollBars, XCUIElement.ElementType.scrollBar) }

    func scrollView() -> UIElement { UIElement(app.scrollViews, XCUIElement.ElementType.scrollView) }
    func scrollView(_ identifier: String) -> UIElement { UIElement(identifier, app.scrollViews, XCUIElement.ElementType.scrollView) }
    func scrollView(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.scrollViews, XCUIElement.ElementType.scrollView) }

    func searchField() -> UIElement { UIElement(app.searchFields, XCUIElement.ElementType.searchField) }
    func searchField(_ identifier: String) -> UIElement { UIElement(identifier, app.searchFields, XCUIElement.ElementType.searchField) }
    func searchField(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.searchFields, XCUIElement.ElementType.searchField) }

    func secureTextField() -> UIElement { UIElement(app.secureTextFields, XCUIElement.ElementType.secureTextField) }
    func secureTextField(_ identifier: String) -> UIElement { UIElement(identifier, app.secureTextFields, XCUIElement.ElementType.secureTextField) }
    func secureTextField(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.secureTextFields, XCUIElement.ElementType.secureTextField) }

    func segmentedControl() -> UIElement { UIElement(app.segmentedControls, XCUIElement.ElementType.segmentedControl) }
    func segmentedControl(_ identifier: String) -> UIElement { UIElement(identifier, app.segmentedControls, XCUIElement.ElementType.segmentedControl) }
    func segmentedControl(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.segmentedControls, XCUIElement.ElementType.segmentedControl) }

    func sheet() -> UIElement { UIElement(app.sheets, XCUIElement.ElementType.sheet) }
    func sheet(_ identifier: String) -> UIElement { UIElement(identifier, app.sheets, XCUIElement.ElementType.sheet) }
    func sheet(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.sheets, XCUIElement.ElementType.sheet) }

    func slider() -> UIElement { UIElement(app.sliders, XCUIElement.ElementType.slider) }
    func slider(_ identifier: String) -> UIElement { UIElement(identifier, app.sliders, XCUIElement.ElementType.slider) }
    func slider(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.sliders, XCUIElement.ElementType.slider) }

    func splitGroup() -> UIElement { UIElement(app.splitGroups, XCUIElement.ElementType.splitGroup) }
    func splitGroup(_ identifier: String) -> UIElement { UIElement(identifier, app.splitGroups, XCUIElement.ElementType.splitGroup) }
    func splitGroup(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.splitGroups, XCUIElement.ElementType.splitGroup) }

    func splitter() -> UIElement { UIElement(app.splitters, XCUIElement.ElementType.splitter) }
    func splitter(_ identifier: String) -> UIElement { UIElement(identifier, app.splitters, XCUIElement.ElementType.splitter) }
    func splitter(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.splitters, XCUIElement.ElementType.splitter) }

    func staticText() -> UIElement { UIElement(app.staticTexts, XCUIElement.ElementType.staticText) }
    func staticText(_ identifier: String) -> UIElement { UIElement(identifier, app.staticTexts, XCUIElement.ElementType.staticText) }
    func staticText(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.staticTexts, XCUIElement.ElementType.staticText) }

    func statusBar() -> UIElement { UIElement(app.statusBars, XCUIElement.ElementType.statusBar) }
    func statusBar(_ identifier: String) -> UIElement { UIElement(identifier, app.statusBars, XCUIElement.ElementType.statusBar) }
    func statusBar(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.statusBars, XCUIElement.ElementType.statusBar) }

    func statusItem() -> UIElement { UIElement(app.statusItems, XCUIElement.ElementType.statusItem) }
    func statusItem(_ identifier: String) -> UIElement { UIElement(identifier, app.statusItems, XCUIElement.ElementType.statusItem) }
    func statusItem(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.statusItems, XCUIElement.ElementType.statusItem) }

    func stepper() -> UIElement { UIElement(app.steppers, XCUIElement.ElementType.stepper) }
    func stepper(_ identifier: String) -> UIElement { UIElement(identifier, app.steppers, XCUIElement.ElementType.stepper) }
    func stepper(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.steppers, XCUIElement.ElementType.stepper) }

    func swittch() -> UIElement { UIElement(app.switches, XCUIElement.ElementType.switch) }
    func swittch(_ identifier: String) -> UIElement { UIElement(identifier, app.switches, XCUIElement.ElementType.switch) }
    func swittch(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.switches, XCUIElement.ElementType.switch) }

    func tab() -> UIElement { UIElement(app.tabs, XCUIElement.ElementType.tab) }
    func tab(_ identifier: String) -> UIElement { UIElement(identifier, app.tabs, XCUIElement.ElementType.tab) }
    func tab(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.tabs, XCUIElement.ElementType.tab) }

    func tabBar() -> UIElement { UIElement(app.tabBars, XCUIElement.ElementType.tabBar) }
    func tabBar(_ identifier: String) -> UIElement { UIElement(identifier, app.tabBars, XCUIElement.ElementType.tabBar) }
    func tabBar(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.tabBars, XCUIElement.ElementType.tabBar) }

    func tabGroup() -> UIElement { UIElement(app.tabGroups, XCUIElement.ElementType.tabGroup) }
    func tabGroup(_ identifier: String) -> UIElement { UIElement(identifier, app.tabGroups, XCUIElement.ElementType.tabGroup) }
    func tabGroup(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.tabGroups, XCUIElement.ElementType.tabGroup) }

    func table() -> UIElement { UIElement(app.tables, XCUIElement.ElementType.table) }
    func table(_ identifier: String) -> UIElement { UIElement(identifier, app.tables, XCUIElement.ElementType.table) }
    func table(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.tables, XCUIElement.ElementType.table) }

    func tableColumn() -> UIElement { UIElement(app.tableColumns, XCUIElement.ElementType.tableColumn) }
    func tableColumn(_ identifier: String) -> UIElement { UIElement(identifier, app.tableColumns, XCUIElement.ElementType.tableColumn) }
    func tableColumn(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.tableColumns, XCUIElement.ElementType.tableColumn) }

    func tableRow() -> UIElement { UIElement(app.tableRows, XCUIElement.ElementType.tableRow) }
    func tableRow(_ identifier: String) -> UIElement { UIElement(identifier, app.tableRows, XCUIElement.ElementType.tableRow) }
    func tableRow(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.tableRows, XCUIElement.ElementType.tableRow) }

    func textField() -> UIElement { UIElement(app.textFields, XCUIElement.ElementType.textField) }
    func textField(_ identifier: String) -> UIElement { UIElement(identifier, app.textFields, XCUIElement.ElementType.textField) }
    func textField(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.textFields, XCUIElement.ElementType.textField) }

    func textView() -> UIElement { UIElement(app.textViews, XCUIElement.ElementType.textView) }
    func textView(_ identifier: String) -> UIElement { UIElement(identifier, app.textViews, XCUIElement.ElementType.textView) }
    func textView(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.textViews, XCUIElement.ElementType.textView) }

    func timeline() -> UIElement { UIElement(app.timelines, XCUIElement.ElementType.timeline) }
    func timeline(_ identifier: String) -> UIElement { UIElement(identifier, app.timelines, XCUIElement.ElementType.timeline) }
    func timeline(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.timelines, XCUIElement.ElementType.timeline) }

    func toggle() -> UIElement { UIElement(app.toggles, XCUIElement.ElementType.toggle) }
    func toggle(_ identifier: String) -> UIElement { UIElement(identifier, app.toggles, XCUIElement.ElementType.toggle) }
    func toggle(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.toggles, XCUIElement.ElementType.toggle) }

    func toolbarButton() -> UIElement { UIElement(app.toolbarButtons, XCUIElement.ElementType.toolbarButton) }
    func toolbarButton(_ identifier: String) -> UIElement { UIElement(identifier, app.toolbarButtons, XCUIElement.ElementType.toolbarButton) }
    func toolbarButton(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.toolbarButtons, XCUIElement.ElementType.toolbarButton) }

    func toolbar() -> UIElement { UIElement(app.toolbars, XCUIElement.ElementType.toolbar) }
    func toolbar(_ identifier: String) -> UIElement { UIElement(identifier, app.toolbars, XCUIElement.ElementType.toolbar) }
    func toolbar(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.toolbars, XCUIElement.ElementType.toolbar) }

    func touchBar() -> UIElement { UIElement(app.touchBars, XCUIElement.ElementType.touchBar) }
    func touchBar(_ identifier: String) -> UIElement { UIElement(identifier, app.touchBars, XCUIElement.ElementType.touchBar) }
    func touchBar(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.touchBars, XCUIElement.ElementType.touchBar) }

    func valueIndicator() -> UIElement { UIElement(app.valueIndicators, XCUIElement.ElementType.valueIndicator) }
    func valueIndicator(_ identifier: String) -> UIElement { UIElement(identifier, app.valueIndicators, XCUIElement.ElementType.valueIndicator) }
    func valueIndicator(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.valueIndicators, XCUIElement.ElementType.valueIndicator) }

    func webView() -> UIElement { UIElement(app.webViews, XCUIElement.ElementType.webView) }
    func webView(_ identifier: String) -> UIElement { UIElement(identifier, app.webViews, XCUIElement.ElementType.webView) }
    func webView(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.webViews, XCUIElement.ElementType.webView) }

    func windows() -> UIElement { UIElement(app.windows, XCUIElement.ElementType.window) }
    func windows(_ identifier: String) -> UIElement { UIElement(identifier, app.windows, XCUIElement.ElementType.window) }
    func windows(_ predicate: NSPredicate) -> UIElement { UIElement(predicate, app.windows, XCUIElement.ElementType.window) }
}
