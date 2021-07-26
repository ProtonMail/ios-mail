//
//  SignInCoordinatorTests.swift
//  ProtonMailTests
//
//  Copyright (c) 2021 Proton Technologies AG
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
import PromiseKit

import ProtonCore_DataModel
import ProtonCore_Doh
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_TestingToolkit

@testable import ProtonMail

final class PMLoginStubFactory {
    var makeArgs: (name: String, accountType: AccountType, signupMode: SignupMode, passwordRestrictions: SignupPasswordRestrictions, isCloseButton: Bool)?
    var instance: LoginInterfaceMock?
    lazy var make: (String, AccountType, SignupMode, SignupPasswordRestrictions, Bool) -> LoginInterface = { [weak self] name, accountType, signupMode, passwordRestrictions, isCloseButton in
        self?.makeArgs = (name, accountType, signupMode, passwordRestrictions, isCloseButton)
        let login = LoginInterfaceMock()
        self?.instance = login
        return login
    }
}

final class SignInCoordinatorTests: XCTestCase {

    func testCoordinatorForFirstAccountIsNotDismissable() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make)
        _ = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { _ in }
        XCTAssertEqual(loginStubFactory.makeArgs?.isCloseButton, false)
    }

    func testCoordinatorForSecondAndAnotherAccountIsDismissable() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make)
        _ = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: nil, environment: environment) { _ in }
        XCTAssertEqual(loginStubFactory.makeArgs?.isCloseButton, true)
    }

    func testStartingCoordinatorFromFormEntryPointKicksOffLoginFlow() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make)
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { _ in }
        out.start()
        XCTAssertEqual(loginStubFactory.instance?.presentLoginFlowStub.wasCalledExactlyOnce, true)
        XCTAssertEqual(loginStubFactory.instance?.presentMailboxPasswordFlowStub.wasNotCalled, true)
    }

    func testCoordinatorFromMailboxPasswordEntryPointKicksOffLoginFlow() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make)
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .mailboxPassword, environment: environment) { _ in }
        out.start()
        XCTAssertEqual(loginStubFactory.instance?.presentLoginFlowStub.wasNotCalled, true)
        XCTAssertEqual(loginStubFactory.instance?.presentMailboxPasswordFlowStub.wasCalledExactlyOnce, true)
    }

    func testCoordinatorPassesRightUsernameToLoginFlow() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make)
        let out = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: "test username", environment: environment) { _ in }
        out.start()
        XCTAssertEqual(loginStubFactory.instance?.presentLoginFlowStub.lastArguments?.second, "test username")
    }

    func testLoginDismissalCausesCoordinatorToReturnResultDissmissed() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make)
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: "test username", environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in completion(.dismissed) }
        out.start()
        guard case .dismissed = flowResult else { XCTFail(#function); return }
    }

    func testCoordinatorFinalizesSignInAfterSuccessfullSettingsFetch() {
        let loginStubFactory = PMLoginStubFactory()
        let testUserInfo = UserInfo(displayName: "test display name", maxSpace: 42, notificationEmail: "test notification name",
                                    signature: "test signature", usedSpace: 123, userAddresses: [], autoSC: 321, language: "DE", maxUpload: 234,
                                    notify: 2345, showImage: 645, swipeL: 3452, swipeR: 4132, role: 1234, delinquent: 4123, keys: [],
                                    userId: "test user Id", sign: 1234, attachPublicKey: 5467, linkConfirmation: "test link confirmation", credit: 098,
                                    currency: "BOL", pwdMode: 667, twoFA: 776, enableFolderColor: 77, inheritParentFolderColor: 88, subscribed: 12, groupingMode: 1, weekStart: 0)
        let testAuth = AuthCredential(sessionID: "test session id", accessToken: "test access token", refreshToken: "test refresh token",
                                      expiration: .distantFuture, privateKey: "test private key", passwordKeySalt: "test password key salt")
        var loginData: LoginData?
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make, finalizeSignIn: { loginDataRes, _, _, _, _, _ in
            loginData = loginDataRes
        }, unlockIfRememberedCredentials: { _, _, _, _ in })

        let out = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: "test username", environment: environment) { _ in }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in
            let user = User.dummy.updated(ID: nil, name: testUserInfo.displayName, usedSpace: Double(testUserInfo.usedSpace), currency: testUserInfo.currency, credit: testUserInfo.credit, maxSpace: Double(testUserInfo.maxSpace), maxUpload: Double(testUserInfo.maxUpload), role: testUserInfo.role, private: nil, subscribed: testUserInfo.subscribed, services: nil, delinquent: testUserInfo.delinquent, orgPrivateKey: nil, email: testUserInfo.notificationEmail, displayName: testUserInfo.displayName, keys: nil)
            completion(.loggedIn(LoginData(credential: testAuth, user: user, salts: [], passphrases: [:], addresses: [], scopes: [])))
        }
        out.start()
        XCTAssertEqual(loginData?.toUserInfo.displayName, testUserInfo.displayName)
        XCTAssertEqual(loginData?.toUserInfo.maxSpace, testUserInfo.maxSpace)
        XCTAssertEqual(loginData?.toUserInfo.usedSpace, testUserInfo.usedSpace)
        XCTAssertEqual(loginData?.toUserInfo.delinquent, testUserInfo.delinquent)

        XCTAssertEqual(loginData?.credential.sessionID, testAuth.sessionID)
        XCTAssertEqual(loginData?.credential.accessToken, testAuth.accessToken)
        XCTAssertEqual(loginData?.credential.refreshToken, testAuth.refreshToken)
    }

    func testCoordinatorUnlocksWhenShouldTryUnlock() {
        let loginStubFactory = PMLoginStubFactory()
        var wasUnlockCredentialsCalled = false
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make, finalizeSignIn: { _, _, _, _, _, tryUnlock in
            tryUnlock()
        }, unlockIfRememberedCredentials: { _, _, _, _ in wasUnlockCredentialsCalled = true })
        let out = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: "test username", environment: environment) { _ in }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in completion(.loggedIn(.dummy)) }
        out.start()
        XCTAssertTrue(wasUnlockCredentialsCalled)
    }

    func testCoordinatorFinishesWithErrorIfFinalizeSignInFailsWithError() {
        let loginStubFactory = PMLoginStubFactory()
        struct TestError: Error, Equatable { let localizedDescription = "test error" }
        let testError = TestError()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make, finalizeSignIn: { _, onError, _, _, _, _ in
            onError(testError as NSError)
        })
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in completion(.loggedIn(.dummy)) }
        out.start()
        guard case .errored(.finalizingSignInFailed(let error)) = flowResult, let errorAsTestError = error as? TestError
        else { XCTFail(#function); return }
        XCTAssertEqual(testError, errorAsTestError)
    }

    func testCoordinatorFinishesWithReachLimitIfFinalizeSignInFailsWithReachLimit() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make, finalizeSignIn: { _, _, reachLimit, _, _, _ in
            reachLimit()
        })
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in completion(.loggedIn(.dummy)) }
        out.start()
        guard case .loggedInFreeAccountsLimitReached = flowResult else { XCTFail(#function); return }
    }

    func testCoordinatorFinishesWithUnlockFailedIfUnlockIfRememberedCorrectlyFinishedWithUnlockFailed() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make, finalizeSignIn: { _, _, _, _, _, tryUnlock in
            tryUnlock()
        }, unlockIfRememberedCredentials: { _, _, unlockFailed, _ in unlockFailed?() })
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in completion(.loggedIn(.dummy)) }
        out.start()
        guard case .errored(.unlockFailed) = flowResult else { XCTFail(#function); return }
    }

    func testCoordinatorSucceedsIfUnlockSucceeds() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make, finalizeSignIn: { _, _, _, _, _, tryUnlock in
            tryUnlock()
        }, unlockIfRememberedCredentials: { _, _, _, unlocked in unlocked?() })
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in completion(.loggedIn(.dummy)) }
        out.start()
        guard case .succeeded = flowResult else { XCTFail(#function); return }
    }

}
