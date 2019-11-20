//
//  contactTests.swift
//  ProtonMail - Created on 7/5/19.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
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
        
        if #available(iOS 13.0, *) {
            
            //skip
            
        } else {
            
            tablesQuery.cells.staticTexts[shareContactLabel].tap()
            Thread.sleep(forTimeInterval: 0.5)
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
