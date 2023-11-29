//
//  SignupUITestCases.swift
//  ProtonCore-TestingToolkit - Created on 11/23/2022
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if canImport(fusion)

import Foundation
import XCTest
import fusion

public class SigninExternalAccountsCapability {
    public init() {}
    
    public func signInWithAccount<T: CoreElements>(userName: String,
                                                   password: String,
                                                   loginRobot: LoginRobot,
                                                   retRobot: T.Type) -> T {
        return loginRobot
            .fillUsername(username: userName)
            .fillpassword(password: password)
            .signIn(robot: retRobot)
    }

    public func convertExternalAccountToInternal<T: CoreElements>(email: String,
                                                                  password: String,
                                                                  username: String?,
                                                                  loginRobot: LoginRobot,
                                                                  retRobot: T.Type) -> T {

        let createAccountRobot = loginRobot
            .fillUsername(username: email)
            .fillpassword(password: password)
            .signIn(robot: CreateAddressRobot.self)
            .verify.createAddress(email: email)

        if let username {
            _ = createAccountRobot
                .fillUsername(username: username)
        }

        createAccountRobot.tapContinueButton()

        return T()
    }
}

#endif
