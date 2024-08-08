//
//  SettingsGestureViewModelTests.swift
//  ProtonMailTests
//
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

@testable import ProtonMail
import XCTest

class SettingsGestureViewModelTests: XCTestCase {
    var sut: SettingsGestureViewModelImpl!
    var swipeActionCacheStub: SwipeActionCacheStub!
    var swipeActionInfoStub: MockSwipeActionInfo!

    override func setUp() {
        swipeActionCacheStub = SwipeActionCacheStub()
        swipeActionInfoStub = MockSwipeActionInfo()
        sut = SettingsGestureViewModelImpl(cache: swipeActionCacheStub, swipeActionInfo: swipeActionInfoStub)
    }

    override func tearDown() {
        sut = nil
        swipeActionCacheStub = nil
        swipeActionInfoStub = nil
    }

    func testGetLeftToRightSwipeAction() {
        swipeActionCacheStub.leftToRightSwipeActionType = .archive

        XCTAssertEqual(sut.leftToRightAction, .archive)
    }

    func testGetLeftToRightSwipeAction_withInvalidServerValue_returnArchiveAsDefaultAction() {
        swipeActionCacheStub.leftToRightSwipeActionType = nil
        swipeActionInfoStub.swipeRightStub.fixture = Int.random(in: 5...Int.max)

        XCTAssertEqual(sut.leftToRightAction, .archive)
    }

    func testGetRightToLeftSwipeAction() {
        swipeActionCacheStub.rightToLeftSwipeActionType = .archive

        XCTAssertEqual(sut.rightToLeftAction, .archive)
    }

    func testGetRightToLeftSwipeAction_withInvalidServerValue_returnArchiveAsDefaultAction() {
        swipeActionCacheStub.rightToLeftSwipeActionType = nil
        swipeActionInfoStub.swipeLeftStub.fixture = Int.random(in: 5...Int.max)

        XCTAssertEqual(sut.rightToLeftAction, .archive)
    }

    func testSettingSwipeActionItems() {
        XCTAssertEqual(sut.settingSwipeActionItems.count, 5)
        XCTAssertEqual(sut.settingSwipeActionItems, [.rightActionView, .right, .empty, .leftActionView, .left])
    }

    func testMigration() {
        swipeActionCacheStub.initialSwipeActionIfNeeded(leftToRight: 0,
                                                        rightToLeft: 1)
        XCTAssertEqual(sut.leftToRightAction, .trash)
        XCTAssertEqual(sut.rightToLeftAction, .spam)

        swipeActionCacheStub.initialSwipeActionIfNeeded(leftToRight: 2,
                                                        rightToLeft: 3)
        XCTAssertEqual(sut.leftToRightAction, .starAndUnstar)
        XCTAssertEqual(sut.rightToLeftAction, .archive)

        swipeActionCacheStub.initialSwipeActionIfNeeded(leftToRight: 4,
                                                        rightToLeft: 5)
        XCTAssertEqual(sut.leftToRightAction, .readAndUnread)
        XCTAssertEqual(sut.rightToLeftAction, .none)
    }
}
