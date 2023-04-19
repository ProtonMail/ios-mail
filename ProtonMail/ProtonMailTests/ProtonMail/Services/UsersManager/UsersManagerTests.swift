// Copyright (c) 2021 Proton AG
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

import ProtonCore_DataModel
import ProtonCore_Keymaker
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

class UsersManagerTests: XCTestCase {
    var apiMock: APIService!
    var sut: UsersManager!
    var doh: DohMock!
    var cachedUserDataProviderMock: MockCachedUserDataProvider!
    let suiteName = String.randomString(10)
    var customCache: SharedCacheBase!
    var customKeyChain: Keychain!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.cachedUserDataProviderMock = .init()
        self.apiMock = APIServiceMock()
        self.doh = DohMock()
        self.customCache = .init(userDefaults: .init(suiteName: suiteName)!)
        self.customKeyChain = .init(service: String.randomString(10),
                                    accessGroup: "2SB5Z68H26.ch.protonmail.protonmail")
        sut = UsersManager(
            doh: doh,
            userDataCache: cachedUserDataProviderMock,
            userDefaultCache: customCache,
            keychain: customKeyChain
        )
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        doh = nil
        apiMock = nil
        cachedUserDataProviderMock = nil

        customCache.getShared().remove(forKey: UsersManager.CoderKey.authKeychainStore)
        customCache.getShared().remove(forKey: UsersManager.CoderKey.userInfo)
        customCache.getShared().remove(forKey: UsersManager.CoderKey.authKeychainStore)
        customCache.getShared().remove(forKey: UsersManager.CoderKey.usersInfo)
        self.customCache = nil
        self.customKeyChain.removeEverything()
        self.customKeyChain = nil
    }

    func testNumberOfFreeAccounts() {
        XCTAssertEqual(sut.numberOfFreeAccounts, 0)
        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        sut.add(newUser: user1)
        XCTAssertEqual(sut.numberOfFreeAccounts, 1)
        let user2 = createUserManagerMock(userID: "2", isPaid: true)
        sut.add(newUser: user2)
        XCTAssertEqual(sut.numberOfFreeAccounts, 1)
        let user3 = createUserManagerMock(userID: "3", isPaid: false)
        sut.add(newUser: user3)
        XCTAssertEqual(sut.numberOfFreeAccounts, 2)
    }

    func testIsAllowedNewUser_noFreeUser() {
        let paidUserInfo = UserInfo(maxSpace: nil,
                                    usedSpace: nil,
                                    language: nil,
                                    maxUpload: nil,
                                    role: 1,
                                    delinquent: nil,
                                    keys: [],
                                    userId: "1",
                                    linkConfirmation: nil,
                                    credit: nil,
                                    currency: nil,
                                    subscribed: nil)
        XCTAssertTrue(sut.isAllowedNewUser(userInfo: paidUserInfo))

        let freeUserInfo = UserInfo(maxSpace: nil,
                                    usedSpace: nil,
                                    language: nil,
                                    maxUpload: nil,
                                    role: 0,
                                    delinquent: nil,
                                    keys: [],
                                    userId: "1",
                                    linkConfirmation: nil,
                                    credit: nil,
                                    currency: nil,
                                    subscribed: nil)
        XCTAssertTrue(sut.isAllowedNewUser(userInfo: freeUserInfo))
    }

    func testIsAllowedNewUser_1FreeUser() {
        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        sut.add(newUser: user1)

        let paidUserInfo = UserInfo(maxSpace: nil,
                                    usedSpace: nil,
                                    language: nil,
                                    maxUpload: nil,
                                    role: 1,
                                    delinquent: nil,
                                    keys: [],
                                    userId: "1",
                                    linkConfirmation: nil,
                                    credit: nil,
                                    currency: nil,
                                    subscribed: nil)
        XCTAssertTrue(sut.isAllowedNewUser(userInfo: paidUserInfo))

        let freeUserInfo = UserInfo(maxSpace: nil,
                                    usedSpace: nil,
                                    language: nil,
                                    maxUpload: nil,
                                    role: 0,
                                    delinquent: nil,
                                    keys: [],
                                    userId: "1",
                                    linkConfirmation: nil,
                                    credit: nil,
                                    currency: nil,
                                    subscribed: nil)
        XCTAssertFalse(sut.isAllowedNewUser(userInfo: freeUserInfo))
    }

    func testAddNewUser() {
        let userID = "1"
        let auth = AuthCredential(sessionID: userID,
                                  accessToken: "",
                                  refreshToken: "",
                                  userName: userID,
                                  userID: userID,
                                  privateKey: nil,
                                  passwordKeySalt: nil)
        let userInfo = UserInfo(maxSpace: nil,
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
                                subscribed: nil)
        XCTAssertTrue(sut.users.isEmpty)
        sut.add(auth: auth, user: userInfo, mailSettings: .init())
        XCTAssertFalse(sut.users.isEmpty)
        XCTAssertEqual(sut.users[0].authCredential, auth)
        XCTAssertEqual(sut.users[0].userInfo, userInfo)
    }

    func testUpdateUserInfo() {
        let userID = "1"
        let user1 = createUserManagerMock(userID: userID, isPaid: false)
        sut.add(newUser: user1)
        XCTAssertFalse(sut.users[0].isPaid)

        let newAuth = AuthCredential(sessionID: "SessionID_\(userID)",
                                     accessToken: "new",
                                     refreshToken: "",
                                     userName: userID,
                                     userID: userID,
                                     privateKey: nil,
                                     passwordKeySalt: nil)
        let newUserInfo = UserInfo(maxSpace: 999,
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
                                   subscribed: nil)
        sut.update(userInfo: newUserInfo, for: newAuth.sessionID)
        XCTAssertTrue(sut.users[0].isPaid)
        XCTAssertEqual(sut.users[0].userInfo.maxSpace, 999)
    }

    func testUserAt() {
        XCTAssertNil(sut.user(at: 0))
        XCTAssertNil(sut.user(at: Int.max))
        XCTAssertNil(sut.user(at: Int.min))

        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        sut.add(newUser: user1)

        XCTAssertEqual(sut.user(at: 0)?.userInfo.userId, "1")
        XCTAssertNil(sut.user(at: Int.max))
        XCTAssertNil(sut.user(at: Int.min))
    }

    func testActive() {
        sut.active(by: "")
        XCTAssertTrue(sut.users.isEmpty)

        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        let user2 = createUserManagerMock(userID: "2", isPaid: true)
        let user3 = createUserManagerMock(userID: "3", isPaid: false)
        sut.add(newUser: user1)
        sut.add(newUser: user2)

        XCTAssertEqual(sut.users.map { $0.userInfo.userId }, ["1", "2"])
        sut.active(by: user2.authCredential.sessionID)
        XCTAssertEqual(sut.users.map { $0.userInfo.userId }, ["2", "1"])
        sut.active(by: user2.authCredential.sessionID)
        XCTAssertEqual(sut.users.map { $0.userInfo.userId }, ["2", "1"])
        sut.active(by: user1.authCredential.sessionID)
        XCTAssertEqual(sut.users.map { $0.userInfo.userId }, ["1", "2"])
        sut.add(newUser: user3)
        XCTAssertEqual(sut.users.map { $0.userInfo.userId }, ["1", "2", "3"])
        sut.active(by: user2.authCredential.sessionID)
        XCTAssertEqual(sut.users.map { $0.userInfo.userId }, ["2", "1", "3"])
        sut.active(by: user3.authCredential.sessionID)
        XCTAssertEqual(sut.users.map { $0.userInfo.userId }, ["3", "2", "1"])
    }

    func testGetUserBySessionID() {
        XCTAssertNil(sut.getUser(by: "hello"))
        XCTAssertNil(sut.getUser(by: "1"))

        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        sut.add(newUser: user1)
        XCTAssertEqual(sut.getUser(by: "SessionID_1")?.userInfo, user1.userInfo)
        XCTAssertNil(sut.getUser(by: UserID(rawValue: "Hello")))
    }

    func testGetUserByUserID() {
        let id1 = UserID(rawValue: String.randomString(20))
        let id2 = UserID(rawValue: String.randomString(20))
        XCTAssertNil(sut.getUser(by: id1))
        XCTAssertNil(sut.getUser(by: id2))

        let user1 = createUserManagerMock(userID: id1.rawValue, isPaid: false)
        sut.add(newUser: user1)
        XCTAssertEqual(sut.getUser(by: id1)?.userInfo, user1.userInfo)
        XCTAssertNil(sut.getUser(by: id2))
    }

    func testRemoveUser() throws {
        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        let user2 = createUserManagerMock(userID: "2", isPaid: false)
        sut.add(newUser: user1)
        sut.add(newUser: user2)
        XCTAssertEqual(sut.users.count, 2)

        sut.remove(user: user1)

        XCTAssertEqual(sut.users.count, 1)
        XCTAssertTrue(
            cachedUserDataProviderMock.setStub.wasCalled
        )
        let argument = try XCTUnwrap(
            cachedUserDataProviderMock.setStub.lastArguments?.a1
        )
        XCTAssertEqual(argument.count, 1)
        let disconnectedUser = try XCTUnwrap(argument.first)
        XCTAssertEqual(disconnectedUser.userID, user1.userID.rawValue)

        XCTAssertEqual(sut.users[0].userInfo, user2.userInfo)
    }

    func testLogoutUser_primaryUser() {
        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        sut.add(newUser: user1)
        XCTAssertEqual(sut.users.count, 1)
        let expectation1 = expectation(description: "Closure is called")
        expectation(forNotification: .didPrimaryAccountLogout, object: nil, handler: nil)

        sut.logout(user: user1) {
            XCTAssertTrue(self.sut.users.isEmpty)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testLogoutUser_userNotInUsersManager_addedToDisconnectedUser() throws {
        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        XCTAssertTrue(sut.users.isEmpty)
        let expectation1 = expectation(description: "Closure is called")

        sut.logout(user: user1) {
            XCTAssertTrue(self.sut.users.isEmpty)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(
            cachedUserDataProviderMock.setStub.wasCalledExactlyOnce
        )
        let argument = try XCTUnwrap(
            cachedUserDataProviderMock.setStub.lastArguments?.a1
        )
        XCTAssertEqual(argument.count, 1)
    }

    func testTryRestore_dataInLegacyFormat_dataIsSavedToNewLocation() throws {
        let userID = String.randomString(20)
        try prepareLegacyUserData(userID: userID)

        sut.tryRestore()

        XCTAssertTrue(sut.hasUsers())
        XCTAssertEqual(sut.users.count, 1)
        XCTAssertEqual(sut.firstUser?.userID.rawValue, userID)

        XCTAssertNil(customKeyChain.data(forKey: UsersManager.CoderKey.keychainStore))
        let userInfoData = customCache.getShared().object(forKey: UsersManager.CoderKey.userInfo) as? Data
        XCTAssertNil(userInfoData)

        XCTAssertNotNil(customCache.getShared().object(forKey: UsersManager.CoderKey.authKeychainStore))
        XCTAssertNotNil(customCache.getShared().object(forKey: UsersManager.CoderKey.usersInfo))
    }

    func testTryRestore_withNoMailSettingInCache_userHasDefaultMailSetting() throws {
        let userID = String.randomString(20)
        try prepareUserDataInCache(userID: userID, hasMailSetting: false)

        sut.tryRestore()

        XCTAssertTrue(sut.hasUsers())
        XCTAssertEqual(sut.users.count, 1)
        XCTAssertEqual(sut.firstUser?.userID.rawValue, userID)
        XCTAssertEqual(sut.firstUser?.mailSettings, .init())
    }

    func testTryRestore_withMailSettingInCache_correctMailSettingIsRestore() throws {
        let userID = String.randomString(20)
        try prepareUserDataInCache(userID: userID, hasMailSetting: true)

        sut.tryRestore()

        XCTAssertTrue(sut.hasUsers())
        XCTAssertEqual(sut.users.count, 1)
        XCTAssertEqual(sut.firstUser?.userID.rawValue, userID)
        XCTAssertEqual(sut.firstUser?.mailSettings.nextMessageOnMove, true)
    }

    func testTryRestore_withDifferentOrderOfUserData_shouldFollowTheOrderOfAuthCredentials() throws {
        var userIDs: [String] = []
        for _ in 0 ... 9 {
            userIDs.append(String.randomString(20))
        }
        try prepareUserDataInCacheWithDifferentOrder(userIDs: userIDs)

        sut.tryRestore()

        XCTAssertTrue(sut.hasUsers())
        XCTAssertEqual(sut.users.count, 10)
        XCTAssertEqual(sut.users.map { $0.userID.rawValue }, userIDs)
    }

    func testClean_hasUsersReturnFalse() throws {
        let userID = String.randomString(20)
        try prepareUserDataInCache(userID: userID, hasMailSetting: true)
        let e = expectation(description: "Closure is called")

        sut.clean().ensure {
            e.fulfill()
        }.cauterize()

        waitForExpectations(timeout: 1)

        XCTAssertFalse(sut.hasUsers())
    }

    private func prepareUserDataInCacheWithDifferentOrder(userIDs: [String]) throws {
        let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin)!
        var userInfos: [UserInfo] = []
        var auths: [AuthCredential] = []
        for userID in userIDs {
            auths.append(createAuth(userID: userID))
        }
        for userID in userIDs.reversed() {
            userInfos.append(createUserInfo(userID: userID))
        }

        let lockedAuth = try Locked<[AuthCredential]>(clearValue: auths, with: mainKey)
        customCache.getShared().set(lockedAuth.encryptedValue, forKey: UsersManager.CoderKey.authKeychainStore)
        let lockedUserInfo = try Locked<[UserInfo]>(clearValue: userInfos, with: mainKey)
        customCache.getShared().set(lockedUserInfo.encryptedValue, forKey: UsersManager.CoderKey.usersInfo)
    }

    private func prepareUserDataInCache(userID: String, hasMailSetting: Bool) throws {
        let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin)!
        let auth = createAuth(userID: userID)
        let userInfo = createUserInfo(userID: userID)

        let lockedAuth = try Locked<[AuthCredential]>(clearValue: [auth], with: mainKey)
        customCache.getShared().set(lockedAuth.encryptedValue, forKey: UsersManager.CoderKey.authKeychainStore)
        let lockedUserInfo = try Locked<[UserInfo]>(clearValue: [userInfo], with: mainKey)
        customCache.getShared().set(lockedUserInfo.encryptedValue, forKey: UsersManager.CoderKey.usersInfo)
        if hasMailSetting {
            let mailSetting = MailSettings(nextMessageOnMove: true)
            let value: [String: MailSettings] = [userID: mailSetting]
            let lockedMailSetting = try Locked<[String: MailSettings]>(clearValue: value, with: mainKey)
            customCache.getShared().set(lockedMailSetting.encryptedValue, forKey: UsersManager.CoderKey.mailSettingsStore)
        }
    }

    private func prepareLegacyUserData(userID: String) throws {
        let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin)!
        let auth = createAuth(userID: userID)
        let userInfo = createUserInfo(userID: userID)
        let archived = auth.archive()
        let lockedAuth = try Locked<Data>(clearValue: archived, with: mainKey)
        customKeyChain.set(lockedAuth.encryptedValue, forKey: UsersManager.CoderKey.keychainStore)

        let lockedUserInfo = try Locked<UserInfo>(clearValue: userInfo, with: mainKey)
        customCache.getShared().set(lockedUserInfo.encryptedValue, forKey: UsersManager.CoderKey.userInfo)
    }

    private func createAuth(userID: String) -> AuthCredential {
        return AuthCredential(sessionID: "SessionID_\(userID)",
                              accessToken: "",
                              refreshToken: "",
                              userName: userID,
                              userID: userID,
                              privateKey: nil,
                              passwordKeySalt: nil)
    }

    private func createUserInfo(userID: String) -> UserInfo {
        return UserInfo(maxSpace: nil,
                        usedSpace: nil,
                        language: nil,
                        maxUpload: nil,
                        role: 0,
                        delinquent: nil,
                        keys: [],
                        userId: userID,
                        linkConfirmation: nil,
                        credit: nil,
                        currency: nil,
                        subscribed: nil)
    }

    private func createUserManagerMock(userID: String, isPaid: Bool) -> UserManager {
        let userInfo = UserInfo(maxSpace: nil,
                                usedSpace: nil,
                                language: nil,
                                maxUpload: nil,
                                role: isPaid ? 1 : 0,
                                delinquent: nil,
                                keys: [],
                                userId: userID,
                                linkConfirmation: nil,
                                credit: nil,
                                currency: nil,
                                subscribed: nil)
        let auth = createAuth(userID: userID)
        return UserManager(api: apiMock,
                           userInfo: userInfo,
                           authCredential: auth,
                           mailSettings: .init(),
                           parent: sut)
    }
}
