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
import ProtonCore_Environment
import ProtonCore_TestingToolkit
import ProtonCore_QuarkCommands
import ProtonCore_CoreTranslation

final class ExternalAccountsTests: BaseTestCase {
    
    override class func setUp() {
        environmentFileName = "environment_black"
        super.setUp()
    }
    
    override func tearDown() {
        environmentFileName = "environment"
        super.tearDown()
    }

    let quarkCommandTimeout = 30.0
    let accountCreationTimeout = 90.0
    
//    Sign-in:
//    Sign-in with internal account works
//    Sign-in with external account works
//    Sign-in with username account works (account is converted to internal under the hood)
    
    func testSignInWithInternalAccountWorks() {
        let randomUsername = StringUtils().randomAlphanumericString(length: 8)
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)
        
        let expectQuarkCommandToFinish = expectation(description: "Quark command should finish")
        var quarkCommandResult: Result<CreatedAccountDetails, CreateAccountError>?
        QuarkCommands.create(account: .freeWithAddressAndKeys(username: randomUsername, password: randomPassword),
                             currentlyUsedHostUrl: Environment.black.doh.getCurrentlyUsedHostUrl()) { result in
            quarkCommandResult = result
            expectQuarkCommandToFinish.fulfill()
        }
        
        wait(for: [expectQuarkCommandToFinish], timeout: quarkCommandTimeout)
        if case .failure(let error) = quarkCommandResult {
            XCTFail("Internal account creation failed in test \(#function) because of \(error.userFacingMessageInQuarkCommands)")
            return
        }

        SigninExternalAccountsCapability()
            .signInWithAccount(userName: randomUsername,
                               password: randomPassword,
                               loginRobot: LoginRobot(),
                               retRobot: InboxRobot.self)
            .verify.inboxShown(time: accountCreationTimeout)
    }
    
    func testSignInWithExternalAccountWorks() {
        let randomEmail = "\(StringUtils().randomAlphanumericString(length: 8))@proton.uitests"
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)
        
        let expectQuarkCommandToFinish = expectation(description: "Quark command should finish")
        var quarkCommandResult: Result<CreatedAccountDetails, CreateAccountError>?
        QuarkCommands.create(account: .external(email: randomEmail, password: randomPassword),
                             currentlyUsedHostUrl: Environment.black.doh.getCurrentlyUsedHostUrl()) { result in
            quarkCommandResult = result
            expectQuarkCommandToFinish.fulfill()
        }
        wait(for: [expectQuarkCommandToFinish], timeout: quarkCommandTimeout)
        if case .failure(let error) = quarkCommandResult {
            XCTFail("External account creation failed in test \(#function) because of \(error.userFacingMessageInQuarkCommands)")
            return
        }

        SigninExternalAccountsCapability()
            .convertExternalAccountToInternal(email: randomEmail,
                                              password: randomPassword,
                                              username: nil,
                                              loginRobot: LoginRobot(),
                                              retRobot: InboxRobot.self)
            .verify.inboxShown(time: accountCreationTimeout)
    }
    
    func testSignInWithUsernameAccountWorks() {
        let randomUsername = StringUtils().randomAlphanumericString(length: 8)
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)
        
        let expectQuarkCommandToFinish = expectation(description: "Quark command should finish")
        var quarkCommandResult: Result<CreatedAccountDetails, CreateAccountError>?
        QuarkCommands.create(account: .freeNoAddressNoKeys(username: randomUsername, password: randomPassword),
                             currentlyUsedHostUrl: Environment.black.doh.getCurrentlyUsedHostUrl()) { result in
            quarkCommandResult = result
            expectQuarkCommandToFinish.fulfill()
        }
        wait(for: [expectQuarkCommandToFinish], timeout: quarkCommandTimeout)
        if case .failure(let error) = quarkCommandResult {
            XCTFail("Username account creation failed in test \(#function) because of \(error.userFacingMessageInQuarkCommands)")
            return
        }

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
    
    func testSignUpWithInternalAccountWorks() {
        
        let expectQuarkCommandToFinish = expectation(description: "Quark command should finish")
        QuarkCommands.unban(currentlyUsedHostUrl: Environment.black.doh.getCurrentlyUsedHostUrl()) { _ in
            expectQuarkCommandToFinish.fulfill()
        }
        wait(for: [expectQuarkCommandToFinish], timeout: quarkCommandTimeout)
        
        let randomUsername = StringUtils().randomAlphanumericString(length: 8)
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)
        let randomEmail = "\(StringUtils().randomAlphanumericString(length: 8))@proton.uitests"

        LoginRobot()
            .switchToCreateAccount()
            .verify.signupScreenIsShown()
            .verify.domainsButtonIsShown()
            .verify.domainsButtonHasValue(domain: "@proton.black")
            .insertName(name: randomUsername)
            .nextButtonTap(robot: PasswordRobot.self)
            .verify.passwordScreenIsShown()
            .insertPassword(password: randomPassword)
            .insertRepeatPassword(password: randomPassword)
            .nextButtonTap(robot: RecoveryRobot.self)
            .verify.recoveryScreenIsShown()
            .skipButtonTap()
            .verify.recoveryDialogDisplay()
            .skipButtonTap(robot: PaymentsUIRobot.self)
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
        wait(timeInterval: 15.0)
        button(domainsButtonId).checkHasLabel(domain)
        return SignupRobot()
    }
}

// not the greatest use of expectations, but it does the job
private func wait(timeInterval: TimeInterval) {
    let testCase = XCTestCase()
    let waitExpectation = testCase.expectation(description: "Waiting")
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeInterval) {
        waitExpectation.fulfill()
    }
    testCase.waitForExpectations(timeout: timeInterval + 0.5)
}
