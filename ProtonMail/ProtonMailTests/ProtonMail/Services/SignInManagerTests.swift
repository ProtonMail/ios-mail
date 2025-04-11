// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreDataModel
import ProtonCoreLogin
import ProtonCoreTestingToolkitUnitTestsServices
import ProtonCoreKeymaker
@testable import ProtonMail
import XCTest

final class SignInManagerTests: XCTestCase {
    private var usersManager: UsersManager!
    private var apiMock: APIServiceMock!
    private var updateSwipeActionUseCaseMock: MockUpdateSwipeActionDuringLoginUseCase!
    private var globalContainer: TestContainer!

    private var sut: SignInManager!

    private let userID = String.randomString(10)
    private let sessionID = String.randomString(10)

    override func setUp() {
        super.setUp()
        apiMock = .init()

        globalContainer = .init()
        usersManager = globalContainer.usersManager
        updateSwipeActionUseCaseMock = .init()
        let queueHandlerRegisterMock = MockQueueHandlerRegister()
        sut = .init(
            usersManager: usersManager,
            queueHandlerRegister: queueHandlerRegisterMock,
            updateSwipeActionUseCase: updateSwipeActionUseCaseMock,
            dependencies: .init(
                notificationCenter: globalContainer.notificationCenter,
                userDefaults: globalContainer.userDefaults
            )
        )
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        updateSwipeActionUseCaseMock = nil
        usersManager = nil
        apiMock = nil
        globalContainer = nil
    }

    func testSaveLoginData_newUserIsAddedToUsersManager() {
        let userData = createLoginData(userID: userID, sessionID: sessionID)

        XCTAssertEqual(sut.saveLoginData(loginData: userData), .success)

        XCTAssertEqual(globalContainer.userDefaults[.areContactsCached], 0)
        XCTAssertTrue(usersManager.hasUsers())
        XCTAssertEqual(usersManager.users.count, 1)
    }

    func testSaveLoginData_whenUserIsExist_returnError() {
        let userData = createLoginData(userID: userID, sessionID: sessionID)
        usersManager.add(newUser: .init(api: apiMock, userID: userID))

        XCTAssertEqual(sut.saveLoginData(loginData: userData), .errorOccurred)
    }

    func testSaveLoginData_whenOneFreeAccountIsLoggedIn_doesNotReturnLimitReached() {
        let userData = createLoginData(userID: userID, sessionID: sessionID, subscribed: .init(rawValue: 0))
        usersManager.add(newUser: .init(api: apiMock, userID: String.randomString(10), subscribed: .init(rawValue: 0)))

        XCTAssertEqual(sut.saveLoginData(loginData: userData), .success)
    }

    func testSaveLoginData_whenTwoFreeAccountsAreLoggedIn_returnFreeAccountsLimitReached() {
        let userData = createLoginData(userID: userID, sessionID: sessionID, subscribed: .init(rawValue: 0))
        usersManager.add(newUser: .init(api: apiMock, userID: String.randomString(10), subscribed: .init(rawValue: 0)))
        usersManager.add(newUser: .init(api: apiMock, userID: String.randomString(10), subscribed: .init(rawValue: 0)))

        XCTAssertEqual(sut.saveLoginData(loginData: userData), .freeAccountsLimitReached)
    }

    func testFinalizeSignIn_tryUnlockClosureIsCalled() throws {
        let userData = createLoginData(userID: userID, sessionID: sessionID)
        usersManager.add(newUser: .init(api: apiMock, userInfo: userData.toUserInfo, authCredential: userData.credential, mailSettings: nil, parent: nil, globalContainer: .init()))
        let skeletonExpectation = expectation(description: "Closure is called")
        let unlockExpectation = expectation(description: "Closure is called")
        let errorExpectation = expectation(description: "Closure should not be called")
        errorExpectation.isInverted = true
        updateSwipeActionUseCaseMock.executeStub.bodyIs { _, _, completion in
            completion(.success)
        }
        mockSuccessfulResponses()

        sut.finalizeSignIn(
            loginData: userData,
            onError: { _ in
                errorExpectation.fulfill()
            }, showSkeleton: {
                skeletonExpectation.fulfill()
            }, tryUnlock: {
                unlockExpectation.fulfill()
            })

        waitForExpectations(timeout: 0.5)

        let user = try XCTUnwrap(usersManager.getUser(by: sessionID))
        XCTAssertEqual(user.userInfo.swipeLeft, 4)
        XCTAssertEqual(user.userInfo.swipeRight, 4)
        XCTAssertEqual(user.mailSettings.hideSenderImages, false)
        XCTAssertEqual(user.mailSettings.showMoved, .doNotKeep)
        XCTAssertEqual(user.mailSettings.nextMessageOnMove, .explicitlyDisabled)
    }

    func testFinalizeSignIn_withOneLoggedAccount_tryUnlockClosureIsCalled_newUserIsSetAsActive() throws {
        let userData = createLoginData(userID: userID, sessionID: sessionID)
        usersManager.add(newUser: .init(api: apiMock, userID: String.randomString(10)))
        usersManager.add(newUser: .init(api: apiMock, userInfo: userData.toUserInfo, authCredential: userData.credential, mailSettings: nil, parent: nil, globalContainer: .init()))
        let skeletonExpectation = expectation(description: "Closure is called")
        let unlockExpectation = expectation(description: "Closure is called")
        let errorExpectation = expectation(description: "Closure should not be called")
        errorExpectation.isInverted = true
        updateSwipeActionUseCaseMock.executeStub.bodyIs { _, _, completion in
            completion(.success)
        }
        mockSuccessfulResponses()

        sut.finalizeSignIn(
            loginData: userData,
            onError: { _ in
                errorExpectation.fulfill()
            }, showSkeleton: {
                skeletonExpectation.fulfill()
            }, tryUnlock: {
                unlockExpectation.fulfill()
            })

        waitForExpectations(timeout: 0.5)

        let user = try XCTUnwrap(usersManager.firstUser)
        XCTAssertEqual(user.userInfo.swipeLeft, 4)
        XCTAssertEqual(user.userInfo.swipeRight, 4)
        XCTAssertEqual(user.mailSettings.hideSenderImages, false)
        XCTAssertEqual(user.mailSettings.showMoved, .doNotKeep)
        XCTAssertEqual(user.mailSettings.nextMessageOnMove, .explicitlyDisabled)
    }

    func testFinalizeSignIn_apiFailed_newUserIsRemoved() {
        let userData = createLoginData(userID: userID, sessionID: sessionID)
        usersManager.add(newUser: .init(api: apiMock, userInfo: userData.toUserInfo, authCredential: userData.credential, mailSettings: nil, parent: nil, globalContainer: .init()))
        let skeletonExpectation = expectation(description: "Closure is called")
        let unlockExpectation = expectation(description: "Closure is called")
        unlockExpectation.isInverted = true
        let errorExpectation = expectation(description: "Closure should not be called")
        apiMock.requestJSONStub.bodyIs { _, _, _, path, _, _, _, _, _, _, _, _, completion in
            completion(nil, .failure(.badResponse()))
        }

        sut.finalizeSignIn(
            loginData: userData,
            onError: { _ in
                errorExpectation.fulfill()
            },
            showSkeleton: {
                skeletonExpectation.fulfill()
            },
            tryUnlock: {
                unlockExpectation.fulfill()
            })

        waitForExpectations(timeout: 2)

        XCTAssertFalse(usersManager.hasUsers())
    }

    func testFinalizeSignIn_userIsNotAvailableInDelinquent_newUserIsRemoved() {
        let userData = createLoginData(userID: userID, sessionID: sessionID, delinquent: 4)
        usersManager.add(newUser: .init(api: apiMock, userInfo: userData.toUserInfo, authCredential: userData.credential, mailSettings: nil, parent: nil, globalContainer: .init()))
        let skeletonExpectation = expectation(description: "Closure is called")
        let unlockExpectation = expectation(description: "Closure is called")
        unlockExpectation.isInverted = true
        let errorExpectation = expectation(description: "Closure should not be called")
        updateSwipeActionUseCaseMock.executeStub.bodyIs { _, _, completion in
            completion(.success)
        }
        mockSuccessfulResponses()

        sut.finalizeSignIn(
            loginData: userData,
            onError: { _ in
                errorExpectation.fulfill()
            },
            showSkeleton: {
                skeletonExpectation.fulfill()
            },
            tryUnlock: {
                unlockExpectation.fulfill()
            })

        waitForExpectations(timeout: 2)

        XCTAssertFalse(usersManager.hasUsers())
    }
}

extension SignInManagerTests {
    private func createLoginData(
        userID: String,
        sessionID: String,
        delinquent: Int = 0,
        subscribed: User.Subscribed = .mail
    ) -> LoginData {
        return LoginData(
            credential: .init(
                sessionID: sessionID,
                accessToken: "",
                refreshToken: "",
                userName: "",
                userID: userID,
                privateKey: nil,
                passwordKeySalt: nil
            ),
            user: .init(
                ID: userID,
                name: nil,
                usedSpace: 0,
                usedBaseSpace: nil,
                usedDriveSpace: nil,
                currency: "",
                credit: 0,
                maxSpace: 0,
                maxBaseSpace: nil,
                maxDriveSpace: nil,
                maxUpload: 0,
                role: 0,
                private: 0,
                subscribed: subscribed,
                services: 0,
                delinquent: delinquent,
                orgPrivateKey: nil,
                email: nil,
                displayName: nil,
                keys: []
            ),
            salts: [],
            passphrases: [:],
            addresses: [],
            scopes: []
        )
    }

    private func mockSuccessfulResponses() {
        apiMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            if path.contains("mail/v4/settings") {
                let response = SettingTestData.mailSettings
                completion(nil, .success(response))
            } else if path.contains("/settings") {
                let response = SettingTestData.userSettings
                completion(nil, .success(response))
            } else if path.contains("features") || path.contains("/auth") {
                completion(nil, .success(["Code": 1000]))
            } else if path.hasPrefix("/payments") {
                completion(nil, .success([:]))
            } else {
                XCTFail("Unexpected path: \(path)")
                completion(nil, .failure(.badResponse()))
            }
        }
    }
}
