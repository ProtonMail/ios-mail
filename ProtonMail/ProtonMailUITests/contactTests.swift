//
//  contactTests.swift
//  ProtonMail - Created on 7/5/19.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
    

import XCTest

class contactTests: XCTestCase {

    override func setUp() {

        continueAfterFailure = false

        XCUIApplication().launch()
        
        AllowNotifications()
        
        Thread.sleep(forTimeInterval: 2)
        
        if SignInPage.txtUsername.element.exists {
            
            signIn(twoPasswordMode: false)
            
        }
        
    }
    
    override func tearDown() {
        
        app.terminate()
        
        super.tearDown()
    }

    func testContactsAndGroupsRefresh() {
        
        Thread.sleep(forTimeInterval: 3)
        
        sidebarButton.tap()
        
        contactsButton.tap()
        
        Thread.sleep(forTimeInterval: 1.5)
        
        if #available(iOS 13.0, *) {
            sectionIndexTable.swipeDown()
        } else {
           tableIndexTable.swipeDown()
        }
        
        Thread.sleep(forTimeInterval: 1)
        
        app.tabBars.buttons[groupsLabel].tap()
        
        if #available(iOS 13.0, *) {
           contactGroupWindowiOS13.swipeDown()
        } else {
           contactGroupWindow.swipeDown()
        }
        
        app.navigationBars[groupsLabel].buttons[menu].tap()
        
    }
    
    func testCreateDeleteContact() {
        
        Thread.sleep(forTimeInterval: 3)
        
        sidebarButton.tap()
        
        contactsButton.tap()
        
        app.navigationBars[contactsLabel].buttons[addLabel].tap()
        app.sheets["Select An Option"].buttons[addContactLabel].tap()
        app.tables.textFields["Contact Name"].tap()
        app.typeText(testContact)
        tablesQuery.staticTexts["Add new email"].tap()
        app.typeText(testEmail)
        saveContactNavButton.tap()
        
        tablesQuery.staticTexts[testContact].tap()
        app.navigationBars["Contact Details"].buttons["Edit"].tap()
        deleteContact.tap()
        app.sheets.buttons[deleteContactLabel].tap()
        
        Thread.sleep(forTimeInterval: 2)
        
        XCTAssertFalse(tablesQuery.staticTexts[testContact].exists)
        
    }
    
    func testContactCompose() {
        
        Thread.sleep(forTimeInterval: 3)
        
        sidebarButton.tap()
        contactsButton.tap()
        
        let cells = app.tables.staticTexts.containing(label: sampleContact)
        cells.allElementsBoundByIndex.first?.tap()
        tablesQuery.cells.staticTexts[shareContactLabel].tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        if #available(iOS 13.0, *) {
            app.navigationBars["UIActivityContentView"].buttons[closeLabel].tap()
        } else {
            app.buttons[cancelLabel].tap()
        }
        
        XCTAssertTrue(tablesQuery.staticTexts[notesLabel].exists)
        
        app.tables.children(matching: .button).element(boundBy: 0).tap()
        Thread.sleep(forTimeInterval: 1.5)
        
        if #available(iOS 13.0, *) {
            // 'From' action sheet fails on iOS 13
        } else {
            tablesQuery.staticTexts[mainTestEmail].tap()
            app.sheets["Change sender address to..."].buttons[mainTestEmail].tap()
            
        }
        
    }

}
