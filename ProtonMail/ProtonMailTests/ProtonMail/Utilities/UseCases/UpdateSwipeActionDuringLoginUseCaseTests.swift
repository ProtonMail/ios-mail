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

import ProtonCoreDataModel
import XCTest

@testable import ProtonMail

class UpdateSwipeActionDuringLoginUseCaseTests: XCTestCase {
    var sut: UpdateSwipeActionDuringLoginUseCase!
    var stubSwipeActionCache: SwipeActionCacheStub!

    private var globalContainer: GlobalContainer!
    private var activeUserInfo, newUserInfo: UserInfo!

    override func setUp() {
        super.setUp()
        stubSwipeActionCache = SwipeActionCacheStub()
        globalContainer = .init()
        globalContainer.swipeActionCacheFactory.register { self.stubSwipeActionCache }
        sut = UpdateSwipeActionDuringLogin(dependencies: globalContainer)

        activeUserInfo = .getDefault()
        activeUserInfo.userId = "test"
        activeUserInfo.swipeRight = 0
        activeUserInfo.swipeLeft = 1

        newUserInfo = .getDefault()
        newUserInfo.userId = "test1"
        newUserInfo.swipeRight = 0
        newUserInfo.swipeLeft = 1
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        globalContainer = nil
        stubSwipeActionCache = nil
        activeUserInfo = nil
        newUserInfo = nil
    }

    func testUpdateSwipeAction_activeUserIsTheSameAsNewUser_saveSwipeActionToCache() throws {
        stubSwipeActionCache.leftToRightSwipeActionType = nil
        stubSwipeActionCache.rightToLeftSwipeActionType = nil
        let expectation1 = expectation(description: "Closure is called")

        sut.execute(
            params: .init(
                activeUserInfo: activeUserInfo,
                newUserInfo: activeUserInfo
            )) { _ in
                expectation1.fulfill()
            }
        waitForExpectations(timeout: 1, handler: nil)

        let leftToRight = try XCTUnwrap(stubSwipeActionCache.leftToRightSwipeActionType)
        XCTAssertEqual(leftToRight,
                       SwipeActionSettingType.convertFromServer(rawValue: activeUserInfo.swipeRight))

        let rightToLeft = try XCTUnwrap(stubSwipeActionCache.rightToLeftSwipeActionType)
        XCTAssertEqual(rightToLeft,
                       SwipeActionSettingType.convertFromServer(rawValue: activeUserInfo.swipeLeft))
    }

    func testUpdateSwipeAction_activeUserHasSameActionAsNewUser_noAPIIsCalled() throws {
        stubSwipeActionCache.leftToRightSwipeActionType = .convertFromServer(rawValue: 0)
        stubSwipeActionCache.rightToLeftSwipeActionType = .convertFromServer(rawValue: 1)

        let expectation1 = expectation(description: "Closure is called")

        sut.execute(
            params: .init(
                activeUserInfo: activeUserInfo,
                newUserInfo: newUserInfo
            )
        ) { _ in
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        let leftToRight = try XCTUnwrap(stubSwipeActionCache.leftToRightSwipeActionType)
        XCTAssertEqual(leftToRight,
                       SwipeActionSettingType.convertFromServer(rawValue: activeUserInfo.swipeRight))

        let rightToLeft = try XCTUnwrap(stubSwipeActionCache.rightToLeftSwipeActionType)
        XCTAssertEqual(rightToLeft,
                       SwipeActionSettingType.convertFromServer(rawValue: activeUserInfo.swipeLeft))
    }

    func testUpdateSwipeAction_activeUserHasNotSyncableAction_notAPIIsCalled() throws {
        stubSwipeActionCache.leftToRightSwipeActionType = .labelAs
        stubSwipeActionCache.rightToLeftSwipeActionType = .moveTo

        newUserInfo.swipeRight = 2
        newUserInfo.swipeLeft = 3

        let expectation1 = expectation(description: "Closure is called")

        sut.execute(
            params: .init(
                activeUserInfo: activeUserInfo,
                newUserInfo: newUserInfo
            )
        ) { _ in
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        let leftToRight = try XCTUnwrap(stubSwipeActionCache.leftToRightSwipeActionType)
        XCTAssertEqual(leftToRight, .labelAs)

        let rightToLeft = try XCTUnwrap(stubSwipeActionCache.rightToLeftSwipeActionType)
        XCTAssertEqual(rightToLeft, .moveTo)
    }
}
