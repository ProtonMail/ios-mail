// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail
import ProtonCore_DataModel
import ProtonCore_Services
import ProtonCore_TestingToolkit
import ProtonCore_Networking

class UsersManagerTests: XCTestCase {
    var apiMock: APIService!
    var sut: UsersManager!
    var doh: DohMock!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        self.apiMock = APIServiceMock()
        self.doh = try DohMock()
        sut = UsersManager(doh: doh, delegate: nil)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        doh = nil
        apiMock = nil
    }

    func testGetUsersWithoutTheActiveOne() {
        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        let user2 = createUserManagerMock(userID: "2", isPaid: false)
        sut.add(newUser: user1)
        XCTAssertEqual(sut.getUsersWithoutTheActiveOne().count, 0)
        sut.add(newUser: user2)
        XCTAssertEqual(sut.getUsersWithoutTheActiveOne().count, 1)
        XCTAssertEqual(sut.getUsersWithoutTheActiveOne()[0].userInfo.userId, "2")
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
                                  expiration: Date(),
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
        sut.add(auth: auth, user: userInfo)
        XCTAssertFalse(sut.users.isEmpty)
        XCTAssertEqual(sut.users[0].authCredential, auth)
        XCTAssertEqual(sut.users[0].userInfo, userInfo)
    }

    func testUpdateAuthUserInfo() {
        let userID = "1"
        let user1 = createUserManagerMock(userID: userID, isPaid: false)
        sut.add(newUser: user1)
        XCTAssertFalse(sut.users[0].isPaid)

        let newAuth = AuthCredential(sessionID: "SessionID_\(userID)",
                                     accessToken: "new",
                                     refreshToken: "",
                                     expiration: Date(),
                                     userName: userID,
                                     userID: userID,
                                     privateKey: nil,
                                     passwordKeySalt: nil)
        let newUserInfo = UserInfo(maxSpace: nil,
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
        sut.update(auth: newAuth, user: newUserInfo)
        XCTAssertTrue(sut.users[0].isPaid)
        XCTAssertEqual(sut.users[0].authCredential.accessToken, "new")
    }

    func testUserAt() {
        XCTAssertNil(sut.user(at: 0))
        XCTAssertNil(sut.user(at: Int.max))
        XCTAssertNil(sut.user(at: Int.min))

        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        sut.add(newUser: user1)

        XCTAssertEqual(sut.user(at: 0)?.userinfo.userId, "1")
        XCTAssertNil(sut.user(at: Int.max))
        XCTAssertNil(sut.user(at: Int.min))
    }

    func testActive() {
        sut.active(uid: "")
        XCTAssertTrue(sut.users.isEmpty)

        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        let user2 = createUserManagerMock(userID: "2", isPaid: true)
        let user3 = createUserManagerMock(userID: "3", isPaid: false)
        sut.add(newUser: user1)
        sut.add(newUser: user2)

        XCTAssertEqual(sut.users.map{ $0.userinfo.userId }, ["1", "2"])
        sut.active(uid: user2.auth.sessionID)
        XCTAssertEqual(sut.users.map{ $0.userinfo.userId }, ["2", "1"])
        sut.active(uid: user2.auth.sessionID)
        XCTAssertEqual(sut.users.map{ $0.userinfo.userId }, ["2", "1"])
        sut.active(uid: user1.auth.sessionID)
        XCTAssertEqual(sut.users.map{ $0.userinfo.userId }, ["1", "2"])
        sut.add(newUser: user3)
        XCTAssertEqual(sut.users.map{ $0.userinfo.userId }, ["1", "2", "3"])
        sut.active(uid: user2.auth.sessionID)
        XCTAssertEqual(sut.users.map{ $0.userinfo.userId }, ["2", "1", "3"])
        sut.active(uid: user3.auth.sessionID)
        XCTAssertEqual(sut.users.map{ $0.userinfo.userId }, ["3", "2", "1"])
    }

    func testGetUserBySessionID() {
        XCTAssertNil(sut.getUser(bySessionID: "hello"))
        XCTAssertNil(sut.getUser(bySessionID: "1"))

        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        sut.add(newUser: user1)
        XCTAssertEqual(sut.getUser(bySessionID: "SessionID_1")?.userinfo, user1.userinfo)
        XCTAssertNil(sut.getUser(byUserId: "Hello"))
    }

    func testGetUserByUserID() {
        XCTAssertNil(sut.getUser(byUserId: "Hello"))
        XCTAssertNil(sut.getUser(byUserId: "1"))

        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        sut.add(newUser: user1)
        XCTAssertEqual(sut.getUser(byUserId: "1")?.userinfo, user1.userinfo)
        XCTAssertNil(sut.getUser(byUserId: "Hello"))
    }

    func testRemoveUser() {
        let user1 = createUserManagerMock(userID: "1", isPaid: false)
        let user2 = createUserManagerMock(userID: "2", isPaid: false)
        sut.add(newUser: user1)
        sut.add(newUser: user2)
        XCTAssertTrue(sut.disconnectedUsers.isEmpty)
        XCTAssertEqual(sut.users.count, 2)
        sut.remove(user: user1)
        XCTAssertEqual(sut.users.count, 1)
        XCTAssertEqual(sut.disconnectedUsers.count, 1)
        XCTAssertEqual(sut.users[0].userinfo, user2.userinfo)
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
        let auth = AuthCredential(sessionID: "SessionID_\(userID)",
                                   accessToken: "",
                                   refreshToken: "",
                                   expiration: Date(),
                                   userName: userID,
                                   userID: userID,
                                   privateKey: nil,
                                   passwordKeySalt: nil)
        return UserManager(api: apiMock,
                                userinfo: userInfo,
                                auth: auth,
                                parent: sut)
    }
}
