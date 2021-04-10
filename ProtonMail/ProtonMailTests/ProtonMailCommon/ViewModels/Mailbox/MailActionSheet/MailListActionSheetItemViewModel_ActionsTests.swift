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
        sut = .unstarActionViewModel(number: 1)
        AssertEqualImage(sut.icon, Asset.actionSheetStar.image)
        XCTAssertEqual(sut.type, .unstar)
        let singleMessageFormat = LocalString._title_of_unstar_action_for_single_message_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))

        sut = .unstarActionViewModel(number: 3)
        let messagesFormat = LocalString._title_of_unstar_action_for_messages_in_action_sheet
        XCTAssertEqual(sut.title, String(format: messagesFormat, 3))
    }

    func testStarActionViewModel() {
        sut = .starActionViewModel(number: 1)
        AssertEqualImage(sut.icon, Asset.actionSheetStar.image)
        XCTAssertEqual(sut.type, .star)
        let singleMessageFormat = LocalString._title_of_star_action_for_single_message_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))

        sut = .starActionViewModel(number: 3)
        let messagesFormat = LocalString._title_of_star_action_for_messages_in_action_sheet
        XCTAssertEqual(sut.title, String(format: messagesFormat, 3))
    }

    func testMarkReadActionViewModel() {
        sut = .markReadActionViewModel(number: 1)
        AssertEqualImage(sut.icon, Asset.actionSheetRead.image)
        XCTAssertEqual(sut.type, .markRead)
        let singleMessageFormat = LocalString._title_of_read_action_for_single_message_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))

        sut = .markReadActionViewModel(number: 3)
        let messagesFormat = LocalString._title_of_read_action_for_messages_in_action_sheet
        XCTAssertEqual(sut.title, String(format: messagesFormat, 3))
    }

    func testMarkUnreadActionViewModel() {
        sut = .markUnreadActionViewModel(number: 1)
        AssertEqualImage(sut.icon, Asset.actionSheetUnread.image)
        XCTAssertEqual(sut.type, .markUnread)
        let singleMessageFormat = LocalString._title_of_unread_action_for_single_message_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))

        sut = .markUnreadActionViewModel(number: 3)
        let messagesFormat = LocalString._title_of_unread_action_for_messages_in_action_sheet
        XCTAssertEqual(sut.title, String(format: messagesFormat, 3))
    }

    func testRemoveActionViewModel() {
        sut = .removeActionViewModel(number: 1)
        AssertEqualImage(sut.icon, Asset.actionSheetTrash.image)
        XCTAssertEqual(sut.type, .remove)
        let singleMessageFormat = LocalString._title_of_remove_action_for_single_message_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))

        sut = .removeActionViewModel(number: 3)
        let messagesFormat = LocalString._title_of_remove_action_for_messages_in_action_sheet
        XCTAssertEqual(sut.title, String(format: messagesFormat, 3))
    }

    func testDeleteActionViewModel() {
        sut = .deleteActionViewModel(number: 1)
        AssertEqualImage(sut.icon, Asset.actionSheetTrash.image)
        XCTAssertEqual(sut.type, .delete)
        let singleMessageFormat = LocalString._title_of_delete_action_for_single_message_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))

        sut = .deleteActionViewModel(number: 3)
        let messagesFormat = LocalString._title_of_delete_action_for_messages_in_action_sheet
        XCTAssertEqual(sut.title, String(format: messagesFormat, 3))
    }

    func testMoveToArchiveActionViewModel() {
        sut = .moveToArchive(number: 1)
        AssertEqualImage(sut.icon, Asset.actionSheetArchive.image)
        XCTAssertEqual(sut.type, .moveToArchive)
        let singleMessageFormat = LocalString._title_of_archive_action_for_single_message_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))

        sut = .moveToArchive(number: 3)
        let messagesFormat = LocalString._title_of_archive_action_for_messages_in_action_sheet
        XCTAssertEqual(sut.title, String(format: messagesFormat, 3))
    }

    func testMoveToSpamActionViewModel() {
        sut = .moveToSpam(number: 1)
        AssertEqualImage(sut.icon, Asset.actionSheetSpam.image)
        XCTAssertEqual(sut.type, .moveToSpam)
        let singleMessageFormat = LocalString._title_of_spam_action_for_single_message_in_action_sheet
        XCTAssertEqual(sut.title, String(format: singleMessageFormat, 1))

        sut = .moveToSpam(number: 3)
        let messagesFormat = LocalString._title_of_spam_action_for_messages_in_action_sheet
        XCTAssertEqual(sut.title, String(format: messagesFormat, 3))
    }

}
