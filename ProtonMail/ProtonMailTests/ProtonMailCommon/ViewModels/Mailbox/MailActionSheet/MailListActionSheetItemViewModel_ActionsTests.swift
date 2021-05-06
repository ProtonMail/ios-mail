//
//  MailListActionSheetItemViewModel+ActionsTests.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

@testable import ProtonMail
import XCTest

class MailListActionSheetItemViewModel_ActionsTests: XCTestCase {

    var sut: MailListActionSheetItemViewModel!

    override func tearDown() {
        super.tearDown()

        sut = nil
    }

    func testUnstarActionViewModel() {
        sut = .unstarActionViewModel()
        AssertEqualImage(sut.icon, Asset.actionSheetUnstar.image)
        XCTAssertEqual(sut.type, .unstar)
        let singleMessageFormat = LocalString._title_of_unstar_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testStarActionViewModel() {
        sut = .starActionViewModel()
        AssertEqualImage(sut.icon, Asset.actionSheetStar.image)
        XCTAssertEqual(sut.type, .star)
        let singleMessageFormat = LocalString._title_of_star_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testMarkReadActionViewModel() {
        sut = .markReadActionViewModel()
        AssertEqualImage(sut.icon, Asset.actionSheetRead.image)
        XCTAssertEqual(sut.type, .markRead)
        let singleMessageFormat = LocalString._title_of_read_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testMarkUnreadActionViewModel() {
        sut = .markUnreadActionViewModel()
        AssertEqualImage(sut.icon, Asset.actionSheetUnread.image)
        XCTAssertEqual(sut.type, .markUnread)
        let singleMessageFormat = LocalString._title_of_unread_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testRemoveActionViewModel() {
        sut = .removeActionViewModel()
        AssertEqualImage(sut.icon, Asset.actionSheetTrash.image)
        XCTAssertEqual(sut.type, .remove)
        let singleMessageFormat = LocalString._title_of_remove_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testDeleteActionViewModel() {
        sut = .deleteActionViewModel()
        AssertEqualImage(sut.icon, Asset.actionSheetTrash.image)
        XCTAssertEqual(sut.type, .delete)
        let singleMessageFormat = LocalString._title_of_delete_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testMoveToArchiveActionViewModel() {
        sut = .moveToArchive()
        AssertEqualImage(sut.icon, Asset.actionSheetArchive.image)
        XCTAssertEqual(sut.type, .moveToArchive)
        let singleMessageFormat = LocalString._title_of_archive_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testMoveToSpamActionViewModel() {
        sut = .moveToSpam()
        AssertEqualImage(sut.icon, Asset.actionSheetSpam.image)
        XCTAssertEqual(sut.type, .moveToSpam)
        let singleMessageFormat = LocalString._title_of_spam_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testLabelAsActionViewModel() {
        sut = .labelAsActionViewModel()
        AssertEqualImage(sut.icon, Asset.swipeLabelAs.image)
        XCTAssertEqual(sut.type, .labelAs)
        XCTAssertEqual(sut.title, LocalString._label_as_)
    }

    func testMoveToActionViewModel() {
        sut = .moveToActionViewModel()
        AssertEqualImage(sut.icon, Asset.swipeMoveTo.image)
        XCTAssertEqual(sut.type, .moveTo)
        XCTAssertEqual(sut.title, LocalString._move_to_)
    }

    func testMoveToInboxActionViewModel() {
        sut = .moveToInboxActionViewModel()
        AssertEqualImage(sut.icon, Asset.menuInbox.image)
        XCTAssertEqual(sut.type, .moveToInbox)
        XCTAssertEqual(sut.title, LocalString._title_of_move_inbox_action_in_action_sheet)
    }

    func testNotSpamActionViewModel() {
        sut = .notSpamActionViewModel()
        AssertEqualImage(sut.icon, Asset.menuInbox.image)
        XCTAssertEqual(sut.type, .moveToInbox)
        XCTAssertEqual(sut.title, LocalString._action_sheet_action_title_spam_to_inbox)
    }
}
