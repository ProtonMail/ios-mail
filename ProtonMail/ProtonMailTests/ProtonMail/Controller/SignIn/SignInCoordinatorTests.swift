//
//  SignInCoordinatorTests.swift
//  ProtonMailTests
//
//  Copyright (c) 2021 Proton AG
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

import XCTest
import PromiseKit

import ProtonCoreDataModel
import ProtonCoreDoh
import ProtonCoreLogin
import ProtonCoreLoginUI
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreTestingToolkitUnitTestsDataModel
import ProtonCoreTestingToolkitUnitTestsLogin
import ProtonCoreTestingToolkitUnitTestsLoginUI

@testable import ProtonMail

final class PMLoginStubFactory {
    var makeArgs: (name: String, accountType: AccountType, passwordRestrictions: SignupPasswordRestrictions, isCloseButton: Bool)?
    var instance: LoginInterfaceMock?
    lazy var make: (String, AccountType, SignupPasswordRestrictions, Bool) -> LoginAndSignupInterface = { [weak self] name, accountType, passwordRestrictions, isCloseButton in
        self?.makeArgs = (name, accountType, passwordRestrictions, isCloseButton)
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
        XCTAssertEqual(loginStubFactory.instance?.presentLoginFlowWithUpdateBlockStub.wasCalledExactlyOnce, true)
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

//    func testCoordinatorPassesRightUsernameToLoginFlow() {
//        let loginStubFactory = PMLoginStubFactory()
//        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make)
//        let out = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: "test username", environment: environment) { _ in }
//        out.start()
//        XCTAssertEqual(loginStubFactory.instance?.presentLoginFlowStub.lastArguments?.a2, "test username")

    // it should change to
    // loginStubFactory.instance?.presentLoginFlowStub.lastArguments?.a2.username
    // but the variable is for internal access
    // Can't run this test right now
//    }

    func testLoginDismissalCausesCoordinatorToReturnResultDismissed() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make)
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: "test username", environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowWithUpdateBlockStub.bodyIs { _, _, _, completion in
            completion(.dismissed)
        }
        out.start()
        guard case .dismissed = flowResult else { XCTFail(#function); return }
    }

    func testCoordinatorSaveLoginDataAfterSuccessfulLoginDataFetched() throws {
        let loginStubFactory = PMLoginStubFactory()
        let testUserInfo = UserInfo.dummy
        let testAuth = AuthCredential(sessionID: "test session id", accessToken: "test access token", refreshToken: "test refresh token",
                                      userName: "test user name", userID: "test user id", privateKey: "test private key", passwordKeySalt: "test password key salt")
        var loginData: LoginData?
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make,
                                                              finalizeSignIn: { _, _, _, _ in
                                                                  XCTFail("Should not called here")
                                                              },
                                                              unlockIfRememberedCredentials: { _, _, _ in },
                                                              saveLoginData: { loginDataRes in
                                                                  loginData = loginDataRes
                                                                  return .success
                                                              })

        let out = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: "test username", environment: environment) { _ in }
        loginStubFactory.instance?.presentLoginFlowWithUpdateBlockStub.bodyIs { _, _, _, completion in
            let user = User.dummy.updated(ID: nil, name: testUserInfo.displayName, usedSpace: Int64(testUserInfo.usedSpace), usedBaseSpace: nil, usedDriveSpace: nil, currency: testUserInfo.currency, credit: testUserInfo.credit, maxSpace: Int64(testUserInfo.maxSpace), maxBaseSpace: nil, maxDriveSpace: nil, maxUpload: Int64(testUserInfo.maxUpload), role: testUserInfo.role, private: nil, subscribed: testUserInfo.subscribed, services: nil, delinquent: testUserInfo.delinquent, orgPrivateKey: nil, email: testUserInfo.notificationEmail, displayName: testUserInfo.displayName, keys: nil)
            completion(.loginStateChanged(.dataIsAvailable(UserData(credential: testAuth, user: user, salts: [], passphrases: [:], addresses: [], scopes: []))))
            // Do not call .loginFinished here to simulate the case where the user doesn't finish the whole login process.
        }
        out.start()
        let userData = try XCTUnwrap(loginData)
        XCTAssertEqual(userData.toUserInfo.displayName, testUserInfo.displayName)
        XCTAssertEqual(userData.toUserInfo.maxSpace, testUserInfo.maxSpace)
        XCTAssertEqual(userData.toUserInfo.usedSpace, testUserInfo.usedSpace)
        XCTAssertEqual(userData.toUserInfo.delinquent, testUserInfo.delinquent)

        XCTAssertEqual(userData.credential.sessionID, testAuth.sessionID)
        XCTAssertEqual(userData.credential.accessToken, testAuth.accessToken)
        XCTAssertEqual(userData.credential.refreshToken, testAuth.refreshToken)
    }

    func testCoordinatorUnlocksWhenShouldTryUnlock() {
        let loginStubFactory = PMLoginStubFactory()
        var wasUnlockCredentialsCalled = false
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make, finalizeSignIn: { _, _, _, tryUnlock in
            tryUnlock()
        }, unlockIfRememberedCredentials: { _, _, _ in wasUnlockCredentialsCalled = true })
        let out = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: "test username", environment: environment) { _ in }
        loginStubFactory.instance?.presentLoginFlowWithUpdateBlockStub.bodyIs { _, _, _, completion in
            completion(.loginStateChanged(.dataIsAvailable(.dummy)))
            completion(.loginStateChanged(.loginFinished))
        }
        out.start()
        XCTAssertTrue(wasUnlockCredentialsCalled)
    }

    func testCoordinatorFinishesWithErrorIfFinalizeSignInFailsWithError() {
        let loginStubFactory = PMLoginStubFactory()
        struct TestError: Error, Equatable { let localizedDescription = "test error" }
        let testError = TestError()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make, finalizeSignIn: { _, onError, _, _ in
            onError(testError as NSError)
        })
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowWithUpdateBlockStub.bodyIs { _, _, _, completion in
            completion(.loginStateChanged(.dataIsAvailable(.dummy)))
            completion(.loginStateChanged(.loginFinished))
        }
        out.start()
        guard case .errored(.finalizingSignInFailed(let error)) = flowResult, let errorAsTestError = error as? TestError
        else { XCTFail(#function); return }
        XCTAssertEqual(testError, errorAsTestError)
    }

    func testCoordinatorFinishesWithUnlockFailedIfUnlockIfRememberedCorrectlyFinishedWithUnlockFailed() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make, finalizeSignIn: { _, _, _, tryUnlock in
            tryUnlock()
        }, unlockIfRememberedCredentials: { _, unlockFailed, _ in unlockFailed?() })
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowWithUpdateBlockStub.bodyIs { _, _, _, completion in
            completion(.loginStateChanged(.dataIsAvailable(.dummy)))
            completion(.loginStateChanged(.loginFinished))
        }
        out.start()
        guard case .errored(.unlockFailed) = flowResult else { XCTFail(#function); return }
    }

    func testCoordinatorSucceedsIfUnlockSucceeds() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make, finalizeSignIn: { _, _, _, tryUnlock in
            tryUnlock()
        }, unlockIfRememberedCredentials: { _, _, unlocked in unlocked?() })
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowWithUpdateBlockStub.bodyIs { _, _, _, completion in
            completion(.loginStateChanged(.dataIsAvailable(.dummy)))
            completion(.loginStateChanged(.loginFinished))
        }
        out.start()
        guard case .succeeded = flowResult else { XCTFail(#function); return }
    }

}
