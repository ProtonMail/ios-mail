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
import pmtest
import ProtonCore_Environment
import ProtonCore_TestingToolkit
import ProtonCore_QuarkCommands
import ProtonCore_CoreTranslation

final class ExternalAccountsCapabilityATests: BaseTestCase {
    
    override class func setUp() {
        environmentFileName = "environment_black"
        super.setUp()
    }
    
    override func tearDown() {
        environmentFileName = "environment"
        super.tearDown()
    }
    
//    Sign-in:
//    Sign-in with internal account works
//    Sign-in with external account shows popup with "Learn more" button
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
        
        wait(for: [expectQuarkCommandToFinish], timeout: 5.0)
        if case .failure(let error) = quarkCommandResult {
            XCTFail("Internal account creation failed in test \(#function) because of \(error.userFacingMessageInQuarkCommands)")
            return
        }
        
        LoginRobot()
            .fillUsername(username: randomUsername)
            .fillpassword(password: randomPassword)
            .signIn(robot: InboxRobot.self)
            .verify.inboxShown()
    }
    
    func testSignInWithExternalAccountShowsPopup() {
        let randomEmail = "\(StringUtils().randomAlphanumericString(length: 8))@proton.uitests"
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)
        
        let expectQuarkCommandToFinish = expectation(description: "Quark command should finish")
        var quarkCommandResult: Result<CreatedAccountDetails, CreateAccountError>?
        QuarkCommands.create(account: .external(email: randomEmail, password: randomPassword),
                             currentlyUsedHostUrl: Environment.black.doh.getCurrentlyUsedHostUrl()) { result in
            quarkCommandResult = result
            expectQuarkCommandToFinish.fulfill()
        }
        wait(for: [expectQuarkCommandToFinish], timeout: 5.0)
        if case .failure(let error) = quarkCommandResult {
            XCTFail("External account creation failed in test \(#function) because of \(error.userFacingMessageInQuarkCommands)")
            return
        }
        
        LoginRobot()
            .fillUsername(username: randomEmail)
            .fillpassword(password: randomPassword)
            .signIn(robot: ExternalAccountsNotSupportedDialogRobot.self)
            .verify.externalAccountsNotSupportedDialog()
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
        wait(for: [expectQuarkCommandToFinish], timeout: 5.0)
        if case .failure(let error) = quarkCommandResult {
            XCTFail("Username account creation failed in test \(#function) because of \(error.userFacingMessageInQuarkCommands)")
            return
        }

        LoginRobot()
            .fillUsername(username: randomUsername)
            .fillpassword(password: randomPassword)
            .signIn(robot: InboxRobot.self)
            .verify.inboxShown()
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
        wait(for: [expectQuarkCommandToFinish], timeout: 5.0)
        
        let randomUsername = StringUtils().randomAlphanumericString(length: 8)
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)
        let randomEmail = "\(StringUtils().randomAlphanumericString(length: 8))@proton.uitests"
        
        let robot = LoginRobot()
            .switchToCreateAccount()
            .verify.domainsButtonIsShown()
            .verify.signupScreenIsShown()
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
            .freePlanV3ButtonTap()
        
        // workaround to have this test passing on the CI
        SignupHumanVerificationV3Robot().button(CoreString._hv_email_method_name).wait(time: 5.0)
        
        robot
            .proceed(email: randomEmail, code: "666666", to: AccountSummaryRobot.self)
            .startUsingAppTap(robot: InboxRobot.self)
            .verify.inboxShown()
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
}
