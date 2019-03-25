//
//  SignInTests.swift
//  ProtonMail - Created on 3/15/19.
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

class SignInTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        Thread.sleep(forTimeInterval: 5)
        
        AllowNotifications()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        Springboard.deleteMyApp() // temp. solution until Main.storyboard can be edited to have accessibility identifiers
        
        super.tearDown()
        
    }

    func testSignInSinglePassword() {
        
        XCTAssertTrue(SignInPage.title.element.exists)
        XCTAssertTrue(SignInPage.txtUsername.element.exists)
        XCTAssertTrue(SignInPage.txtPassword.element.exists)
        XCTAssertTrue(SignInPage.pmLogo.element.exists)
        XCTAssertTrue(SignInPage.resetLoginPassword.element.exists)
        XCTAssertTrue(SignInPage.signUpButton.element.exists) // remove once sign-up tests are created
        XCTAssertTrue(SignInPage.forgotPasswordButton.element.exists)
        XCTAssertTrue(SignInPage.languageButton.element.exists)
        XCTAssertTrue(SignInPage.versionLabel.element.exists)
        
        //let app = XCUIApplication()
        signInLogin()
        
    }
    
//    func testSignInTwoPassword() {
//
//        signInLogin()
//        signInMailbox ()
//
//    }
    
    func signInLogin() {
        
        let username = "xcodeui"
        let password = "xcode12345!"
        
        SignInPage.txtUsername.element.tap()
        SignInPage.txtUsername.element.typeText(username)
        
        SignInPage.txtPassword.element.tap()
        SignInPage.txtPassword.element.typeText(password)
        
        SignInPage.loginButton.element.tap()
    }
    
//    func signInMailbox() {
//
//        let decryptPassword = "xcode12345!"
//
//        decryptPage.txtDecryptPassword.element.tap()
//        decryptPage.txtDecryptPassword.element.typeText(decryptPassword)
//        decryptPage.decryptButton.element.tap()
//
//        Thread.sleep(forTimeInterval: 5)
//
//    }
    
    func AllowNotifications() {
        let systemAlerts = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts
        if systemAlerts.buttons["Allow"].exists {
            systemAlerts.buttons["Allow"].tap()
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
            icon.press(forDuration: 1.3)
            
            springboard.coordinate(withNormalizedOffset: CGVector(dx: (iconFrame.minX + 3) / springboardFrame.maxX, dy: (iconFrame.minY + 3) / springboardFrame.maxY)).tap()
            
            Thread.sleep(forTimeInterval: 2)
            
            springboard.alerts.buttons["Delete"].tap()
            
            XCUIDevice.shared.press(.home)
        }
    }
}
