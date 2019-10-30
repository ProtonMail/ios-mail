//
//  searchTests.swift
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

class searchTests: XCTestCase {

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

    func testSearchForMessage() {
        
        app.navigationBars[inbox].buttons[searchLabel].tap()
        app.textFields[searchLabel].tap()
        app.typeText("Qnap")
        
        Thread.sleep(forTimeInterval: 0.5)
        
        if continueButton.exists {
            continueButton.tap()
        }
        
        //Enable hardware keyboard if this part fails
        app.keyboards.buttons[searchLabel].tap()
        
        Thread.sleep(forTimeInterval: 3)
        
        if #available(iOS 13.0, *) {
            
            XCTAssertTrue(emailToSwipe.exists)
            
            // iOS 13 beta currently fails afterwards
            
        } else {
            
            emailToSwipe.tap()
            
            Thread.sleep(forTimeInterval: 1)
            
            app.navigationBars["ProtonMail.MessageContainerView"].buttons[backButton].tap()
            
            Thread.sleep(forTimeInterval: 1)
            
            app.buttons[cancelLabel].tap()
            
            Thread.sleep(forTimeInterval: 1)
            
            XCTAssertTrue(emailToSwipe.exists)
        }
    }
    
    func testSearchForContact() {
        
        Thread.sleep(forTimeInterval: 3)
        
        sidebarButton.tap()
        
        app.tables.staticTexts[contactsLabel].tap()
        
        app.searchFields[searchLabel].tap()
        
        app.typeText(sampleContact)
        
        Thread.sleep(forTimeInterval: 0.5)
        
        app.tables.staticTexts[sampleContact].tap()
        
        Thread.sleep(forTimeInterval: 1)
        
        XCTAssertTrue(tablesQuery.staticTexts[emailAddressesText].exists)
        
    }
    
    func testSearchForGroup() {
        
        Thread.sleep(forTimeInterval: 3)
        
        sidebarButton.tap()
        
        app.tables.staticTexts[contactsLabel].tap()
        
        app.tabBars.buttons[groupsLabel].tap()
        
        app.searchFields[searchLabel].tap()
        
        app.typeText(group01)
        
        app.tables.staticTexts[group01].tap()
        
        Thread.sleep(forTimeInterval: 1)
        
        XCTAssertTrue(app.staticTexts[group01].exists)
        XCTAssertTrue(app.staticTexts[emptyGroupText].exists)
        
        if #available(iOS 13.0, *) {
            
        } else {
            
            app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element.tap()
            
            closePremiumAdButton.tap()
        }
        
        app.navigationBars["Group Details"].buttons[editLabel].tap()
        closePremiumAdButton.tap()
        
    }

}
