// Copyright (c) 2021 Proton Technologies AG
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

final class MessageViewActionSheetViewModelAtomicTests: XCTestCase {
    var sut: MessageViewActionSheetViewModel!

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testShouldProperlySetTitle() {
        let aTitle = String.randomString(5)
        sut = MessageViewActionSheetViewModel(title: aTitle,
                                              labelID: "",
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssertEqual(sut.title, aTitle)
    }

    func testShouldAlwaysIncludeCommonItems() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: "",
                                              includeStarring: false,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              hasMoreThanOneRecipient: false)
        XCTAssertEqual(sut.items, [.reply, .forward, .markUnread, .labelAs, .trash, .archive, .spam, .moveTo, .print, .viewHeaders, .viewHTML, .reportPhishing])
    }

    func testShouldIncludeReplyAllOnlyWhenHasMoreThanOneRecipientIsTrue() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: "",
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: true)
        XCTAssert(sut.items.contains(.replyAll))
    }

    func testShouldNotIncludeReplyAllOnlyWhenHasMoreThanOneRecipientIsFalse() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: "",
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: false)
        XCTAssertFalse(sut.items.contains(.replyAll))
    }

    func testShouldIncludeStarringOnlyWhenIncludeStarringIsTrue() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: "",
                                              includeStarring: true,
                                              isStarred: false,
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssert(sut.items.contains(.star))
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: "",
                                              includeStarring: true,
                                              isStarred: true,
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssert(sut.items.contains(.unstar))
    }

    func testShouldNotIncludeStarringOnlyWhenIncludeStarringIsFalse() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: "",
                                              includeStarring: false,
                                              isStarred: false,
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssertFalse(sut.items.contains(.star))
        XCTAssertFalse(sut.items.contains(.unstar))
    }

    func testShouldIncludeTrashIfLabelIdIsOtherThanTrash() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: "",
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssert(sut.items.contains(.trash))
    }

    func testShouldNotIncludeTrashIfLabelIdIsTrash() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: Message.Location.trash.rawValue,
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssertFalse(sut.items.contains(.trash))
    }

    func testShouldNotIncludeArchiveIfLabelIdIsArchiveOrSpam() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: Message.Location.archive.rawValue,
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssertFalse(sut.items.contains(.archive))
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: Message.Location.spam.rawValue,
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssertFalse(sut.items.contains(.archive))
    }

    func testShouldIncludeArchiveIfLabelIdIsOtherThanArchiveOrSpam() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: "",
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssert(sut.items.contains(.archive))
    }

    func testShouldNotIncludeInboxIfLabelIdIsOtherThanArchiveOrTrash() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: "",
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssertFalse(sut.items.contains(.inbox))
    }

    func testShouldIncludeInboxIfLabelIdIsArchiveOrTrash() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: Message.Location.archive.rawValue,
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssert(sut.items.contains(.inbox))
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: Message.Location.trash.rawValue,
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssert(sut.items.contains(.inbox))
    }

    func testShouldNotIncludeSpamMoveToInboxIfLabelIdIsOtherThanSpam() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: "",
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssertFalse(sut.items.contains(.spamMoveToInbox))
    }

    func testShouldIncludeSpamMoveToInboxIfLabelIdIsSpam() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: Message.Location.spam.rawValue,
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssert(sut.items.contains(.spamMoveToInbox))
    }

    func testShouldIncludeDeleteIfDraftSentSpamTrash() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: Message.Location.draft.rawValue,
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssert(sut.items.contains(.delete))
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: Message.Location.sent.rawValue,
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssert(sut.items.contains(.delete))
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: Message.Location.spam.rawValue,
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssert(sut.items.contains(.delete))
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: Message.Location.trash.rawValue,
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssert(sut.items.contains(.delete))
    }

    func testShouldIncludeSpamIfOtherThanDraftSentSpamTrash() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: "",
                                              includeStarring: Bool.random(),
                                              isStarred: Bool.random(),
                                              isBodyDecryptable: Bool.random(),
                                              hasMoreThanOneRecipient: Bool.random())
        XCTAssert(sut.items.contains(.spam))
    }
}
