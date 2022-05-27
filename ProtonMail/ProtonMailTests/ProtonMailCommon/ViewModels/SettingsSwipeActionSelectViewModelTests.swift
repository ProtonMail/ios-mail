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

import XCTest
@testable import ProtonMail

class SettingsSwipeActionSelectViewModelTests: XCTestCase {

    var sut: SettingsSwipeActionSelectViewModelImpl!
    var swipeActionCacheStub: SwipeActionCacheStub!
    var selectedAction: SwipeActionItems = .left

    override func setUp() {
        swipeActionCacheStub = SwipeActionCacheStub()
        sut = SettingsSwipeActionSelectViewModelImpl(cache: swipeActionCacheStub, selectedAction: selectedAction)
    }

    override func tearDown() {
        sut = nil
        swipeActionCacheStub = nil
    }

    func testGetCurrentAction() {
        swipeActionCacheStub.leftToRightSwipeActionType = .archive

        XCTAssertEqual(sut.currentAction(), .archive)
    }

    func testUpdateSwipeAction() {
        swipeActionCacheStub.leftToRightSwipeActionType = .archive

        sut.updateSwipeAction(.trash)

        XCTAssertEqual(swipeActionCacheStub.leftToRightSwipeActionType, .trash)
    }

    func testRightToLeftGetCurrentAction() {
        sut = SettingsSwipeActionSelectViewModelImpl(cache: swipeActionCacheStub, selectedAction: .right)

        swipeActionCacheStub.rightToLeftSwipeActionType = .moveTo

        XCTAssertEqual(sut.currentAction(), .moveTo)
    }

    func testUpdateRightToLeftSwipeAction() {
        sut = SettingsSwipeActionSelectViewModelImpl(cache: swipeActionCacheStub, selectedAction: .right)
        swipeActionCacheStub.rightToLeftSwipeActionType = .moveTo

        sut.updateSwipeAction(.starAndUnstar)

        XCTAssertEqual(swipeActionCacheStub.rightToLeftSwipeActionType, .starAndUnstar)
    }
}
