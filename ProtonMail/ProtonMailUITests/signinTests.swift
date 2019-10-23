//
//  signinTests.swift
//  ProtonMail - Created on 7/4/19.
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
