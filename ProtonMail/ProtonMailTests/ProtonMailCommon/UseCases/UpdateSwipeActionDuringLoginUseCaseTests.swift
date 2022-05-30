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

import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

class UpdateSwipeActionDuringLoginUseCaseTests: XCTestCase {
    var sut: UpdateSwipeActionDuringLoginUseCase!
    var stubSwipeActionCache: SwipeActionCacheStub!
    override func setUp() {
        super.setUp()
        stubSwipeActionCache = SwipeActionCacheStub()
        sut = UpdateSwipeActionDuringLogin(dependencies: .init(swipeActionCache: stubSwipeActionCache))
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        stubSwipeActionCache = nil
    }

    func testUpdateSwipeAction_activeUserIsTheSameAsNewUser_saveSwipeActionToCache() throws {
        let mockApi = APIServiceMock()
        let user = UserManager(api: mockApi, role: .none)
        user.userinfo.userId = "test"
        user.userinfo.swipeRight = 0
        user.userinfo.swipeLeft = 1
        stubSwipeActionCache.leftToRightSwipeActionType = nil
        stubSwipeActionCache.rightToLeftSwipeActionType = nil
        let expectation1 = expectation(description: "Closure is called")

        sut.execute(activeUserInfo: user.userinfo,
                    newUserInfo: user.userinfo,
                    newUserApiService: mockApi) {
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(mockApi.requestStub.wasNotCalled)
        let leftToRight = try XCTUnwrap(stubSwipeActionCache.leftToRightSwipeActionType)
        XCTAssertEqual(leftToRight,
                       SwipeActionSettingType.convertFromServer(rawValue: user.userinfo.swipeRight))

        let rightToLeft = try XCTUnwrap(stubSwipeActionCache.rightToLeftSwipeActionType)
        XCTAssertEqual(rightToLeft,
                       SwipeActionSettingType.convertFromServer(rawValue: user.userinfo.swipeLeft))
    }

    func testUpdateSwipeAction_activeUserHasSameActionAsNewUser_noAPIIsCalled() throws {
        let activeUser = UserManager(api: APIServiceMock(), role: .none)
        activeUser.userinfo.userId = "test"
        activeUser.userinfo.swipeRight = 0
        activeUser.userinfo.swipeLeft = 1
        stubSwipeActionCache.leftToRightSwipeActionType = .convertFromServer(rawValue: 0)
        stubSwipeActionCache.rightToLeftSwipeActionType = .convertFromServer(rawValue: 1)

        let mockApi = APIServiceMock()
        let newUser = UserManager(api: mockApi, role: .none)
        newUser.userinfo.userId = "test1"
        newUser.userinfo.swipeRight = 0
        newUser.userinfo.swipeLeft = 1

        let expectation1 = expectation(description: "Closure is called")

        sut.execute(activeUserInfo: activeUser.userinfo,
                    newUserInfo: newUser.userinfo,
                    newUserApiService: mockApi) {
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(mockApi.requestStub.wasNotCalled)
        let leftToRight = try XCTUnwrap(stubSwipeActionCache.leftToRightSwipeActionType)
        XCTAssertEqual(leftToRight,
                       SwipeActionSettingType.convertFromServer(rawValue: activeUser.userinfo.swipeRight))

        let rightToLeft = try XCTUnwrap(stubSwipeActionCache.rightToLeftSwipeActionType)
        XCTAssertEqual(rightToLeft,
                       SwipeActionSettingType.convertFromServer(rawValue: activeUser.userinfo.swipeLeft))
    }

    func testUpdateSwipeAction_activeUserHasNotSyncableAction_notAPIIsCalled() throws {
        let activeUser = UserManager(api: APIServiceMock(), role: .none)
        activeUser.userinfo.userId = "test"
        activeUser.userinfo.swipeRight = 0
        activeUser.userinfo.swipeLeft = 1
        stubSwipeActionCache.leftToRightSwipeActionType = .labelAs
        stubSwipeActionCache.rightToLeftSwipeActionType = .moveTo

        let mockApi = APIServiceMock()
        let newUser = UserManager(api: mockApi, role: .none)
        newUser.userinfo.userId = "test1"
        newUser.userinfo.swipeRight = 2
        newUser.userinfo.swipeLeft = 3

        let expectation1 = expectation(description: "Closure is called")

        sut.execute(activeUserInfo: activeUser.userinfo,
                    newUserInfo: newUser.userinfo,
                    newUserApiService: mockApi) {
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(mockApi.requestStub.wasNotCalled)
        let leftToRight = try XCTUnwrap(stubSwipeActionCache.leftToRightSwipeActionType)
        XCTAssertEqual(leftToRight, .labelAs)

        let rightToLeft = try XCTUnwrap(stubSwipeActionCache.rightToLeftSwipeActionType)
        XCTAssertEqual(rightToLeft, .moveTo)
    }
}

class FakeQueueHandlerRegister: QueueHandlerRegister {
    func registerHandler(_ handler: QueueHandler) {}

    func unregisterHandler(_ handler: QueueHandler) {}
}
