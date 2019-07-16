//
//  searchTests.swift
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
