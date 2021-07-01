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

    func testLoginSuccessCausesCoordinatorToFetchSettings() {
        let loginStubFactory = PMLoginStubFactory()
        var wasFetchSettingsCalled = false
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make) {
            wasFetchSettingsCalled = true
            return SignInCoordinatorEnvironment.dummyFetchSettings($0, $1)
        }
        let out = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: "test username", environment: environment) { _ in }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in completion(.loggedIn(.dummy)) }
        out.start()
        XCTAssertTrue(wasFetchSettingsCalled)
    }

    func testCoordinatorUsesUserDataFromLoginToFetchProperSettings() {
        let loginStubFactory = PMLoginStubFactory()
        var userInfoInFetchSettings: UserInfo?
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make) { userInfo, auth in
            userInfoInFetchSettings = userInfo
            return SignInCoordinatorEnvironment.dummyFetchSettings(userInfo, auth)
        }
        let testUser = User(ID: "test ID", name: "test name", usedSpace: 42, currency: "BOP", credit: 12, maxSpace: 123, maxUpload: 321,
                            role: 1, private: 1, subscribed: 1, services: 1, delinquent: 1, orgPrivateKey: "test key", email: "test email",
                            displayName: "test display name", keys: [Key(keyID: "test key id", privateKey: "test private key")])
        let testAddresses = [Address(addressID: "test address ID", domainID: "test domain ID", email: "test address email", send: .active, receive: .active,
                                     status: .enabled, type: .protonDomain, order: 1, displayName: "test address display name", signature: "test signature",
                                     hasKeys: 1, keys: [Key(keyID: "test address key id", privateKey: "test address private key")])]
        let out = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: "test username", environment: environment) { _ in }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in
            completion(.loggedIn(LoginData(credential: .dummy, user: testUser, salts: [], passphrases: [:], addresses: testAddresses, scopes: [])))
        }
        out.start()
        XCTAssertEqual(userInfoInFetchSettings?.userId, "test ID")
        XCTAssertEqual(userInfoInFetchSettings?.usedSpace, 42)
        XCTAssertEqual(userInfoInFetchSettings?.currency, "BOP")
        XCTAssertEqual(userInfoInFetchSettings?.credit, 12)
        XCTAssertEqual(userInfoInFetchSettings?.maxSpace, 123)
        XCTAssertEqual(userInfoInFetchSettings?.maxUpload, 321)
        XCTAssertEqual(userInfoInFetchSettings?.role, 1)
        XCTAssertEqual(userInfoInFetchSettings?.subscribed, 1)
        XCTAssertEqual(userInfoInFetchSettings?.delinquent, 1)
        XCTAssertEqual(userInfoInFetchSettings?.displayName, "test display name")
        XCTAssertEqual(userInfoInFetchSettings?.userKeys, [Key(keyID: "test key id", privateKey: "test private key")])
        XCTAssertEqual(userInfoInFetchSettings?.userAddresses, testAddresses)
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
        var userInfoInFinalizeSignIn: UserInfo?
        var authInFinalizeSignIn: AuthCredential?
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make) { _, _ in
            .value(testUserInfo)
        } finalizeSignIn: { userInfo, auth, _, _, _, _ in
            userInfoInFinalizeSignIn = userInfo
            authInFinalizeSignIn = auth
        } unlockIfRememberedCredentials: { _, _, _, _ in }
        let out = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: "test username", environment: environment) { _ in }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in
            completion(.loggedIn(LoginData(credential: testAuth, user: .dummy, salts: [], passphrases: [:], addresses: [], scopes: [])))
        }
        out.start()
        XCTAssertEqual(userInfoInFinalizeSignIn, testUserInfo)
        XCTAssertEqual(authInFinalizeSignIn, testAuth)
    }

    func testCoordinatorUnlocksWhenShouldTryUnlock() {
        let loginStubFactory = PMLoginStubFactory()
        var wasUnlockCredentialsCalled = false
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make) { _, _ in .value(.dummy) }
            finalizeSignIn: { _, _, _, _, _, tryUnlock in tryUnlock() }
            unlockIfRememberedCredentials: { _, _, _, _ in wasUnlockCredentialsCalled = true }
        let out = SignInCoordinator.loginFlowForSecondAndAnotherAccount(username: "test username", environment: environment) { _ in }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in completion(.loggedIn(.dummy)) }
        out.start()
        XCTAssertTrue(wasUnlockCredentialsCalled)
    }

    func testCoordinatorFinishesWithErrorIfFetchingSettingsFails() {
        let loginStubFactory = PMLoginStubFactory()
        struct TestError: Error, Equatable { let localizedDescription = "test error" }
        let testError = TestError()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make) { _, _ in .init(error: testError) }
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in completion(.loggedIn(.dummy)) }
        out.start()
        guard case .errored(.fetchingSettingsFailed(let error)) = flowResult, let errorAsTestError = error as? TestError
        else { XCTFail(#function); return }
        XCTAssertEqual(testError, errorAsTestError)
    }

    func testCoordinatorFinishesWithErrorIfFinalizeSignInFailsWithError() {
        let loginStubFactory = PMLoginStubFactory()
        struct TestError: Error, Equatable { let localizedDescription = "test error" }
        let testError = TestError()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make) { _, _ in .value(.dummy) }
            finalizeSignIn: { _, _, onError, _, _, _ in onError(testError as NSError) }
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
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make) { _, _ in .value(.dummy) }
            finalizeSignIn: { _, _, _, reachLimit, _, _ in reachLimit() }
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in completion(.loggedIn(.dummy)) }
        out.start()
        guard case .loggedInFreeAccountsLimitReached = flowResult else { XCTFail(#function); return }
    }

    func testCoordinatorFinishesWithUnlockFailedIfUnlockIfRememberedCorrectlyFinishedWithUnlockFailed() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make) { _, _ in .value(.dummy) }
            finalizeSignIn: { _, _, _, _, _, tryUnlock in tryUnlock() }
            unlockIfRememberedCredentials: { _, _, unlockFailed, _ in unlockFailed?() }
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in completion(.loggedIn(.dummy)) }
        out.start()
        guard case .errored(.unlockFailed) = flowResult else { XCTFail(#function); return }
    }

    func testCoordinatorSucceedsIfUnlockSucceeds() {
        let loginStubFactory = PMLoginStubFactory()
        let environment: SignInCoordinatorEnvironment = .test(login: loginStubFactory.make) { _, _ in .value(.dummy) }
            finalizeSignIn: { _, _, _, _, _, tryUnlock in tryUnlock() }
            unlockIfRememberedCredentials: { _, _, _, unlocked in unlocked?() }
        var flowResult: SignInCoordinator.FlowResult?
        let out = SignInCoordinator.loginFlowForFirstAccount(startingPoint: .form, environment: environment) { flowResult = $0 }
        loginStubFactory.instance?.presentLoginFlowStub.bodyIs { _, _, _, completion in completion(.loggedIn(.dummy)) }
        out.start()
        guard case .succeeded = flowResult else { XCTFail(#function); return }
    }

}
