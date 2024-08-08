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

import ProtonCoreTestingToolkitUITestsLogin

class LoginTests: BaseTestCase {

    private let loginRobot = LoginRobot()

    func testTryToLoginWithInvalidPassword() {
        let freeUser = users["free"]!

        loginRobot
            .loginWithInvalidPassword(freeUser)
            .verify.incorrectCredentialsErrorDialog()
    }
    
    /**
     Below test cases cannot be automated without proper test data.
     They should be enabled after test data will be in place.
     */
    func xtestLoginWithTwoPass() {
        let user = testData.twoPassUser
        loginRobot
            .loginTwoPasswordUser(user)
            .verify.inboxShown()
    }

    func xtestLoginWithOnePassAnd2FA() {
        let user = testData.onePassUserWith2Fa
        loginRobot
            .loginUserWithTwoFA(user)
            .verify.inboxShown()
    }

    func xtestLoginWithTwoPassAnd2FA() {
        let user = testData.twoPassUserWith2Fa
        loginRobot
            .loginTwoPasswordUserWithTwoFA(user)
            .verify.inboxShown()
    }

    func xtestLoginWithInvalid2Pass() {
        let user = testData.twoPassUser
        loginRobot
            .loginTwoPasswordUserWithInvalid2Pass(user)
            .verify.incorrectMailboxPasswordErrorDialog()
    }
}
