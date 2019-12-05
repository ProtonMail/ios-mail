//
//  helperFunctions.swift
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

let app = XCUIApplication()
let tablesQuery = app.tables

let addFolderButton = app.buttons["Add Folder"]
let addLabelButton = app.buttons["Add Label"]

let sampleFolder = "Folder"
let sampleLabel = "Label"

let emailToSwipe = tablesQuery.staticTexts["Fwd: QNAP Launches the TR-004U, a 4-bay 1U short-depth rackmount RAID Storage Expansion Device for NAS, PC and servers"]
let undoButton = app.buttons["Undo"]
let createButton = app.buttons["Create"]
let applyButton = app.buttons["Apply"]

let sectionIndexTable = app.tables.containing(.other, identifier:"Section index").element
let tableIndexTable = app.tables.containing(.other, identifier:"table index").element

let contactGroupWindowiOS13 =  app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .table).element

let contactGroupWindow =  app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .table).element

let addContactLabel = "Add Contact"
let saveContactNavButton = app.navigationBars[addContactLabel].buttons["Save"]
let deleteContact = tablesQuery.staticTexts[deleteContactLabel]
let deleteContactLabel = "Delete Contact"
let continueButton = app.buttons["Continue"]

let shareContactLabel = "Share Contact"
let notesLabel = "Notes"

let inboxNavigationBar = app.navigationBars[inbox]

let manageFoldersLabels = app.tables.staticTexts["Manage Labels/Folders"]
let noMessagesText = app.staticTexts["No Messages"]

let folderNavigationBar = app.navigationBars["Folder"]

let inbox = "Inbox"
let sidebarButton = app.navigationBars[inbox].buttons["sidebarButton"]
let sidebarButtonLabel = "sidebarButton"
let settingsButton = app.tables.staticTexts["Settings"]
let searchLabel = "Search"
let menu = "Menu"
let reportBugs = app.tables.staticTexts[reportBugsLabel]
let reportBugsLabel = "Report Bugs"
let logoutText = "Logout"
let logoutButton = "Log out" //
let logoutMessage = "Are you sure you want to logout?"
let moreButton = "More"
let viewHeadersButton = "View Headers"
let copyButton = "Copy"
let doneButton = app.buttons[doneLabel]
let doneLabel = "Done"
let printButton = "Print"
let backButton = "Back"
let trashButton = "Trash"
let replyButton = "Reply"
let deleteButton = app.buttons[deleteLabel]
let deleteLabel = "Delete"
let editLabel = "Edit"

let emailAddressesText = "Email Addresses"

let mainTestEmail = "xcodeui@protonmail.com"
let testEmail = "test@test.com"

let premiumFeatureText = "PREMIUM FEATURE"

let group01 = "Group 01"
let emptyGroupText = "0 Member"

let notificationEmail = app.tables.staticTexts["Notification email"]
let notificationEmailBackButton = app.navigationBars["Notification email"].buttons["Back"]

let singlePassword = tablesQuery.staticTexts["Single Password"]
let passwordBackButton = app.navigationBars["Password"].buttons["Settings"]

let contactsLabel = "Contacts"
let addLabel = "Add"
let cancelLabel = "Cancel"
let closeLabel = "Close"
let contactsButton = app.tables.staticTexts["Contacts"]
let testContact = "Test Name"
let sampleContact = "Sample Contact"
let groupsLabel = "Groups"
let emptyListGroups = "Empty list"
let sampleContactPartial = "sam"

let closePremiumAdButton = app.buttons["notNowPremiumAd"]

let closeTourButton = "closeTour"
let onboardingSubject = "Welcome to ProtonMail"

let sampleMessageSubject = "Self test"
let sampleMessageSubjectReply = "Re: Self test"
let sampleMessageBody = "Self test 2"
let sampleMessageInlineImage = "download.jpeg"
let sampleMessageHeaderSubject = "headers-2019-03-15T09:49:42-Self-test"
let sampleMessagePrintSubject = "Self-test"


enum SignInPage: String {
    
    case txtUsername
    case txtPassword
    case title
    case loginButton
    case showLoginPassword
    case pmLogo
    case signUpButton
    case forgotPasswordButton
    case languageButton
    case versionLabel
    var element: XCUIElement {
        switch self {
        case .txtUsername:
            return XCUIApplication().textFields["txtUsername"]
        case .txtPassword:
            return XCUIApplication().secureTextFields["txtPassword"]
        case .title:
            return XCUIApplication().staticTexts["signInTitle"]
        case .loginButton:
            return XCUIApplication().buttons["loginButton"]
        case .showLoginPassword:
            return XCUIApplication().buttons["showLoginPassword"]
        case .pmLogo:
            return XCUIApplication().images["pmLogo"]
        case .signUpButton:
            return XCUIApplication().buttons["signUpButton"]
        case .forgotPasswordButton:
            return XCUIApplication().buttons["forgotPasswordButton"]
        case .languageButton:
            return XCUIApplication().buttons["languageButton"]
        case .versionLabel:
            return XCUIApplication().staticTexts["versionLabel"]
        }
    }
}

enum decryptPage: String {
    case decryptButton
    case txtDecryptPassword
    case showPasswordButton
    case resetMailboxPassword
    var element: XCUIElement {
        switch self {
        case .decryptButton:
            return XCUIApplication().buttons["decryptButton"]
        case .txtDecryptPassword:
            return XCUIApplication().secureTextFields["txtDecryptPassword"]
        case .showPasswordButton:
            return XCUIApplication().buttons["showPasswordButton"]
        case .resetMailboxPassword:
            return XCUIApplication().buttons["resetMailboxPassword"]
        }
    }
}

func signOut() {
    
    sidebarButton.tap()
    
    Thread.sleep(forTimeInterval: 1)
    
    app.tables.staticTexts[logoutText].tap()
    
    if #available(iOS 13.0, *) {
        app.sheets[logoutMessage].scrollViews.otherElements.buttons[logoutButton].tap()
    } else {
        app.sheets[logoutMessage].buttons[logoutButton].tap()
    }
    
    Thread.sleep(forTimeInterval: 2)
    
}

func signIn(twoPasswordMode: Bool) {
    
    let username = "xcodeui"
    let password = "xcode12345!"
    
    let username2 = "xcodeui.2"
    let password2 = "Xcode12345!"
    
    // Check if decrypt mailbox view is active
    let elementsQuery = XCUIApplication().scrollViews.otherElements
    
    if elementsQuery.buttons["top back"].exists {
        elementsQuery.buttons["top back"].tap()
    }
    
    Thread.sleep(forTimeInterval: 3)
    
    if twoPasswordMode == false {
        
        SignInPage.txtUsername.element.tap()
        SignInPage.txtUsername.element.typeText(username)
        
        SignInPage.txtPassword.element.tap()
        SignInPage.txtPassword.element.typeText(password)
        
        SignInPage.loginButton.element.tap()
        
    } else {
        
        SignInPage.txtUsername.element.tap()
        SignInPage.txtUsername.element.typeText(username2)
        
        SignInPage.txtPassword.element.tap()
        SignInPage.txtPassword.element.typeText(password2)
        
        SignInPage.loginButton.element.tap()
        
        //Mailbox decryption view:
        app.secureTextFields["txtMailboxPassword"].tap()
        app.typeText(password2)
        app.buttons["showMailboxPassButton"].tap()
        app.buttons["decryptButton"].tap()
        
    }
    
    Thread.sleep(forTimeInterval: 3)
    
    if app.scrollViews.otherElements.staticTexts[onboardingSubject].exists {
        app.buttons[closeTourButton].tap()
    }
}

func AllowNotifications() {
    let systemAlerts = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts
    if systemAlerts.buttons["Don’t Allow"].exists {
        systemAlerts.buttons["Don’t Allow"].tap()
    }
}

extension XCUIApplication {
    func filterCells(containing labels: String...) -> XCUIElementQuery {
        var cells = self.cells
        
        for label in labels {
            cells = cells.containing(NSPredicate(format: "label CONTAINS %@", label))
        }
        return cells
    }
}

class Springboard {
    
    static let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    
    // Terminate and delete the app via springboard
    
    class func deleteMyApp() {
        XCUIApplication().terminate()
        
        // Force delete the app from the springboard
        let icon = springboard.icons["ProtonMail"]
        if icon.exists {
            let iconFrame = icon.frame
            let springboardFrame = springboard.frame
            icon.press(forDuration: 2.0)
            
            springboard.coordinate(withNormalizedOffset: CGVector(dx: (iconFrame.minX + 3) / springboardFrame.maxX, dy: (iconFrame.minY + 3) / springboardFrame.maxY)).tap()
            
            Thread.sleep(forTimeInterval: 2)
            
            springboard.alerts.buttons[deleteLabel].tap()
            
            Thread.sleep(forTimeInterval: 1)
            
            XCUIDevice.shared.press(.home)
        }
    }
}
