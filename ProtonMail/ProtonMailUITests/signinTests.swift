//
//  signinTests.swift
//  ProtonMail - Created on 7/4/19.
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

class signinTests: XCTestCase {

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

    func testOnePasswordLogoutLogin() {
        
        Thread.sleep(forTimeInterval: 3)
        
        signOut()
        
        loginAsserts()
        
        signIn(twoPasswordMode: false)
        
    }
    
    func testTwoPasswordLoginLogout() {
        
        Thread.sleep(forTimeInterval: 3)
        
        signOut()
        
        loginAsserts()
        
        signIn(twoPasswordMode: true)
        
        Thread.sleep(forTimeInterval: 3)
        
        // Logout from two-password mode
        
        signOut()
    }
    
    func testFailedLogin() {
        
        let username = "xcodetest123456"
        let password = "111"
        
        Thread.sleep(forTimeInterval: 1)
        
        signOut()
        
        SignInPage.txtUsername.element.tap()
        SignInPage.txtUsername.element.typeText(username)
        
        SignInPage.txtPassword.element.tap()
        SignInPage.txtPassword.element.typeText(password)
        
        SignInPage.loginButton.element.tap()
        
        Thread.sleep(forTimeInterval: 1)
        
        let alert = app.alerts["Alert"]
        XCTAssertTrue(alert.staticTexts["Authentication failed: wrong username or password."].exists)
        Thread.sleep(forTimeInterval: 1)
        alert.buttons["OK"].tap()
        
        loginAsserts()
    }
    
    func loginAsserts() {
        
        XCTAssertTrue(SignInPage.title.element.exists)
        XCTAssertTrue(SignInPage.txtUsername.element.exists)
        XCTAssertTrue(SignInPage.txtPassword.element.exists)
        XCTAssertTrue(SignInPage.pmLogo.element.exists)
        XCTAssertTrue(SignInPage.showLoginPassword.element.exists)
        XCTAssertTrue(SignInPage.signUpButton.element.exists)
        XCTAssertTrue(SignInPage.forgotPasswordButton.element.exists)
        XCTAssertTrue(SignInPage.languageButton.element.exists)
        XCTAssertTrue(SignInPage.versionLabel.element.exists)
        
    }

}
