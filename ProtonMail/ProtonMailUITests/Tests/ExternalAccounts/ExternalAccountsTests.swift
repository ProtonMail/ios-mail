// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import XCTest
import fusion
import ProtonCoreEnvironment
import ProtonCoreTestingToolkitUITestsLogin
import ProtonCoreQuarkCommands

final class ExternalAccountsTests: BaseTestCase {

    let quarkCommandTimeout = 30.0
    let accountCreationTimeout = 90.0

    //    Sign-in:
    //    Sign-in with internal account works
    //    Sign-in with external account works
    //    Sign-in with username account works (account is converted to internal under the hood)

    func testSignInWithInternalAccountWorks() throws {
        let randomUsername = StringUtils().randomAlphanumericString(length: 8)
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)

        try quarkCommands.userCreate(user: User(name: randomUsername, password: randomPassword))

        SigninExternalAccountsCapability()
            .signInWithAccount(userName: randomUsername,
                               password: randomPassword,
                               loginRobot: LoginRobot(),
                               retRobot: InboxRobot.self)
            .verify.inboxShown(time: accountCreationTimeout)
    }

    func testSignInWithExternalAccountWorks() throws {
        let randomEmail = "\(StringUtils().randomAlphanumericString(length: 8))@proton.uitests"
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)

        let user = User(email: randomEmail, name: "", password: randomPassword, isExternal: true)
        try quarkCommands.userCreate(user: user)

        SigninExternalAccountsCapability()
            .convertExternalAccountToInternal(email: randomEmail,
                                              password: randomPassword,
                                              username: nil,
                                              loginRobot: LoginRobot(),
                                              retRobot: InboxRobot.self)
            .verify.inboxShown(time: accountCreationTimeout)
    }

    func testSignInWithUsernameAccountWorks() throws {
        let randomUsername = StringUtils().randomAlphanumericString(length: 8)
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)

        try quarkCommands.userCreate(user: User(name: randomUsername, password: randomPassword), createAddress: .noKey)

        SigninExternalAccountsCapability()
            .signInWithAccount(userName: randomUsername,
                               password: randomPassword,
                               loginRobot: LoginRobot(),
                               retRobot: InboxRobot.self)
            .verify.inboxShown(time: accountCreationTimeout)
    }

    //    Sign-up:
    //    Sign-up with internal account works
    //    The UI for sign-up with external account is not available
    //    The UI for sign-up with username account is not available

    func testSignUpWithInternalAccountWorks() throws {

        try quarkCommands.jailUnban()

        let randomUsername = StringUtils().randomAlphanumericString(length: 8)
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)
        let randomEmail = "\(StringUtils().randomAlphanumericString(length: 8))@proton.uitests"

        LoginRobot()
            .switchToCreateAccount()
            .verify.signupScreenIsShown()
            .verify.domainsButtonIsShown()
            .verify.domainsButtonHasValue(domain: "@\(dynamicDomain)")
            .insertName(name: randomUsername)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: randomPassword)
            .insertRepeatPassword(password: randomPassword)
            .nextButtonTap(robot: RecoveryRobot.self)
            .verify.recoveryScreenIsShown()
            .skipButtonTap()
            .verify.recoveryDialogDisplay()
            .skipButtonTap(robot: SignupPaymentsRobot.self)
            .verify.paymentsUIScreenIsShown()
            .expandPlan(plan: .free)
            .freePlanV3ButtonTap(wait: 30.0)
            .proceed(email: randomEmail, code: "666666", to: AccountSummaryRobot.self)
            .startUsingAppTap(robot: InboxRobot.self)
            .verify.inboxShown(time: accountCreationTimeout)
    }


    func testSignUpWithExternalAccountIsNotAvailable() {
        LoginRobot()
            .switchToCreateAccount()
            .verify.otherAccountExtButtonIsNotShown()
    }

    func testSignUpWithUsernameAccountIsNotAvailable() {
        LoginRobot()
            .switchToCreateAccount()
            .verify.domainsButtonIsShown()
    }
}

private let domainsButtonId = "SignupViewController.domainsButton"

extension SignupRobot.Verify {
    @discardableResult
    public func domainsButtonIsShown() -> SignupRobot {
        button(domainsButtonId).checkExists()
        return SignupRobot()
    }

    @discardableResult
    public func domainsButtonHasValue(domain: String) -> SignupRobot {
        // arbitrary wait to ensure that the domains refresh call finishes
        sleep(15)
        button(domainsButtonId).checkHasLabel(domain)
        return SignupRobot()
    }
}
