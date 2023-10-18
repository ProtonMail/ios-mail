//
//  SignupExternalAccountsCapability.swift
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

// swiftlint:disable function_parameter_count

#if canImport(fusion)

import Foundation
import XCTest
import fusion

public class SignupExternalAccountsCapability {
    public init() {}

    public func signUpWithInternalAccount<T: CoreElements>(signupRobot: SignupRobot,
                                                           username: String,
                                                           password: String,
                                                           userEmail: String,
                                                           verificationCode: String,
                                                           retRobot: T.Type) -> T {
        return signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: username)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: password)
            .insertRepeatPassword(password: password)
            .nextButtonTap(robot: RecoveryRobot.self)
            .verify.recoveryScreenIsShown()
            .skipButtonTap()
            .verify.recoveryDialogDisplay()
            .skipButtonTap(robot: CompleteRobot.self)
            .verify.completeScreenIsShown(robot: SignupHumanVerificationV3Robot.self)
            .verify.humanVerificationScreenIsShown()
            .switchToEmailHVMethod()
            .performEmailVerificationV3(email: userEmail, code: verificationCode, to: retRobot)
    }

    public func signUpWithExternalAccount<T: CoreElements>(signupRobot: SignupRobot,
                                                           userEmail: String,
                                                           password: String,
                                                           verificationCode: String,
                                                           retRobot: T.Type) -> T {
        return signupRobot
            .verify.signupScreenIsShown()
            .insertExternalEmail(name: userEmail)
            .nextButtonTapToOwnershipHV()
            .fillInTextField(verificationCode)
            .tapOnVerifyCodeButton(to: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: password)
            .insertRepeatPassword(password: password)
            .nextButtonTap(robot: retRobot)
    }
}

#endif
