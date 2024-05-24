//
//  SettingsSwipeActionSelectViewModelTests.swift
//  ProtonMailTests
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

import ProtonCoreTestingToolkitUnitTestsCore
@testable import ProtonMail
import XCTest

class MockSaveSwipeActionSettingForUsersUseCase: SaveSwipeActionSettingForUsersUseCase {
    @FuncStub(MockSaveSwipeActionSettingForUsersUseCase.execute) var callExecute
    override func execute(params: SaveSwipeActionSetting.Parameters, callback: @escaping UseCase<Void, SaveSwipeActionSetting.Parameters>.Callback) {
        callExecute(params, callback)
    }
}

class SettingsSwipeActionSelectViewModelTests: XCTestCase {
    var sut: SettingsSwipeActionSelectViewModelImpl!
    var swipeActionCacheStub: SwipeActionCacheStub!
    var selectedAction: SwipeActionItems = .left
    var saveSwipeActionSettingForUsersUseCaseMock: MockSaveSwipeActionSettingForUsersUseCase!

    private var globalContainer: GlobalContainer!

    override func setUp() {
        super.setUp()

        swipeActionCacheStub = SwipeActionCacheStub()
        saveSwipeActionSettingForUsersUseCaseMock = MockSaveSwipeActionSettingForUsersUseCase()

        globalContainer = .init()
        globalContainer.swipeActionCacheFactory.register { self.swipeActionCacheStub }
        globalContainer.saveSwipeActionSettingFactory.register { self.saveSwipeActionSettingForUsersUseCaseMock }

        sut = SettingsSwipeActionSelectViewModelImpl(dependencies: globalContainer, selectedAction: selectedAction)
    }

    override func tearDown() {
        sut = nil
        swipeActionCacheStub = nil
        saveSwipeActionSettingForUsersUseCaseMock = nil
        globalContainer = nil

        super.tearDown()
    }

    func testGetCurrentAction() {
        swipeActionCacheStub.rightToLeftSwipeActionType = .archive

        XCTAssertEqual(sut.currentAction(), .archive)
    }

    func testUpdateLeftToRightSwipeAction() throws {
        let expectation1 = expectation(description: "Closure is called")
        saveSwipeActionSettingForUsersUseCaseMock.callExecute.bodyIs { _, _, completion  in
            completion(.success)
        }
        sut.updateSwipeAction(.trash, completion: {
            expectation1.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(saveSwipeActionSettingForUsersUseCaseMock.callExecute.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(saveSwipeActionSettingForUsersUseCaseMock.callExecute.lastArguments?.a1)
        XCTAssertEqual(argument, .init(preference: .left(.trash)))
    }

    func testRightToLeftGetCurrentAction() {
        sut = SettingsSwipeActionSelectViewModelImpl(dependencies: globalContainer, selectedAction: .right)

        swipeActionCacheStub.leftToRightSwipeActionType = .moveTo

        XCTAssertEqual(sut.currentAction(), .moveTo)
    }

    func testUpdateRightToLeftSwipeAction() throws {
        sut = SettingsSwipeActionSelectViewModelImpl(dependencies: globalContainer, selectedAction: .right)
        saveSwipeActionSettingForUsersUseCaseMock.callExecute.bodyIs { _, _, completion  in
            completion(.success)
        }
        let expectation1 = expectation(description: "Closure is called")

        sut.updateSwipeAction(.starAndUnstar, completion: {
            expectation1.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(saveSwipeActionSettingForUsersUseCaseMock.callExecute.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(saveSwipeActionSettingForUsersUseCaseMock.callExecute.lastArguments?.a1)
        XCTAssertEqual(argument, .init(preference: .right(.starAndUnstar)))
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
