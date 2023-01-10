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

import Foundation
import XCTest
import pmtest
import ProtonCore_CoreTranslation

public class SignupUITestCases {
    public init() {}
    
    public func testCloseButtonExists(signupRobot: SignupRobot) {
        signupRobot
            .verify.signupScreenIsShown()
            .verify.closeButtonIsShown()
    }
    
    public func testCloseButtonDoesntExist(signupRobot: SignupRobot) {
        signupRobot
            .verify.signupScreenIsShown()
            .verify.closeButtonIsNotShown()
    }
    
    public func testBothAccountInteralFirst(signupRobot: SignupRobot) {
        signupRobot
            .verify.signupScreenIsShown()
            .verify.otherAccountExtButtonIsShown()
    }
    
    public func testBothAccountExternalFirst(signupRobot: SignupRobot) {
        signupRobot
            .verify.signupScreenIsShown()
            .verify.otherAccountIntButtonIsShown()
    }
    
    public func testInternalAccountOnly(signupRobot: SignupRobot) {
        signupRobot
            .verify.signupScreenIsShown()
            .verify.otherAccountButtonIsNotShown()
    }
    
    public func testExtAccountOnly(signupRobot: SignupRobot) {
        signupRobot
            .verify.signupScreenIsShown()
            .verify.otherAccountButtonIsNotShown()
    }
    
    public func testBothAccountIntExternalSignupFeatureOff(signupRobot: SignupRobot) {
        signupRobot
            .verify.signupScreenIsShown()
            .verify.otherAccountButtonIsNotShown()
            .verify.otherAccountExtButtonIsNotShown()
    }
    
    public func testBothAccountExtExternalSignupFeatureOff(signupRobot: SignupRobot) {
        signupRobot
            .verify.signupScreenIsShown()
            .verify.otherAccountButtonIsNotShown()
            .verify.otherAccountExtButtonIsNotShown()
    }
    
    public func testIntAccountOnlyExternalSignupFeatureOff(signupRobot: SignupRobot) {
        signupRobot
            .verify.signupScreenIsShown()
            .verify.otherAccountButtonIsNotShown()
            .verify.otherAccountExtButtonIsNotShown()
    }
    
    public func testExtAccountOnlyExternalSignupFeatureOff(signupRobot: SignupRobot) {
        signupRobot
            .verify.signupScreenIsShown()
            .verify.otherAccountButtonIsNotShown()
            .verify.otherAccountExtButtonIsNotShown()
    }
    
    public func testSwitchIntToLogin(signupRobot: SignupRobot) {
        signupRobot
            .verify.signupScreenIsShown()
            .signinButtonTap()
            .verify.loginScreenIsShown()
    }
    
    public func testSwitchExtToLogin(signupRobot: SignupRobot) {
        signupRobot
            .verify.signupScreenIsShown()
            .otherAccountButtonTap()
            .verify.signupScreenIsShown()
            .signinButtonTap()
            .verify.loginScreenIsShown()
    }
    
    public func testSignupNewIntAccountSuccess(signupRobot: SignupRobot,
                                               randomName: String,
                                               password: String,
                                               randomEmail: String,
                                               emailVerificationCode: String) -> AccountSummaryRobot {
        return signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: randomName)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: password)
            .insertRepeatPassword(password: password)
            .nextButtonTap(robot: RecoveryRobot.self)
            .verify.recoveryScreenIsShown()
            .skipButtonTap()
            .verify.recoveryDialogDisplay()
            .skipButtonTap(robot: CompleteRobot.self)
            .verify.completeScreenIsShown(robot: SignupHumanVerificationRobot.self)
            .verify.humanVerificationScreenIsShown()
            .performEmailVerification(
                email: randomEmail, code: emailVerificationCode, to: AccountSummaryRobot.self
            )
            .accountSummaryElementsDisplayed(robot: AccountSummaryRobot.self)
    }
    
    public func testSignupExistingIntAccount(signupRobot: SignupRobot, existingName: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: existingName)
            .nextButtonTap(robot: SignupRobot.self)
            .verify.usernameAlreadyExists()
    }
    
    public func testSignupNewExtAccountSuccess(signupRobot: SignupRobot,
                                               randomEmail: String,
                                               password: String,
                                               emailVerificationCode: String) -> AccountSummaryRobot {
        return signupRobot
            .verify.signupScreenIsShown()
            .otherAccountButtonTap()
            .verify.signupScreenIsShown()
            .insertExternalEmail(name: randomEmail)
            .nextButtonTap(robot: EmailVerificationRobot.self)
            .verify.emailVerificationScreenIsShown()
            .insertCode(code: emailVerificationCode)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: password)
            .insertRepeatPassword(password: password)
            .nextButtonTap(robot: CompleteRobot.self)
            .verify.completeScreenIsShown(robot: AccountSummaryRobot.self)
            .accountSummaryElementsDisplayed(robot: AccountSummaryRobot.self)
    }
    
    public func testSignupExistingExtAccount(signupRobot: SignupRobot,
                                             existingEmail: String,
                                             existingEmailPassword: String,
                                             emailVerificationCode: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .otherAccountButtonTap()
            .verify.signupScreenIsShown()
            .insertExternalEmail(name: existingEmail)
            .nextButtonTap(robot: EmailVerificationRobot.self)
            .verify.emailVerificationScreenIsShown()
            .insertCode(code: emailVerificationCode)
            .nextButtonTap(robot: LoginRobot.self)
            .verify.loginScreenIsShown()
            .verify.emailAlreadyExists()
            .verify.checkEmail(email: existingEmail)
            .insertPassword(password: existingEmailPassword)
            .signInButtonTapAfterEmailError(to: CreateProtonmailRobot.self)
            .createPMAddressIsShown()
    }
    
    public func testPasswordVerificationEmpty(signupRobot: SignupRobot, randomName: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: randomName)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordEmpty()
    }
    
    public func testPasswordVerificationTooShort(signupRobot: SignupRobot,
                                                 randomName: String,
                                                 shortPassword: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: randomName)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: shortPassword)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordTooShort()
    }
    
    public func testPasswordVerificationRepeatPasswordEmpty(signupRobot: SignupRobot,
                                                            randomName: String,
                                                            password: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: randomName)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: password)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordNotEqual()
    }
    
    public func testPasswordVerificationPasswordEmpty(signupRobot: SignupRobot,
                                                      randomName: String,
                                                      password: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: randomName)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertRepeatPassword(password: password)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordNotEqual()
    }
    
    public func testPasswordsVerificationDoNotMatch(signupRobot: SignupRobot,
                                                    randomName: String,
                                                    password: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: randomName)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: password)
            .insertRepeatPassword(password: password + password)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordNotEqual()
    }
    
    public func testRecoveryVerificationEmail(signupRobot: SignupRobot,
                                              randomName: String,
                                              password: String,
                                              testEmail: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: randomName)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: password)
            .insertRepeatPassword(password: password)
            .nextButtonTap(robot: RecoveryRobot.self)
            .verify.recoveryScreenIsShown()
            .insertRecoveryEmail(email: testEmail)
            .verify.nextButtonIsEnabled()
    }
    
    public func testRecoveryVerificationPhone(signupRobot: SignupRobot,
                                              randomName: String,
                                              password: String,
                                              testNumber: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: randomName)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: password)
            .insertRepeatPassword(password: password)
            .nextButtonTap(robot: RecoveryRobot.self)
            .verify.recoveryScreenIsShown()
            .selectRecoveryMethod(method: .phone)
            .insertRecoveryNumber(number: testNumber)
            .verify.nextButtonIsEnabled()
            .nextButtonTap()
            .verify.phoneNumberInvalid()
    }
    
    public func testRecoverySelectCountryAndCheckCode(signupRobot: SignupRobot,
                                                      randomName: String,
                                                      password: String,
                                                      exampleCountry: String,
                                                      exampleCode: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: randomName)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: password)
            .insertRepeatPassword(password: password)
            .nextButtonTap(robot: RecoveryRobot.self)
            .verify.recoveryScreenIsShown()
            .selectRecoveryMethod(method: .phone)
            .selectCountrySelector()
            .verify.countrySelectorScreenIsShown()
            .insertCountryName(name: exampleCountry)
            .selectTopCountry()
            .verify.recoveryScreenIsShown()
            .verify.verifyCountryCode(code: exampleCode)
    }
    
    public func testSignupNewIntAccountHVRequired(signupRobot: SignupRobot,
                                                  randomName: String,
                                                  password: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: randomName)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: password)
            .insertRepeatPassword(password: password)
            .nextButtonTap(robot: RecoveryRobot.self)
            .verify.recoveryScreenIsShown()
            .skipButtonTap()
            .verify.recoveryDialogDisplay()
            .skipButtonTap(robot: CompleteRobot.self)
            .verify.completeScreenIsShown(robot: SignupHumanVerificationRobot.self)
            .verify.humanVerificationScreenIsShown()
            .closeButton()
            .verify.recoveryScreenIsShown()
            .verify.humanVerificationRequired()
    }
    
    public func testSignupNewIntStayInRecoveryMethod(signupRobot: SignupRobot,
                                                     randomName: String,
                                                     password: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: randomName)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: password)
            .insertRepeatPassword(password: password)
            .nextButtonTap(robot: RecoveryRobot.self)
            .verify.recoveryScreenIsShown()
            .skipButtonTap()
            .verify.recoveryDialogDisplay()
            .recoveryMethodTap()
            .verify.recoveryScreenIsShown()
            .skipButtonTap()
            .verify.recoveryDialogDisplay()
            .recoveryMethodTap()
            .verify.recoveryScreenIsShown()
    }
    
    public func testSignupNewExtSendCodeRequestNewCode(signupRobot: SignupRobot,
                                                       randomEmail: String,
                                                       defaultCode: String) {
        let email = randomEmail
        signupRobot
            .verify.signupScreenIsShown()
            .insertExternalEmail(name: email)
            .nextButtonTap(robot: EmailVerificationRobot.self)
            .verify.emailVerificationScreenIsShown()
            .resendCodeButton()
            .verify.resendDialogDisplay(email: email)
            .newCodeButtonTap()
            .verify.resendEmailMessage(email: email)
            .verify.verifyVerificationCode(code: defaultCode)
    }
    
    public func testSignupNewExtSendCodeCancel(signupRobot: SignupRobot, randomEmail: String) {
        let email = randomEmail
        signupRobot
            .verify.signupScreenIsShown()
            .insertExternalEmail(name: email)
            .nextButtonTap(robot: EmailVerificationRobot.self)
            .verify.emailVerificationScreenIsShown()
            .resendCodeButton()
            .verify.resendDialogDisplay(email: email)
            .cancelButtonTap()
            .verify.emailVerificationScreenIsShown()
    }
    
    public func testSignupNewExtWrongVerificationCodeResend(signupRobot: SignupRobot,
                                                            randomEmail: String,
                                                            emailVerificationWrongCode: String,
                                                            defaultCode: String) {
        let email = randomEmail
        signupRobot
            .verify.signupScreenIsShown()
            .insertExternalEmail(name: email)
            .nextButtonTap(robot: EmailVerificationRobot.self)
            .verify.emailVerificationScreenIsShown()
            .insertCode(code: emailVerificationWrongCode)
            .nextButtonTap(robot: EmailVerificationRobot.EmailVerificationDialogRobot.self)
            .verify.verificationDialogDisplay()
            .resendButtonTap()
            .verify.resendEmailMessage(email: email)
            .verify.verifyVerificationCode(code: defaultCode)
    }
    
    public func testSignupNewExtWrongVerificationCodeChangeEmail(signupRobot: SignupRobot,
                                                                 randomEmail: String,
                                                                 emailVerificationWrongCode: String) {
        let email = randomEmail
        signupRobot
            .verify.signupScreenIsShown()
            .verify.otherAccountIntButtonIsShown()
            .insertExternalEmail(name: email)
            .nextButtonTap(robot: EmailVerificationRobot.self)
            .verify.emailVerificationScreenIsShown()
            .insertCode(code: emailVerificationWrongCode)
            .nextButtonTap(robot: EmailVerificationRobot.EmailVerificationDialogRobot.self)
            .verify.verificationDialogDisplay()
            .changeEmailButtonTap()
            .waitDisapper()
            .verify.signupScreenIsShown()
    }
    
    public func testSignupNewIntTermsAndConditions(signupRobot: SignupRobot, randomName: String, password: String) {
        signupRobot
            .verify.signupScreenIsShown()
            .insertName(name: randomName)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: password)
            .insertRepeatPassword(password: password)
            .nextButtonTap(robot: RecoveryRobot.self)
            .verify.recoveryScreenIsShown()
            .TCLinkTap()
            .verify.tcScreenIsShown()
            .swipeUpWebView()
            .backButton()
            .verify.recoveryScreenIsShown()
    }
}
