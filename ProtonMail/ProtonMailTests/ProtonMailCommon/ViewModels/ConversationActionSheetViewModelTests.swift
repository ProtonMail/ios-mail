// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

class ConversationActionSheetViewModelTests: XCTestCase {

    func testInit_withUnread_starred_allMsgInTrash_inbox() {
        let testTitle = String.randomString(100)
        let sut = ConversationActionSheetViewModel(title: testTitle,
                                                   labelID: Message.Location.inbox.labelID,
                                                   isUnread: true,
                                                   isStarred: true,
                                                   isAllMessagesInTrash: true)
        XCTAssertEqual(sut.title, testTitle)
        XCTAssertEqual(sut.items, [
            .markRead,
            .unstar,
            .labelAs,
            .archive,
            .spam,
            .moveTo
        ])
    }

    func testInit_withUnread_starred_allMsgInTrashFalse_inbox() {
        let testTitle = String.randomString(100)
        let sut = ConversationActionSheetViewModel(title: testTitle,
                                                   labelID: Message.Location.inbox.labelID,
                                                   isUnread: true,
                                                   isStarred: true,
                                                   isAllMessagesInTrash: false)
        XCTAssertEqual(sut.title, testTitle)
        XCTAssertEqual(sut.items, [
            .markRead,
            .unstar,
            .labelAs,
            .trash,
            .archive,
            .spam,
            .moveTo
        ])
    }

    func testInit_withUnread_notStarred_allMsgInTrash_inbox() {
        let testTitle = String.randomString(100)
        let sut = ConversationActionSheetViewModel(title: testTitle,
                                                   labelID: Message.Location.inbox.labelID,
                                                   isUnread: true,
                                                   isStarred: false,
                                                   isAllMessagesInTrash: false)
        XCTAssertEqual(sut.title, testTitle)
        XCTAssertEqual(sut.items, [
            .markRead,
            .star,
            .labelAs,
            .trash,
            .archive,
            .spam,
            .moveTo
        ])
    }

    func testInit_withRead_starred_allMsgInTrash_inbox() {
        let testTitle = String.randomString(100)
        let sut = ConversationActionSheetViewModel(title: testTitle,
                                                   labelID: Message.Location.inbox.labelID,
                                                   isUnread: false,
                                                   isStarred: true,
                                                   isAllMessagesInTrash: true)
        XCTAssertEqual(sut.title, testTitle)
        XCTAssertEqual(sut.items, [
            .markUnread,
            .unstar,
            .labelAs,
            .archive,
            .spam,
            .moveTo
        ])
    }

    func testInit_withUnread_starred_allMsgInTrash_spam() {
        let testTitle = String.randomString(100)
        let sut = ConversationActionSheetViewModel(title: testTitle,
                                                   labelID: Message.Location.spam.labelID,
                                                   isUnread: true,
                                                   isStarred: true,
                                                   isAllMessagesInTrash: true)
        XCTAssertEqual(sut.title, testTitle)
        XCTAssertEqual(sut.items, [
            .markRead,
            .unstar,
            .labelAs,
            .spamMoveToInbox,
            .delete,
            .moveTo
        ])
    }

    func testInit_withUnread_starred_allMsgInTrash_archive() {
        let testTitle = String.randomString(100)
        let sut = ConversationActionSheetViewModel(title: testTitle,
                                                   labelID: Message.Location.archive.labelID,
                                                   isUnread: true,
                                                   isStarred: true,
                                                   isAllMessagesInTrash: true)
        XCTAssertEqual(sut.title, testTitle)
        XCTAssertEqual(sut.items, [
            .markRead,
            .unstar,
            .labelAs,
            .inbox,
            .spam,
            .moveTo
        ])
    }
}
