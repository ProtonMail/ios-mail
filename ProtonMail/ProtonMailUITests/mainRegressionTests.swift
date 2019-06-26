//
//  mainRegressionTests.swift
//  ProtonMail - Created on 6/19/19.
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

let app = XCUIApplication()
let tablesQuery = app.tables

let inbox = "Inbox"
let sidebarButton = "sidebarButton"
let settingsButton = "Settings"
let menu = "Menu"
let reportBugs = "Report Bugs"
let logoutText = "Logout"
let logoutButton = "Log out" //
let logoutMessage = "Are you sure you want to logout?"
let moreButton = "More"
let viewHeadersButton = "View Headers"
let copyButton = "Copy"
let doneButton = "Done"
let printButton = "Print"
let backButton = "Back"
let trashButton = "Trash"
let replyButton = "Reply"
let deleteButton = "Delete"

let contactsButton = "Contacts"
let sampleContact = "Sample Contact"
let groupsButton = "Groups"
let emptyListGroups = "Empty list"
let sampleContactPartial = "sam"

let closeTourButton = "closeTour"
let onboardingSubject = "Welcome to ProtonMail"

let sampleMessageSubject = "Self test"
let sampleMessageSubjectReply = "Re: Self test"
let sampleMessageBody = "Self test 2"
let sampleMessageInlineImage = "download.jpeg"
let sampleMessageHeaderSubject = "2019-03-15T09:49:42-Self-test"
let sampleMessagePrintSubject = "Self-test"


enum SignInPage: String {
    
    case txtUsername
    case txtPassword
    case title
    case loginButton
    case resetLoginPassword
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
        case .resetLoginPassword:
            return XCUIApplication().buttons["resetLoginPassword"]
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

extension XCUIApplication {
    func filterCells(containing labels: String...) -> XCUIElementQuery {
        var cells = self.cells
        
        for label in labels {
            cells = cells.containing(NSPredicate(format: "label CONTAINS %@", label))
        }
        return cells
    }
}

class mainRegressionTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = true
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        
        AllowNotifications()
        
        Thread.sleep(forTimeInterval: 2)
        
        if SignInPage.txtUsername.element.exists {
            
            signInLogin()
            
        }
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        app.terminate()
        
        super.tearDown()
        
    }
    
    func testLogoutLogin() {
        
        Thread.sleep(forTimeInterval: 3)
        
        app.navigationBars[inbox].buttons[sidebarButton].tap()
        
        app.tables.staticTexts[logoutText].tap()
        
        if #available(iOS 13.0, *) {
            app.sheets[logoutMessage].scrollViews.otherElements.buttons[logoutButton].tap()
        } else {
            app.sheets[logoutMessage].buttons[logoutButton].tap()
        }
        
        Thread.sleep(forTimeInterval: 2)
        
        loginAsserts()
        
        signInLogin()
        
    }
    
    func loginAsserts() {
        
        XCTAssertTrue(SignInPage.title.element.exists)
        XCTAssertTrue(SignInPage.txtUsername.element.exists)
        XCTAssertTrue(SignInPage.txtPassword.element.exists)
        XCTAssertTrue(SignInPage.pmLogo.element.exists)
        XCTAssertTrue(SignInPage.resetLoginPassword.element.exists)
        XCTAssertTrue(SignInPage.signUpButton.element.exists)
        XCTAssertTrue(SignInPage.forgotPasswordButton.element.exists)
        XCTAssertTrue(SignInPage.languageButton.element.exists)
        XCTAssertTrue(SignInPage.versionLabel.element.exists)
        
    }
    
    func testReadMessageAndReply() {
        
        // Read message
        tablesQuery.staticTexts[sampleMessageSubject].tap()
        Thread.sleep(forTimeInterval: 5)
        XCTAssert(app.staticTexts[sampleMessageBody].exists)
        XCTAssert(app.images[sampleMessageInlineImage].exists)
        
        // Check headers and print preview
        app.navigationBars[inbox].buttons[moreButton].tap()
        app.sheets.buttons[viewHeadersButton].tap()
        
        app.otherElements["QLPreviewControllerView"].children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .textView).element.press(forDuration: 1.2);
        app.menuItems[copyButton].tap()
        
        let navigationBar = app.navigationBars[sampleMessageHeaderSubject]
        navigationBar.buttons[doneButton].tap()
        app.navigationBars[inbox].buttons[moreButton].tap()
        
        app.sheets.buttons[printButton].tap()
        
        XCTAssert(app.staticTexts[sampleMessageBody].exists)
        
        app.navigationBars[sampleMessagePrintSubject].buttons[doneButton].tap()
        
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
        
        // Send message
        app.navigationBars["ProtonMail.ComposeContainerView"].children(matching: .button).element(boundBy: 1).tap()
        
        // Inbox management
        Thread.sleep(forTimeInterval: 5)
        
        let inboxNavigationBar = app.navigationBars[inbox]
        
        if #available(iOS 11.0, *) {
            inboxNavigationBar.buttons[inbox].tap()
            
        } else {
            inboxNavigationBar.buttons[backButton].tap()
        }
        
        tablesQuery.staticTexts[sampleMessageSubjectReply].press(forDuration: 1.5);
        app.navigationBars.buttons[trashButton].tap()
        
    }
    
    
    func testContactsRefresh() {
        
        Thread.sleep(forTimeInterval: 3)
        
        app.navigationBars[inbox].buttons[sidebarButton].tap()
        
        app.tables.staticTexts[contactsButton].tap()
        
        if #available(iOS 13.0, *) {
            let sectionIndexTable = app.tables.containing(.other, identifier:"Section index").element
            sectionIndexTable.swipeDown()
        } else {
            let tableIndexTable = app.tables.containing(.other, identifier:"table index").element
            tableIndexTable.swipeDown()
        }
        
        app.tabBars.buttons[groupsButton].tap()
        app.tables[emptyListGroups].swipeDown()
        app.navigationBars[groupsButton].buttons[menu].tap()
        
    }
    
    func testSettingsView() {
        
        Thread.sleep(forTimeInterval: 3)
        
        app.navigationBars[inbox].buttons[sidebarButton].tap()
        
        app.tables.staticTexts[settingsButton].tap()
        
    }
    
    func testBugReportsView() {
        
        Thread.sleep(forTimeInterval: 3)
        
        app.navigationBars[inbox].buttons[sidebarButton].tap()
        
        app.tables.staticTexts[reportBugs].tap()
        
        app.navigationBars[reportBugs].buttons[menu].tap()
        
    }
    
    func signInLogin() {
        
        let username = "xcodeui"
        let password = "xcode12345!"
        
        Thread.sleep(forTimeInterval: 3)
        
        SignInPage.txtUsername.element.tap()
        SignInPage.txtUsername.element.typeText(username)
        
        SignInPage.txtPassword.element.tap()
        SignInPage.txtPassword.element.typeText(password)
        
        SignInPage.loginButton.element.tap()
        
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
            
            springboard.alerts.buttons[deleteButton].tap()
            
            Thread.sleep(forTimeInterval: 1)
            
            XCUIDevice.shared.press(.home)
        }
    }
}
