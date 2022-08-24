//
//  signinTests.swift
//  Proton Mail - Created on 7/4/19.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_TestingToolkit

class LoginTests: BaseTestCase {
    
    private let loginRobot = LoginRobot()

    func testLoginWithOnePass() {
        app.launchEnvironment["MAIL_APP_API_DOMAIN"] = ProcessInfo.processInfo.environment["MAIL_APP_API_DOMAIN"]
        app.launchEnvironment["MAIL_APP_API_PATH"] = ProcessInfo.processInfo.environment["MAIL_APP_API_PATH"]
        let user = testData.onePassUser
        loginRobot
            .loginUser(user)
            .verify.inboxShown()
    }

    func testLoginWithTwoPass() {
        let user = testData.twoPassUser
        loginRobot
            .loginTwoPasswordUser(user)
            .verify.inboxShown()
    }
    
    func testLoginWithOnePassAnd2FA() {
        let user = testData.onePassUserWith2Fa
        loginRobot
            .loginUserWithTwoFA(user)
            .verify.inboxShown()
    }
    
    func testLoginWithTwoPassAnd2FA() {
        let user = testData.twoPassUserWith2Fa
        loginRobot
            .loginTwoPasswordUserWithTwoFA(user)
            .verify.inboxShown()
    }
    
    func testLoginWithInvalidPassword() {
        let user = testData.onePassUser
        loginRobot
            .loginWithInvalidPassword(user)
            .verify.incorrectCredentialsErrorDialog()
    }
    
    func testLoginWithInvalidUserAndPassword() {
        let user = testData.onePassUser
        loginRobot
            .loginWithInvalidUserAndPassword(user)
            .verify.incorrectCredentialsErrorDialog()
    }
    
    func testLoginWithInvalidUser() {
        let user = testData.onePassUser
        loginRobot
            .loginWithInvalidUser(user)
            .verify.incorrectCredentialsErrorDialog()
    }
    
    func testLoginWithInvalid2Pass() {
        let user = testData.twoPassUser
        loginRobot
            .loginTwoPasswordUserWithInvalid2Pass(user)
            .verify.incorrectMailboxPasswordErrorDialog()
    }
}
