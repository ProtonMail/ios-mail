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

import Foundation

import ProtonCoreDataModel
import ProtonCoreKeymaker
import ProtonCoreNetworking
import ProtonCoreTestingToolkit
@testable import ProtonMail
import XCTest

final class LaunchTests: XCTestCase {
    private var sut: Launch!
    private var testContainer: TestContainer!
    private var mockKeyMaker: MockKeyMakerProtocol!
    private var mockSetupCoreData: MockSetupCoreDataService!
    private let dummyMainKey = NoneProtection.generateRandomValue(length: 32)

    override func setUp() {
        super.setUp()

        testContainer = .init()
        mockKeyMaker = .init()
        mockSetupCoreData = .init()

        testContainer.keyMakerFactory.register { self.mockKeyMaker }
        testContainer.setupCoreDataServiceFactory.register { self.mockSetupCoreData }

        mockKeyMaker.mainKeyStub.bodyIs { _, _ in
            self.dummyMainKey
        }

        sut = .init(dependencies: testContainer)
    }

    override func tearDown() {
        super.tearDown()

        testContainer = nil
        mockKeyMaker = nil
        mockSetupCoreData = nil
        sut = nil
    }

    func testStart_itShouldCallMainKeyExists() throws {
        try sut.start()
        XCTAssertTrue(mockKeyMaker.mainKeyExistsStub.wasCalledExactlyOnce)
    }

    func testStart_itShouldCallSetupCoreData() throws {
        try sut.start()
        XCTAssertTrue(mockSetupCoreData.setupStub.wasCalledExactlyOnce)
    }

    func testStart_whenCoreDataSetupFails_itShouldNotLoadUsers() {
        mockSetupCoreData.setupStub.bodyIs { _ in
            throw NSError()
        }
        setUpAppAccessGranted_and_userInUserDefaults()

        try? sut.start()
        XCTAssertTrue(mockSetupCoreData.setupStub.wasCalledExactlyOnce)
        XCTAssertEqual(testContainer.usersManager.users.count, 0)
    }

    func testStart_whenAccessGranted_itShouldLoadUsersIntoMemory() throws {
        setUpAppAccessGranted_and_userInUserDefaults()

        try sut.start()
        XCTAssertEqual(testContainer.usersManager.users.count, 1)
    }

    func testStart_whenAccessDenied_itShouldNotLoadUsersIntoMemory() throws {
        setUpAppAccessDeniedReasonAppLock_and_userInUserDefaults()

        try sut.start()
        XCTAssertEqual(testContainer.usersManager.users.count, 0)
    }

    func testLoadUserDataAfterUnlock_itShouldLoadUsersIntoMemory() throws {
        setUpAppAccessGranted_and_userInUserDefaults()

        try sut.start()
        XCTAssertEqual(testContainer.usersManager.users.count, 1)
    }
}

extension LaunchTests {

    private func setUpAppAccessGranted_and_userInUserDefaults() {
        addNewUserInUserDefaults(userID: "7")
        mockKeyMaker.isMainKeyInMemory = true
    }

    private func setUpAppAccessDeniedReasonAppLock_and_userInUserDefaults() {
        addNewUserInUserDefaults(userID: "4")
        mockKeyMaker.isMainKeyInMemory = false
    }

    private func addNewUserInUserDefaults(userID: String = UUID().uuidString) {
        let auth = AuthCredential(
            sessionID: userID,
            accessToken: "",
            refreshToken: "",
            userName: userID,
            userID: userID,
            privateKey: nil,
            passwordKeySalt: nil
        )
        let userInfo = UserInfo(
            maxSpace: nil,
            usedSpace: nil,
            language: nil,
            maxUpload: nil,
            role: 1,
            delinquent: nil,
            keys: [],
            userId: userID,
            linkConfirmation: nil,
            credit: nil,
            currency: nil,
            createTime: nil,
            subscribed: nil
        )

        setupUserDefaultsWithUser(auth: auth, userInfo: userInfo)
    }

    private func setupUserDefaultsWithUser(auth: AuthCredential, userInfo: UserInfo) {
        XCTAssertTrue(testContainer.usersManager.users.isEmpty)

        // Add and remove user to UsersManager copying stored data in the middle
        testContainer.usersManager.add(auth: auth, user: userInfo, mailSettings: .init())
        let authCredentials = testContainer.userDefaults.value(forKey: UsersManager.CoderKey.authKeychainStore)
        let usersInfo = testContainer.userDefaults.value(forKey: UsersManager.CoderKey.usersInfo)
        let mailSettings = testContainer.userDefaults.value(forKey: UsersManager.CoderKey.mailSettingsStore)
        testContainer.usersManager.users.forEach(testContainer.usersManager.remove(user:))

        // Deleting data stored by UserObjectsPersistence
        try? FileManager.default.removeItem(at: FileManager.default.documentDirectoryURL.appendingPathComponent([AuthCredential].pathComponent))
        try? FileManager.default.removeItem(at: FileManager.default.documentDirectoryURL.appendingPathComponent([UserInfo].pathComponent))

        // Set copied stored data again in testContainer.userDefaults
        testContainer.userDefaults.setValue(authCredentials, forKey: UsersManager.CoderKey.authKeychainStore)
        testContainer.userDefaults.setValue(usersInfo, forKey: UsersManager.CoderKey.usersInfo)
        testContainer.userDefaults.setValue(mailSettings, forKey: UsersManager.CoderKey.mailSettingsStore)

        XCTAssertTrue(testContainer.usersManager.users.isEmpty)
    }
}
