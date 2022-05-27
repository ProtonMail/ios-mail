//
//  MailListActionSheetItemViewModel+ActionsTests.swift
//  Proton Mail
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

class MailListActionSheetItemViewModel_ActionsTests: XCTestCase {

    var sut: MailListActionSheetItemViewModel!

    override func tearDown() {
        super.tearDown()

        sut = nil
    }

    func testUnstarActionViewModel() {
        sut = .unstarActionViewModel()
        XCTAssertEqual(sut.type, .unstar)
        let singleMessageFormat = LocalString._title_of_unstar_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testStarActionViewModel() {
        sut = .starActionViewModel()
        XCTAssertEqual(sut.type, .star)
        let singleMessageFormat = LocalString._title_of_star_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testMarkReadActionViewModel() {
        sut = .markReadActionViewModel()
        XCTAssertEqual(sut.type, .markRead)
        let singleMessageFormat = LocalString._title_of_read_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testMarkUnreadActionViewModel() {
        sut = .markUnreadActionViewModel()
        XCTAssertEqual(sut.type, .markUnread)
        let singleMessageFormat = LocalString._title_of_unread_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testRemoveActionViewModel() {
        sut = .removeActionViewModel()
        XCTAssertEqual(sut.type, .remove)
        let singleMessageFormat = LocalString._title_of_remove_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testDeleteActionViewModel() {
        sut = .deleteActionViewModel()
        XCTAssertEqual(sut.type, .delete)
        let singleMessageFormat = LocalString._title_of_delete_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testMoveToArchiveActionViewModel() {
        sut = .moveToArchive()
        XCTAssertEqual(sut.type, .moveToArchive)
        let singleMessageFormat = LocalString._title_of_archive_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testMoveToSpamActionViewModel() {
        sut = .moveToSpam()
        XCTAssertEqual(sut.type, .moveToSpam)
        let singleMessageFormat = LocalString._title_of_spam_action_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))
    }

    func testLabelAsActionViewModel() {
        sut = .labelAsActionViewModel()
        XCTAssertEqual(sut.type, .labelAs)
        XCTAssertEqual(sut.title, LocalString._label_as_)
    }

    func testMoveToActionViewModel() {
        sut = .moveToActionViewModel()
        XCTAssertEqual(sut.type, .moveTo)
        XCTAssertEqual(sut.title, LocalString._move_to_)
    }

    func testMoveToInboxActionViewModel() {
        sut = .moveToInboxActionViewModel()
        XCTAssertEqual(sut.type, .moveToInbox)
        XCTAssertEqual(sut.title, LocalString._title_of_move_inbox_action_in_action_sheet)
    }

    func testNotSpamActionViewModel() {
        sut = .notSpamActionViewModel()
        XCTAssertEqual(sut.type, .moveToInbox)
        XCTAssertEqual(sut.title, LocalString._action_sheet_action_title_spam_to_inbox)
    }
}
