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

import XCTest
@testable import ProtonMail

class SettingsGestureViewModelTests: XCTestCase {

    var sut: SettingsGestureViewModelImpl!
    var swipeActionCacheStub: SwipeActionCacheStub!

    override func setUp() {
        swipeActionCacheStub = SwipeActionCacheStub()
        sut = SettingsGestureViewModelImpl(cache: swipeActionCacheStub)
    }

    override func tearDown() {
        sut = nil
        swipeActionCacheStub = nil
    }

    func testGetLeftToRightSwipeAction() {
        swipeActionCacheStub.leftToRightSwipeActionType = .archive

        XCTAssertEqual(sut.leftToRightAction, .archive)
    }

    func testGetRightToLeftSwipeAction() {
        swipeActionCacheStub.rightToLeftSwipeActionType = .archive

        XCTAssertEqual(sut.rightToLeftAction, .archive)
    }

    func testSetRightToLeftSwipeAction() {
        sut.rightToLeftAction = .labelAs

        XCTAssertEqual(sut.rightToLeftAction, .labelAs)
    }

    func testSetLeftToRightSwipeAction() {
        sut.leftToRightAction = .labelAs

        XCTAssertEqual(sut.leftToRightAction, .labelAs)
    }

    func testSettingSwipeActionItems() {
        XCTAssertEqual(sut.settingSwipeActionItems.count, 5)
        XCTAssertEqual(sut.settingSwipeActionItems, [.leftActionView, .left, .empty, .rightActionView, .right])
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
