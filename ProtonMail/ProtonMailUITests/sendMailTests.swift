//
//  sendMailTests.swift
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
