//
//  ProtonMailUITests.swift
//  ProtonMail - Created on 3/12/19.
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
        //default: break
        }
    }
}

class ProtonMailUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
        //app.launchArguments.append("isUITestingLogin")
        XCUIApplication().launch()
    }

    override func tearDown() {
        super.tearDown()
 }

    func testSignInSinglePassword() {
        
        //let app = XCUIApplication()
        
        let username = "xcodeui"
        let password = "xcode12345!"
        
        let systemAlerts = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts
        if systemAlerts.buttons["Allow"].exists {
            systemAlerts.buttons["Allow"].tap()
        }
        
        Thread.sleep(forTimeInterval: 5)
        
        XCTAssertTrue(SignInPage.title.element.exists)
        XCTAssertTrue(SignInPage.txtUsername.element.exists)
        XCTAssertTrue(SignInPage.txtPassword.element.exists)

        SignInPage.txtUsername.element.tap()
        SignInPage.txtUsername.element.typeText(username)
        
        SignInPage.txtPassword.element.tap()
        SignInPage.txtPassword.element.typeText(password)
        
        SignInPage.loginButton.element.tap()
    }

}
