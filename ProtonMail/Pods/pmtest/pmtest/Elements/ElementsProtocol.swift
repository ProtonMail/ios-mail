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

    func acttivityIndicator() -> UiElement { UiElement(getApp().activityIndicators, XCUIElement.ElementType.activityIndicator) }
    func acttivityIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().activityIndicators, XCUIElement.ElementType.activityIndicator) }
    func activityIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().activityIndicators, XCUIElement.ElementType.activityIndicator) }

    func alert() -> UiElement { UiElement(getApp().alerts, XCUIElement.ElementType.alert) }
    func alert(_ identifier: String) -> UiElement { UiElement(identifier, getApp().alerts, XCUIElement.ElementType.alert) }
    func alert(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().alerts, XCUIElement.ElementType.alert) }

    func browser() -> UiElement { UiElement(getApp().browsers, XCUIElement.ElementType.browser) }
    func browser(_ identifier: String) -> UiElement { UiElement(identifier, getApp().browsers, XCUIElement.ElementType.browser) }
    func browser(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().browsers, XCUIElement.ElementType.browser) }

    func button() -> UiElement { UiElement(getApp().buttons, XCUIElement.ElementType.button) }
    func button(_ identifier: String) -> UiElement { UiElement(identifier, getApp().buttons, XCUIElement.ElementType.button) }
    func button(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().buttons, XCUIElement.ElementType.button) }

    func cell() -> UiElement { UiElement(getApp().cells, XCUIElement.ElementType.cell) }
    func cell(_ identifier: String) -> UiElement { UiElement(identifier, getApp().cells, XCUIElement.ElementType.cell) }
    func cell(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().cells, XCUIElement.ElementType.cell) }

    func checkBox() -> UiElement { UiElement(getApp().checkBoxes, XCUIElement.ElementType.checkBox) }
    func checkBox(_ identifier: String) -> UiElement { UiElement(identifier, getApp().checkBoxes, XCUIElement.ElementType.checkBox) }
    func checkBox(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().checkBoxes, XCUIElement.ElementType.checkBox) }

    func collectionView() -> UiElement { UiElement(getApp().collectionViews, XCUIElement.ElementType.collectionView) }
    func collectionView(_ identifier: String) -> UiElement { UiElement(identifier, getApp().collectionViews, XCUIElement.ElementType.collectionView) }
    func collectionView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().collectionViews, XCUIElement.ElementType.collectionView) }

    func colorWell() -> UiElement { UiElement(getApp().colorWells, XCUIElement.ElementType.colorWell) }
    func colorWell(_ identifier: String) -> UiElement { UiElement(identifier, getApp().colorWells, XCUIElement.ElementType.colorWell) }
    func colorWell(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().colorWells, XCUIElement.ElementType.colorWell) }

    func comboBox() -> UiElement { UiElement(getApp().comboBoxes, XCUIElement.ElementType.comboBox) }
    func comboBox(_ identifier: String) -> UiElement { UiElement(identifier, getApp().comboBoxes, XCUIElement.ElementType.comboBox) }
    func comboBox(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().comboBoxes, XCUIElement.ElementType.comboBox) }

    func datePicker() -> UiElement { UiElement(getApp().datePickers, XCUIElement.ElementType.datePicker) }
    func datePicker(_ identifier: String) -> UiElement { UiElement(identifier, getApp().datePickers, XCUIElement.ElementType.datePicker) }
    func datePicker(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().datePickers, XCUIElement.ElementType.datePicker) }

    func decrementArrow() -> UiElement { UiElement(getApp().decrementArrows, XCUIElement.ElementType.decrementArrow) }
    func decrementArrow(_ identifier: String) -> UiElement { UiElement(identifier, getApp().decrementArrows, XCUIElement.ElementType.decrementArrow) }
    func decrementArrow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().decrementArrows, XCUIElement.ElementType.decrementArrow) }

    func dialog() -> UiElement { UiElement(getApp().dialogs, XCUIElement.ElementType.dialog) }
    func dialog(_ identifier: String) -> UiElement { UiElement(identifier, getApp().dialogs, XCUIElement.ElementType.dialog) }
    func dialog(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().dialogs, XCUIElement.ElementType.dialog) }

    func disclosureTriangle() -> UiElement { UiElement(getApp().disclosureTriangles, XCUIElement.ElementType.disclosureTriangle) }
    func disclosureTriangle(_ identifier: String) -> UiElement { UiElement(identifier, getApp().disclosureTriangles, XCUIElement.ElementType.disclosureTriangle) }
    func disclosureTriangle(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().disclosureTriangles, XCUIElement.ElementType.disclosureTriangle) }

    func dockItem() -> UiElement { UiElement(getApp().dockItems, XCUIElement.ElementType.dockItem) }
    func dockItem(_ identifier: String) -> UiElement { UiElement(identifier, getApp().dockItems, XCUIElement.ElementType.dockItem) }
    func dockItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().dockItems, XCUIElement.ElementType.dockItem) }

    func drawer() -> UiElement { UiElement(getApp().drawers, XCUIElement.ElementType.drawer) }
    func drawer(_ identifier: String) -> UiElement { UiElement(identifier, getApp().drawers, XCUIElement.ElementType.drawer) }
    func drawer(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().drawers, XCUIElement.ElementType.drawer) }

    func grid() -> UiElement { UiElement(getApp().grids, XCUIElement.ElementType.grid) }
    func grid(_ identifier: String) -> UiElement { UiElement(identifier, getApp().grids, XCUIElement.ElementType.grid) }
    func grid(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().grids, XCUIElement.ElementType.grid) }

    func group() -> UiElement { UiElement(getApp().groups, XCUIElement.ElementType.group) }
    func group(_ identifier: String) -> UiElement { UiElement(identifier, getApp().groups, XCUIElement.ElementType.group) }
    func group(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().groups, XCUIElement.ElementType.group) }

    func handle() -> UiElement { UiElement(getApp().handles, XCUIElement.ElementType.handle) }
    func handle(_ identifier: String) -> UiElement { UiElement(identifier, getApp().handles, XCUIElement.ElementType.handle) }
    func handle(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().handles, XCUIElement.ElementType.handle) }

    func helpTag() -> UiElement { UiElement(getApp().helpTags, XCUIElement.ElementType.helpTag) }
    func helpTag(_ identifier: String) -> UiElement { UiElement(identifier, getApp().helpTags, XCUIElement.ElementType.helpTag) }
    func helpTag(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().helpTags, XCUIElement.ElementType.helpTag) }

    func icon() -> UiElement { UiElement(getApp().icons, XCUIElement.ElementType.icon) }
    func icon(_ identifier: String) -> UiElement { UiElement(identifier, getApp().icons, XCUIElement.ElementType.icon) }
    func icon(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().icons, XCUIElement.ElementType.icon) }

    func image() -> UiElement { UiElement(getApp().images, XCUIElement.ElementType.image) }
    func image(_ identifier: String) -> UiElement { UiElement(identifier, getApp().images, XCUIElement.ElementType.image) }
    func image(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().images, XCUIElement.ElementType.image) }

    func incrementArrow() -> UiElement { UiElement(getApp().incrementArrows, XCUIElement.ElementType.incrementArrow) }
    func incrementArrow(_ identifier: String) -> UiElement { UiElement(identifier, getApp().incrementArrows, XCUIElement.ElementType.incrementArrow) }
    func incrementArrow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().incrementArrows, XCUIElement.ElementType.incrementArrow) }

    func keyboard() -> UiElement { UiElement(getApp().keyboards, XCUIElement.ElementType.keyboard) }
    func keyboard(_ identifier: String) -> UiElement { UiElement(identifier, getApp().keyboards, XCUIElement.ElementType.keyboard) }
    func keyboard(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().keyboards, XCUIElement.ElementType.keyboard) }

    func key() -> UiElement { UiElement(getApp().keys, XCUIElement.ElementType.key) }
    func key(_ identifier: String) -> UiElement { UiElement(identifier, getApp().keys, XCUIElement.ElementType.key) }
    func key(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().keys, XCUIElement.ElementType.key) }

    func layoutArea() -> UiElement { UiElement(getApp().layoutAreas, XCUIElement.ElementType.layoutArea) }
    func layoutArea(_ identifier: String) -> UiElement { UiElement(identifier, getApp().layoutAreas, XCUIElement.ElementType.layoutArea) }
    func layoutArea(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().layoutAreas, XCUIElement.ElementType.layoutArea) }

    func layoutItem() -> UiElement { UiElement(getApp().layoutItems, XCUIElement.ElementType.layoutItem) }
    func layoutItem(_ identifier: String) -> UiElement { UiElement(identifier, getApp().layoutItems, XCUIElement.ElementType.layoutItem) }
    func layoutItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().layoutItems, XCUIElement.ElementType.layoutItem) }

    func levelIndicator() -> UiElement { UiElement(getApp().levelIndicators, XCUIElement.ElementType.levelIndicator) }
    func levelIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().levelIndicators, XCUIElement.ElementType.levelIndicator) }
    func levelIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().levelIndicators, XCUIElement.ElementType.levelIndicator) }

    func link() -> UiElement { UiElement(getApp().links, XCUIElement.ElementType.link) }
    func link(_ identifier: String) -> UiElement { UiElement(identifier, getApp().links, XCUIElement.ElementType.link) }
    func link(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().links, XCUIElement.ElementType.link) }

    func map() -> UiElement { UiElement(getApp().maps, XCUIElement.ElementType.map) }
    func map(_ identifier: String) -> UiElement { UiElement(identifier, getApp().maps, XCUIElement.ElementType.map) }
    func map(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().maps, XCUIElement.ElementType.map) }

    func matte() -> UiElement { UiElement(getApp().mattes, XCUIElement.ElementType.matte) }
    func matte(_ identifier: String) -> UiElement { UiElement(identifier, getApp().mattes, XCUIElement.ElementType.matte) }
    func matte(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().mattes, XCUIElement.ElementType.matte) }

    func menuBar() -> UiElement { UiElement(getApp().menuBars, XCUIElement.ElementType.menuBar) }
    func menuBar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().menuBars, XCUIElement.ElementType.menuBar) }
    func menuBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().menuBars, XCUIElement.ElementType.menuBar) }

    func menuBarItem() -> UiElement { UiElement(getApp().menuBarItems, XCUIElement.ElementType.menuBarItem) }
    func menuBarItem(_ identifier: String) -> UiElement { UiElement(identifier, getApp().menuBarItems, XCUIElement.ElementType.menuBarItem) }
    func menuBarItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().menuBarItems, XCUIElement.ElementType.menuBarItem) }

    func menuButton() -> UiElement { UiElement(getApp().menuButtons, XCUIElement.ElementType.menuButton) }
    func menuButton(_ identifier: String) -> UiElement { UiElement(identifier, getApp().menuButtons, XCUIElement.ElementType.menuButton) }
    func menuButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().menuButtons, XCUIElement.ElementType.menuButton) }

    func menuItem() -> UiElement { UiElement(getApp().menuItems, XCUIElement.ElementType.menuItem) }
    func menuItem(_ identifier: String) -> UiElement { UiElement(identifier, getApp().menuItems, XCUIElement.ElementType.menuItem) }
    func menuItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().menuItems, XCUIElement.ElementType.menuItem) }

    func menu() -> UiElement { UiElement(getApp().menus, XCUIElement.ElementType.menu) }
    func menu(_ identifier: String) -> UiElement { UiElement(identifier, getApp().menus, XCUIElement.ElementType.menu) }
    func menu(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().menus, XCUIElement.ElementType.menu) }

    func navigationBar() -> UiElement { UiElement(getApp().navigationBars, XCUIElement.ElementType.navigationBar) }
    func navigationBar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().navigationBars, XCUIElement.ElementType.navigationBar) }
    func navigationBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().navigationBars, XCUIElement.ElementType.navigationBar) }

    func otherElement() -> UiElement { UiElement(getApp().otherElements, XCUIElement.ElementType.other) }
    func otherElement(_ identifier: String) -> UiElement { UiElement(identifier, getApp().otherElements, XCUIElement.ElementType.other) }
    func otherElement(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().otherElements, XCUIElement.ElementType.other) }

    func outline() -> UiElement { UiElement(getApp().outlines, XCUIElement.ElementType.outline) }
    func outline(_ identifier: String) -> UiElement { UiElement(identifier, getApp().outlines, XCUIElement.ElementType.outline) }
    func outline(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().outlines, XCUIElement.ElementType.outline) }

    func outlineRow() -> UiElement { UiElement(getApp().outlineRows, XCUIElement.ElementType.outlineRow) }
    func outlineRow(_ identifier: String) -> UiElement { UiElement(identifier, getApp().outlineRows, XCUIElement.ElementType.outlineRow) }
    func outlineRow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().outlineRows, XCUIElement.ElementType.outlineRow) }

    func pageIndicator() -> UiElement { UiElement(getApp().pageIndicators, XCUIElement.ElementType.pageIndicator) }
    func pageIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().pageIndicators, XCUIElement.ElementType.pageIndicator) }
    func pageIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().pageIndicators, XCUIElement.ElementType.pageIndicator) }

    func picker() -> UiElement { UiElement(getApp().pickers, XCUIElement.ElementType.picker) }
    func picker(_ identifier: String) -> UiElement { UiElement(identifier, getApp().pickers, XCUIElement.ElementType.picker) }
    func picker(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().pickers, XCUIElement.ElementType.picker) }

    func pickerWheel() -> UiElement { UiElement(getApp().pickerWheels, XCUIElement.ElementType.pickerWheel) }
    func pickerWheel(_ identifier: String) -> UiElement { UiElement(identifier, getApp().pickerWheels, XCUIElement.ElementType.pickerWheel) }
    func pickerWheel(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().pickerWheels, XCUIElement.ElementType.pickerWheel) }

    func popover() -> UiElement { UiElement(getApp().popovers, XCUIElement.ElementType.popover) }
    func popover(_ identifier: String) -> UiElement { UiElement(identifier, getApp().popovers, XCUIElement.ElementType.popover) }
    func popover(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().popovers, XCUIElement.ElementType.popover) }

    func popUpButton() -> UiElement { UiElement(getApp().popUpButtons, XCUIElement.ElementType.popUpButton) }
    func popUpButton(_ identifier: String) -> UiElement { UiElement(identifier, getApp().popUpButtons, XCUIElement.ElementType.popUpButton) }
    func popUpButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().popUpButtons, XCUIElement.ElementType.popUpButton) }

    func progressIndicator() -> UiElement { UiElement(getApp().progressIndicators, XCUIElement.ElementType.progressIndicator) }
    func progressIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().progressIndicators, XCUIElement.ElementType.progressIndicator) }
    func progressIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().progressIndicators, XCUIElement.ElementType.progressIndicator) }

    func radioButton() -> UiElement { UiElement(getApp().radioButtons, XCUIElement.ElementType.radioButton) }
    func radioButton(_ identifier: String) -> UiElement { UiElement(identifier, getApp().radioButtons, XCUIElement.ElementType.radioButton) }
    func radioButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().radioButtons, XCUIElement.ElementType.radioButton) }

    func radioGroup() -> UiElement { UiElement(getApp().radioGroups, XCUIElement.ElementType.radioGroup) }
    func radioGroup(_ identifier: String) -> UiElement { UiElement(identifier, getApp().radioGroups, XCUIElement.ElementType.radioGroup) }
    func radioGroup(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().radioGroups, XCUIElement.ElementType.radioGroup) }

    func ratingIndicator() -> UiElement { UiElement(getApp().ratingIndicators, XCUIElement.ElementType.ratingIndicator) }
    func ratingIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().ratingIndicators, XCUIElement.ElementType.ratingIndicator) }
    func ratingIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().ratingIndicators, XCUIElement.ElementType.ratingIndicator) }

    func relevanceIndicator() -> UiElement { UiElement(getApp().relevanceIndicators, XCUIElement.ElementType.relevanceIndicator) }
    func relevanceIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().relevanceIndicators, XCUIElement.ElementType.relevanceIndicator) }
    func relevanceIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().relevanceIndicators, XCUIElement.ElementType.relevanceIndicator) }

    func rulerMarker() -> UiElement { UiElement(getApp().rulerMarkers, XCUIElement.ElementType.rulerMarker) }
    func rulerMarker(_ identifier: String) -> UiElement { UiElement(identifier, getApp().rulerMarkers, XCUIElement.ElementType.rulerMarker) }
    func rulerMarker(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().rulerMarkers, XCUIElement.ElementType.rulerMarker) }

    func ruler() -> UiElement { UiElement(getApp().rulers, XCUIElement.ElementType.ruler) }
    func ruler(_ identifier: String) -> UiElement { UiElement(identifier, getApp().rulers, XCUIElement.ElementType.ruler) }
    func ruler(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().rulers, XCUIElement.ElementType.ruler) }

    func scrollBar() -> UiElement { UiElement(getApp().scrollBars, XCUIElement.ElementType.scrollBar) }
    func scrollBar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().scrollBars, XCUIElement.ElementType.scrollBar) }
    func scrollBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().scrollBars, XCUIElement.ElementType.scrollBar) }

    func scrollView() -> UiElement { UiElement(getApp().scrollViews, XCUIElement.ElementType.scrollView) }
    func scrollView(_ identifier: String) -> UiElement { UiElement(identifier, getApp().scrollViews, XCUIElement.ElementType.scrollView) }
    func scrollView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().scrollViews, XCUIElement.ElementType.scrollView) }

    func searchField() -> UiElement { UiElement(getApp().searchFields, XCUIElement.ElementType.searchField) }
    func searchField(_ identifier: String) -> UiElement { UiElement(identifier, getApp().searchFields, XCUIElement.ElementType.searchField) }
    func searchField(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().searchFields, XCUIElement.ElementType.searchField) }

    func secureTextField() -> UiElement { UiElement(getApp().secureTextFields, XCUIElement.ElementType.secureTextField) }
    func secureTextField(_ identifier: String) -> UiElement { UiElement(identifier, getApp().secureTextFields, XCUIElement.ElementType.secureTextField) }
    func secureTextField(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().secureTextFields, XCUIElement.ElementType.secureTextField) }

    func segmentedControl() -> UiElement { UiElement(getApp().segmentedControls, XCUIElement.ElementType.segmentedControl) }
    func segmentedControl(_ identifier: String) -> UiElement { UiElement(identifier, getApp().segmentedControls, XCUIElement.ElementType.segmentedControl) }
    func segmentedControl(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().segmentedControls, XCUIElement.ElementType.segmentedControl) }

    func sheet() -> UiElement { UiElement(getApp().sheets, XCUIElement.ElementType.sheet) }
    func sheet(_ identifier: String) -> UiElement { UiElement(identifier, getApp().sheets, XCUIElement.ElementType.sheet) }
    func sheet(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().sheets, XCUIElement.ElementType.sheet) }

    func slider() -> UiElement { UiElement(getApp().sliders, XCUIElement.ElementType.slider) }
    func slider(_ identifier: String) -> UiElement { UiElement(identifier, getApp().sliders, XCUIElement.ElementType.slider) }
    func slider(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().sliders, XCUIElement.ElementType.slider) }

    func splitGroup() -> UiElement { UiElement(getApp().splitGroups, XCUIElement.ElementType.splitGroup) }
    func splitGroup(_ identifier: String) -> UiElement { UiElement(identifier, getApp().splitGroups, XCUIElement.ElementType.splitGroup) }
    func splitGroup(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().splitGroups, XCUIElement.ElementType.splitGroup) }

    func splitter() -> UiElement { UiElement(getApp().splitters, XCUIElement.ElementType.splitter) }
    func splitter(_ identifier: String) -> UiElement { UiElement(identifier, getApp().splitters, XCUIElement.ElementType.splitter) }
    func splitter(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().splitters, XCUIElement.ElementType.splitter) }

    func staticText() -> UiElement { UiElement(getApp().staticTexts, XCUIElement.ElementType.staticText) }
    func staticText(_ identifier: String) -> UiElement { UiElement(identifier, getApp().staticTexts, XCUIElement.ElementType.staticText) }
    func staticText(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().staticTexts, XCUIElement.ElementType.staticText) }

    func statusBar() -> UiElement { UiElement(getApp().statusBars, XCUIElement.ElementType.statusBar) }
    func statusBar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().statusBars, XCUIElement.ElementType.statusBar) }
    func statusBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().statusBars, XCUIElement.ElementType.statusBar) }

    func statusItem() -> UiElement { UiElement(getApp().statusItems, XCUIElement.ElementType.statusItem) }
    func statusItem(_ identifier: String) -> UiElement { UiElement(identifier, getApp().statusItems, XCUIElement.ElementType.statusItem) }
    func statusItem(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().statusItems, XCUIElement.ElementType.statusItem) }

    func stepper() -> UiElement { UiElement(getApp().steppers, XCUIElement.ElementType.stepper) }
    func stepper(_ identifier: String) -> UiElement { UiElement(identifier, getApp().steppers, XCUIElement.ElementType.stepper) }
    func stepper(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().steppers, XCUIElement.ElementType.stepper) }

    func swittch() -> UiElement { UiElement(getApp().switches, XCUIElement.ElementType.switch) }
    func swittch(_ identifier: String) -> UiElement { UiElement(identifier, getApp().switches, XCUIElement.ElementType.switch) }
    func swittch(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().switches, XCUIElement.ElementType.switch) }

    func tab() -> UiElement { UiElement(getApp().tabs, XCUIElement.ElementType.tab) }
    func tab(_ identifier: String) -> UiElement { UiElement(identifier, getApp().tabs, XCUIElement.ElementType.tab) }
    func tab(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().tabs, XCUIElement.ElementType.tab) }

    func tabBar() -> UiElement { UiElement(getApp().tabBars, XCUIElement.ElementType.tabBar) }
    func tabBar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().tabBars, XCUIElement.ElementType.tabBar) }
    func tabBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().tabBars, XCUIElement.ElementType.tabBar) }

    func tabGroup() -> UiElement { UiElement(getApp().tabGroups, XCUIElement.ElementType.tabGroup) }
    func tabGroup(_ identifier: String) -> UiElement { UiElement(identifier, getApp().tabGroups, XCUIElement.ElementType.tabGroup) }
    func tabGroup(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().tabGroups, XCUIElement.ElementType.tabGroup) }

    func table() -> UiElement { UiElement(getApp().tables, XCUIElement.ElementType.table) }
    func table(_ identifier: String) -> UiElement { UiElement(identifier, getApp().tables, XCUIElement.ElementType.table) }
    func table(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().tables, XCUIElement.ElementType.table) }

    func tableColumn() -> UiElement { UiElement(getApp().tableColumns, XCUIElement.ElementType.tableColumn) }
    func tableColumn(_ identifier: String) -> UiElement { UiElement(identifier, getApp().tableColumns, XCUIElement.ElementType.tableColumn) }
    func tableColumn(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().tableColumns, XCUIElement.ElementType.tableColumn) }

    func tableRow() -> UiElement { UiElement(getApp().tableRows, XCUIElement.ElementType.tableRow) }
    func tableRow(_ identifier: String) -> UiElement { UiElement(identifier, getApp().tableRows, XCUIElement.ElementType.tableRow) }
    func tableRow(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().tableRows, XCUIElement.ElementType.tableRow) }

    func textField() -> UiElement { UiElement(getApp().textFields, XCUIElement.ElementType.textField) }
    func textField(_ identifier: String) -> UiElement { UiElement(identifier, getApp().textFields, XCUIElement.ElementType.textField) }
    func textField(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().textFields, XCUIElement.ElementType.textField) }

    func textView() -> UiElement { UiElement(getApp().textViews, XCUIElement.ElementType.textView) }
    func textView(_ identifier: String) -> UiElement { UiElement(identifier, getApp().textViews, XCUIElement.ElementType.textView) }
    func textView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().textViews, XCUIElement.ElementType.textView) }

    func timeline() -> UiElement { UiElement(getApp().timelines, XCUIElement.ElementType.timeline) }
    func timeline(_ identifier: String) -> UiElement { UiElement(identifier, getApp().timelines, XCUIElement.ElementType.timeline) }
    func timeline(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().timelines, XCUIElement.ElementType.timeline) }

    func toggle() -> UiElement { UiElement(getApp().toggles, XCUIElement.ElementType.toggle) }
    func toggle(_ identifier: String) -> UiElement { UiElement(identifier, getApp().toggles, XCUIElement.ElementType.toggle) }
    func toggle(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().toggles, XCUIElement.ElementType.toggle) }

    func toolbarButton() -> UiElement { UiElement(getApp().toolbarButtons, XCUIElement.ElementType.toolbarButton) }
    func toolbarButton(_ identifier: String) -> UiElement { UiElement(identifier, getApp().toolbarButtons, XCUIElement.ElementType.toolbarButton) }
    func toolbarButton(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().toolbarButtons, XCUIElement.ElementType.toolbarButton) }

    func toolbar() -> UiElement { UiElement(getApp().toolbars, XCUIElement.ElementType.toolbar) }
    func toolbar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().toolbars, XCUIElement.ElementType.toolbar) }
    func toolbar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().toolbars, XCUIElement.ElementType.toolbar) }

    func touchBar() -> UiElement { UiElement(getApp().touchBars, XCUIElement.ElementType.touchBar) }
    func touchBar(_ identifier: String) -> UiElement { UiElement(identifier, getApp().touchBars, XCUIElement.ElementType.touchBar) }
    func touchBar(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().touchBars, XCUIElement.ElementType.touchBar) }

    func valueIndicator() -> UiElement { UiElement(getApp().valueIndicators, XCUIElement.ElementType.valueIndicator) }
    func valueIndicator(_ identifier: String) -> UiElement { UiElement(identifier, getApp().valueIndicators, XCUIElement.ElementType.valueIndicator) }
    func valueIndicator(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().valueIndicators, XCUIElement.ElementType.valueIndicator) }

    func webView() -> UiElement { UiElement(getApp().webViews, XCUIElement.ElementType.webView) }
    func webView(_ identifier: String) -> UiElement { UiElement(identifier, getApp().webViews, XCUIElement.ElementType.webView) }
    func webView(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().webViews, XCUIElement.ElementType.webView) }

    func windows() -> UiElement { UiElement(getApp().windows, XCUIElement.ElementType.window) }
    func windows(_ identifier: String) -> UiElement { UiElement(identifier, getApp().windows, XCUIElement.ElementType.window) }
    func windows(_ predicate: NSPredicate) -> UiElement { UiElement(predicate, getApp().windows, XCUIElement.ElementType.window) }
}
