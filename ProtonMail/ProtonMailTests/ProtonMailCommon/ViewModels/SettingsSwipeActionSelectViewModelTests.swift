//
//  SettingsSwipeActionSelectViewModelTests.swift
//  Proton MailTests
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

import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

class MockSaveSwipeActionSettingForUsersUseCase: SaveSwipeActionSettingForUsersUseCase {
    @FuncStub(MockSaveSwipeActionSettingForUsersUseCase.execute) var callExecute
    func execute(preference: SwipeActionPreference, completion: ((Result<Void, UpdateSwipeActionError>) -> Void)?) {
        callExecute(preference, completion)
    }
}

class SettingsSwipeActionSelectViewModelTests: XCTestCase {
    var sut: SettingsSwipeActionSelectViewModelImpl!
    var swipeActionCacheStub: SwipeActionCacheStub!
    var selectedAction: SwipeActionItems = .left
    var saveSwipeActionSettingForUsersUseCaseMock: MockSaveSwipeActionSettingForUsersUseCase!

    override func setUp() {
        swipeActionCacheStub = SwipeActionCacheStub()
        saveSwipeActionSettingForUsersUseCaseMock = MockSaveSwipeActionSettingForUsersUseCase()
        sut = SettingsSwipeActionSelectViewModelImpl(cache: swipeActionCacheStub, selectedAction: selectedAction, dependencies: .init(saveSwipeActionSetting: saveSwipeActionSettingForUsersUseCaseMock))
    }

    override func tearDown() {
        sut = nil
        swipeActionCacheStub = nil
        saveSwipeActionSettingForUsersUseCaseMock = nil
    }

    func testGetCurrentAction() {
        swipeActionCacheStub.rightToLeftSwipeActionType = .archive

        XCTAssertEqual(sut.currentAction(), .archive)
    }

    func testUpdateLeftToRightSwipeAction() throws {
        let expectation1 = expectation(description: "Closure is called")
        saveSwipeActionSettingForUsersUseCaseMock.callExecute.bodyIs { _, _, completion  in
            completion?(.success)
        }
        sut.updateSwipeAction(.trash, completion: {
            expectation1.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(saveSwipeActionSettingForUsersUseCaseMock.callExecute.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(saveSwipeActionSettingForUsersUseCaseMock.callExecute.lastArguments?.a1)
        XCTAssertEqual(argument, .left(.trash))
    }

    func testRightToLeftGetCurrentAction() {
        sut = SettingsSwipeActionSelectViewModelImpl(cache: swipeActionCacheStub, selectedAction: .right, dependencies: .init(saveSwipeActionSetting: saveSwipeActionSettingForUsersUseCaseMock))

        swipeActionCacheStub.leftToRightSwipeActionType = .moveTo

        XCTAssertEqual(sut.currentAction(), .moveTo)
    }

    func testUpdateRightToLeftSwipeAction() throws {
        sut = SettingsSwipeActionSelectViewModelImpl(cache: swipeActionCacheStub, selectedAction: .right, dependencies: .init(saveSwipeActionSetting: saveSwipeActionSettingForUsersUseCaseMock))
        saveSwipeActionSettingForUsersUseCaseMock.callExecute.bodyIs { _, _, completion  in
            completion?(.success)
        }
        let expectation1 = expectation(description: "Closure is called")

        sut.updateSwipeAction(.starAndUnstar, completion: {
            expectation1.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(saveSwipeActionSettingForUsersUseCaseMock.callExecute.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(saveSwipeActionSettingForUsersUseCaseMock.callExecute.lastArguments?.a1)
        XCTAssertEqual(argument, .right(.starAndUnstar))
    }

    func testCheckIsActionAbleToBeSynced() {
        let allowedActions: [SwipeActionSettingType] = [
            .trash,
            .spam,
            .starAndUnstar,
            .archive,
            .readAndUnread
        ]
        let notAllowedActions = SwipeActionSettingType.allCases.filter { !allowedActions.contains($0) }

        for action in allowedActions {
            XCTAssertTrue(sut.isActionSyncable(action))
        }
        for action in notAllowedActions {
            XCTAssertFalse(sut.isActionSyncable(action))
        }
    }
}
