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

class SaveSwipeActionSettingForUsersUseCaseTests: XCTestCase {
    var sut: SaveSwipeActionSettingForUsersUseCase!
    var firstUserAPI: APIServiceMock!
    var secondUserAPI: APIServiceMock!
    var swipeActionCacheStub: SwipeActionCacheStub!

    override func setUp() {
        super.setUp()
        firstUserAPI = APIServiceMock()
        secondUserAPI = APIServiceMock()
        swipeActionCacheStub = SwipeActionCacheStub()
        sut = SaveSwipeActionSetting(dependencies: .init(swipeActionCache: swipeActionCacheStub, usersApiServices: [firstUserAPI, secondUserAPI]))
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        firstUserAPI = nil
        secondUserAPI = nil
        swipeActionCacheStub = nil
    }

    func testUpdateSwipeLeft_withValidAction_success() {
        let expectation1 = expectation(description: "Closure is called")
        swipeActionCacheStub.rightToLeftSwipeActionType = .archive
        swipeActionCacheStub.leftToRightSwipeActionType = .archive
        firstUserAPI.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains("/settings/mail/swipeleft") {
                completion(nil, .success(["Code": 1000]))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.badResponse()))
            }
        }
        secondUserAPI.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains("/settings/mail/swipeleft") {
                completion(nil, .success(["Code": 1000]))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.badResponse()))
            }
        }

        sut.execute(preference: .left(.trash)) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Should not get here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(swipeActionCacheStub.rightToLeftSwipeActionType, .trash)
        XCTAssertEqual(swipeActionCacheStub.leftToRightSwipeActionType, .archive)
        XCTAssertTrue(firstUserAPI.requestJSONStub.wasCalledExactlyOnce)
        XCTAssertTrue(secondUserAPI.requestJSONStub.wasCalledExactlyOnce)
    }

    func testUpdateSwipeLeft_withInvalidAction_success() {
        let expectation1 = expectation(description: "Closure is called")
        swipeActionCacheStub.rightToLeftSwipeActionType = .archive
        swipeActionCacheStub.leftToRightSwipeActionType = .archive

        sut.execute(preference: .left(.moveTo)) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Should not get here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(swipeActionCacheStub.rightToLeftSwipeActionType, .moveTo)
        XCTAssertEqual(swipeActionCacheStub.leftToRightSwipeActionType, .archive)
        XCTAssertTrue(firstUserAPI.requestJSONStub.wasNotCalled)
        XCTAssertTrue(secondUserAPI.requestJSONStub.wasNotCalled)
    }

    func testUpdateSwipeRight_withValidAction_success() {
        let expectation1 = expectation(description: "Closure is called")
        swipeActionCacheStub.rightToLeftSwipeActionType = .archive
        swipeActionCacheStub.leftToRightSwipeActionType = .archive
        firstUserAPI.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains("/settings/mail/swiperight") {
                completion(nil, .success(["Code": 1000]))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.badResponse()))
            }
        }
        secondUserAPI.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains("/settings/mail/swiperight") {
                completion(nil, .success(["Code": 1000]))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.badResponse()))
            }
        }

        sut.execute(preference: .right(.trash)) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Should not get here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(swipeActionCacheStub.rightToLeftSwipeActionType, .archive)
        XCTAssertEqual(swipeActionCacheStub.leftToRightSwipeActionType, .trash)
        XCTAssertTrue(firstUserAPI.requestJSONStub.wasCalledExactlyOnce)
        XCTAssertTrue(secondUserAPI.requestJSONStub.wasCalledExactlyOnce)
    }

    func testUpdateSwipeRight_withInvalidAction_success() {
        let expectation1 = expectation(description: "Closure is called")
        swipeActionCacheStub.rightToLeftSwipeActionType = .archive
        swipeActionCacheStub.leftToRightSwipeActionType = .archive

        sut.execute(preference: .right(.moveTo)) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Should not get here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(swipeActionCacheStub.rightToLeftSwipeActionType, .archive)
        XCTAssertEqual(swipeActionCacheStub.leftToRightSwipeActionType, .moveTo)
        XCTAssertTrue(firstUserAPI.requestJSONStub.wasNotCalled)
        XCTAssertTrue(secondUserAPI.requestJSONStub.wasNotCalled)
    }
}
