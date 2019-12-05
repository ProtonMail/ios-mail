//
//  mainRegressionTests.swift
//  ProtonMail - Created on 6/19/19.
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

class mainRegressionTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        
        AllowNotifications()
        
        Thread.sleep(forTimeInterval: 2)
        
        if SignInPage.txtUsername.element.exists {
            
            signIn(twoPasswordMode: false)
   
        }
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        app.terminate()
        
        super.tearDown()
        
    }

    func testSettingsView() {
        
        Thread.sleep(forTimeInterval: 3)
        
        sidebarButton.tap()
        
        settingsButton.tap()
        
        notificationEmail.tap()
        notificationEmailBackButton.tap()
        
        singlePassword.tap()
        passwordBackButton.tap()
        
    }
    
    func testBugReportsView() {
        
        Thread.sleep(forTimeInterval: 3)
        
        sidebarButton.tap()
        
        reportBugs.tap()
        
        app.navigationBars[reportBugsLabel].buttons[menu].tap()
        
    }
    
    func testCreateDeleteGroup() {
        
        Thread.sleep(forTimeInterval: 3)
        
        sidebarButton.tap()
        
        contactsButton.tap()
        
        app.tabBars.buttons[groupsLabel].tap()
        
        let groupsNavigationBar = app.navigationBars[groupsLabel]
        groupsNavigationBar.buttons[addLabel].tap()
        app.sheets["Select An Option"].buttons["Add Group"].tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(app.staticTexts[premiumFeatureText].exists)
        closePremiumAdButton.tap()
        
    }
    
    func testLeftRightSwipeAndUndo() {
        
        Thread.sleep(forTimeInterval: 2)
        
        emailToSwipe.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)
        undoButton.tap()
        emailToSwipe.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
        undoButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        XCTAssertTrue(emailToSwipe.exists)
        
    }
    
    func testAddRemoveLabelFolder() {
        
        var doneClicked = false
        
        Thread.sleep(forTimeInterval: 3)
        
        sidebarButton.tap()
        
        settingsButton.tap()
        manageFoldersLabels.tap()
        
        if (tablesQuery.staticTexts["  Folder  "].exists == true) {
 
        } else {
            addFolderButton.tap()
            
            app.textFields["Folder Name"].tap()
            app.typeText(sampleFolder)
            
            Thread.sleep(forTimeInterval: 2)
            
            if  doneButton.exists {
                doneButton.tap()
                doneClicked = true
            }
            
            createButton.tap()
        }

        if (tablesQuery.staticTexts["  Label  "].exists == true) {
            
        } else {
            addLabelButton.tap()
            
            app.textFields["Label Name"].tap()
            app.typeText(sampleLabel)
            
            Thread.sleep(forTimeInterval: 2)
            
            if #available(iOS 13.0, *) {
                if  doneButton.exists {
                    doneButton.tap()
                }} else {
                if  doneButton.exists && doneClicked == false {
                    doneButton.tap()
                    doneClicked = true
                }
            }
        
            createButton.tap()
    }

        tablesQuery.cells.containing(.staticText, identifier:"  Folder  ").buttons["mail check"].tap()
        tablesQuery.cells.containing(.staticText, identifier:"  Label  ").buttons["mail check"].tap()
        
        deleteButton.tap()
        
        manageFoldersLabels.tap()
        
        Thread.sleep(forTimeInterval: 1)
        
        XCTAssertFalse(tablesQuery.cells.containing(.staticText, identifier:"  Label  ").buttons["mail check"].exists)
        XCTAssertFalse(tablesQuery.cells.containing(.staticText, identifier:"  Folder  ").buttons["mail check"].exists)
    }
    
    func testEmailMoveBetweenFolders() {
    
        var doneClicked = false
        
        Thread.sleep(forTimeInterval: 3)
        
        let navigationBarsQuery = app.navigationBars
        let moveToButton = navigationBarsQuery.buttons["Move to..."]
        
        emailToSwipe.press(forDuration: 1.5);
        
        navigationBarsQuery.buttons["Label as..."].tap()
        
        Thread.sleep(forTimeInterval: 1)
        
        if (tablesQuery.staticTexts["  Label  "].exists == false) {
            addLabelButton.tap()
            app.textFields["Label Name"].tap()
            app.typeText(sampleLabel)
            
            Thread.sleep(forTimeInterval: 2)
            
            // Disable hardware keyboard in simulator if this part fails
            if  doneButton.exists {
                doneButton.tap()
                doneClicked = true
            }
            
            createButton.tap()
            
            tablesQuery.cells.containing(.staticText, identifier:"  Label  ").buttons["mail check"].tap()
            
        } else if tablesQuery.cells.containing(.staticText, identifier:"  Label  ").buttons["mail check"].exists {
            tablesQuery.cells.containing(.staticText, identifier:"  Label  ").buttons["mail check"].tap()
        }
        
        applyButton.tap()
        
        emailToSwipe.press(forDuration: 1.5);
        
        moveToButton.tap()
        
        if tablesQuery.cells.containing(.staticText, identifier:"  Folder  ").buttons["mail check"].exists {
            
            tablesQuery.cells.containing(.staticText, identifier:"  Folder  ").buttons["mail check"].tap()
            
        } else {
            
            addFolderButton.tap()
            app.textFields["Folder Name"].tap()
            app.typeText(sampleFolder)
            
            Thread.sleep(forTimeInterval: 2)
            
            if #available(iOS 13.0, *) {
                if  doneButton.exists {
                    doneButton.tap()
                } else {
                    if  doneButton.exists && doneClicked == false {
                        doneButton.tap()
                        doneClicked = true
                    }
                }
            }
            createButton.tap()
            tablesQuery.cells.containing(.staticText, identifier:"  Folder  ").buttons["mail check"].tap()
            
        }
       
        applyButton.tap()
        sidebarButton.tap()
        app.tables.staticTexts[sampleFolder].tap()
        
        emailToSwipe.tap()
        folderNavigationBar.buttons[moreButton].tap()
        app.sheets.buttons["Move to Inbox"].tap()
        
        Thread.sleep(forTimeInterval: 2)
        
        app.tables["Empty list"].swipeDown()
        
        Thread.sleep(forTimeInterval: 2)
        
        XCTAssertTrue(noMessagesText.exists)
        
        app.navigationBars[sampleFolder].buttons[sidebarButtonLabel].tap()
        app.tables.staticTexts[inbox].tap()

        XCTAssertTrue(emailToSwipe.exists)
        
        // Move to seperate test:
        // removeFolderLabel()
        
    }
    
    func testSidebarButtons() {
        
        Thread.sleep(forTimeInterval: 3)
        
        sidebarButton.tap()
        
        app.tables.staticTexts["Drafts"].tap()
        app.navigationBars["Drafts"].buttons[sidebarButtonLabel].tap()
        app.tables.staticTexts["Sent"].tap()
        app.navigationBars["Sent"].buttons[sidebarButtonLabel].tap()
        app.tables.staticTexts["Starred"].tap()
        app.navigationBars["Starred"].buttons[sidebarButtonLabel].tap()
        app.tables.staticTexts["Archive"].tap()
        app.navigationBars["Archive"].buttons[sidebarButtonLabel].tap()
        app.tables.staticTexts["Spam"].tap()
        app.navigationBars["Spam"].buttons[sidebarButtonLabel].tap()
        app.tables.staticTexts["Trash"].tap()
        app.navigationBars["Trash"].buttons[sidebarButtonLabel].tap()
        app.tables.staticTexts["All Mail"].tap()
        app.navigationBars["All Mail"].buttons[sidebarButtonLabel].tap()
        app.tables.staticTexts["Subscription"].tap()

    }
    
    func removeFolderLabel() {
        
        // Remove any leftover folders and labels
        
        sidebarButton.tap()
        
        settingsButton.tap()
        manageFoldersLabels.tap()
        
        if tablesQuery.cells.containing(.staticText, identifier:"  Label  ").buttons["mail check"].exists {
            tablesQuery.cells.containing(.staticText, identifier:"  Label  ").buttons["mail check"].tap()
        }
        if tablesQuery.cells.containing(.staticText, identifier:"  Folder  ").buttons["mail check"].exists {
            tablesQuery.cells.containing(.staticText, identifier:"  Folder  ").buttons["mail check"].tap()
        }
        deleteButton.tap()
        
    }
    
}
