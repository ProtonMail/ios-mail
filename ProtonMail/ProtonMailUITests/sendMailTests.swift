//
//  sendMailTests.swift
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

class sendMailTests: XCTestCase {

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

    func testReadMessageAndReply() {
        
        // Read message
        tablesQuery.staticTexts[sampleMessageSubject].tap()
        Thread.sleep(forTimeInterval: 5)
        XCTAssert(app.staticTexts[sampleMessageBody].exists)
        XCTAssert(app.images[sampleMessageInlineImage].exists)
        
        
        if #available(iOS 10.0, *) {
        
        app.navigationBars["ProtonMail.MessageContainerView"].buttons["More"].tap()
            
        } else {
            
        app.navigationBars[inbox].buttons[moreButton].tap()
        
        }
        
        // Check headers and print preview
        
        app.sheets.buttons[viewHeadersButton].tap()
        
        Thread.sleep(forTimeInterval: 2)
        
        if #available(iOS 10.0, *) {
            
            app.navigationBars[sampleMessageHeaderSubject].buttons["Done"].tap()
              
        } else {
        app.navigationBars[sampleMessageHeaderSubject].buttons["QLOverlayDoneButtonAccessibilityIdentifier"].tap()
            
        }

       if #available(iOS 10.0, *) {
        
        app.navigationBars["ProtonMail.MessageContainerView"].buttons["More"].tap()
            
        } else {
            
        app.navigationBars[inbox].buttons[moreButton].tap()
        
        }
        
        app.sheets.buttons[printButton].tap()
        
        if #available(iOS 13.0, *) {
            
            // This part currently fails on iOS 13 beta
            
        } else {
            
            XCTAssert(app.staticTexts[sampleMessageBody].exists)
        
        }
        
        Thread.sleep(forTimeInterval: 5)
        
        app.navigationBars["Printer Options"].buttons["Cancel"].tap()
        
        // Prepare composer
        app.buttons[replyButton].tap()
        
        if #available(iOS 13.0, *) {
            app.tables.cells.containing(.button, identifier:"compose lock").children(matching: .textField).element(boundBy: 1).tap()
        }
        else if #available(iOS 11.0, *) {
            app.tables.cells.containing(.button, identifier:"mail attachment closed").children(matching: .textField).element(boundBy: 2).tap()
        }
        else if #available(iOS 10.0, *) {
            Thread.sleep(forTimeInterval: 2)
            let mailAttachmentClosedCellsQuery = app.tables.cells.containing(.button, identifier:"mail attachment closed")
            mailAttachmentClosedCellsQuery.children(matching: .textField).element(boundBy: 4).tap()
            
        }
        
        app.typeText(sampleContactPartial)
        
        app.children(matching: .window).element(boundBy: 0).tables.children(matching: .cell).element(boundBy: 0).staticTexts[sampleContact].tap()
        
        Thread.sleep(forTimeInterval: 8) // Timer for contact verification
        
        // Send message
        app.navigationBars["ProtonMail.ComposeContainerView"].children(matching: .button).element(boundBy: 1).tap()
        
        // Inbox management
        Thread.sleep(forTimeInterval: 5)
  
        if #available(iOS 11.0, *) {
            
        app.navigationBars["ProtonMail.MessageContainerView"].buttons[inbox].tap()
            
        }
            
        else if #available(iOS 10.0, *) {
            
        app.navigationBars["ProtonMail.MessageContainerView"].buttons["Back"].tap()
            
        }
            
        else {
            
            inboxNavigationBar.buttons[backButton].tap()
        
        }

        tablesQuery.staticTexts[sampleMessageSubjectReply].press(forDuration: 1.5);
        app.navigationBars.buttons[trashButton].tap()
        
    }

}
