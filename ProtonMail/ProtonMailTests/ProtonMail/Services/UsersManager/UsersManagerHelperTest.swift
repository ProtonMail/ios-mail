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

import ProtonCoreDataModel
import ProtonCoreServices
import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

class UsersManagerHelperTest: XCTestCase {
    private var apiMock: APIService!
    private var globalContainer: GlobalContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.apiMock = APIServiceMock()
        globalContainer = .init()
    }

    override func tearDown() {
        self.apiMock = nil
        globalContainer = nil

        super.tearDown()
    }

    func testNumberOfFreeAccounts_allFreeUsers() throws {
        let user1 = UserManager(api: apiMock, subscribed: .init(rawValue: 0))
        let user2 = UserManager(api: apiMock, subscribed: .init(rawValue: 0))
        let users = UsersManager(dependencies: globalContainer)
        users.add(newUser: user1)
        users.add(newUser: user2)
        XCTAssertEqual(users.numberOfFreeAccounts, 2)
    }

    func testNumberOfFreeAccounts_hasPaidUser() throws {
        let user1 = UserManager(api: apiMock, subscribed: .init(rawValue: 0))
        let user2 = UserManager(api: apiMock, subscribed: .mail)
        let user3 = UserManager(api: apiMock, subscribed: .drive)
        let users = UsersManager(dependencies: globalContainer)
        users.add(newUser: user1)
        users.add(newUser: user2)
        users.add(newUser: user3)
        XCTAssertEqual(users.numberOfFreeAccounts, 1)
    }

    func testIsAllowedNewUser_allowed_whenFreeAccountLessThanTwo_anyPaidAccountExemptFromLimit() {
        let user1 = UserManager(api: apiMock, subscribed: .init(rawValue: 0))
        let user2 = UserManager(api: apiMock, subscribed: .init(rawValue: 0))
        let users = UsersManager(dependencies: globalContainer)
        let userInfo = user1.userInfo
        XCTAssertTrue(users.isAllowedNewUser(userInfo: userInfo))

        let users2 = UsersManager(dependencies: globalContainer)
        users2.add(newUser: user2)
        XCTAssertTrue(users2.isAllowedNewUser(userInfo: userInfo))

        for _ in 0...4 {
            let plans: [User.Subscribed] = [.mail, .drive, .vpn]
            let paidUser = UserManager(api: apiMock, subscribed: plans.randomElement() ?? .mail)
            XCTAssertTrue(users.isAllowedNewUser(userInfo: paidUser.userInfo))
            users2.add(newUser: paidUser)
        }
    }

    func testIsAllowedNewUser_notAllowed_whenFreeAccountMoreThanTwo() {
        let user1 = UserManager(api: apiMock, subscribed: .init(rawValue: 0))
        let user2 = UserManager(api: apiMock, subscribed: .init(rawValue: 0))
        let users = UsersManager(dependencies: globalContainer)
        users.add(newUser: user1)
        let userInfo = user2.userInfo
        XCTAssertTrue(users.isAllowedNewUser(userInfo: userInfo))
        users.add(newUser: user2)

        let user3 = UserManager(api: apiMock, subscribed: .init(rawValue: 0))
        XCTAssertFalse(users.isAllowedNewUser(userInfo: user3.userInfo))
    }
}
