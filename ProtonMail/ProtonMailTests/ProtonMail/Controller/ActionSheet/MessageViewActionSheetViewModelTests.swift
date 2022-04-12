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

class MessageViewActionSheetViewModelTests: XCTestCase {

    var sut: MessageViewActionSheetViewModel!
    let testTitle = "test title"
    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testActionSheet_openInInbox() {
        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.inbox.rawValue,
                                              includeStarring: true,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false)
        XCTAssertEqual(sut.title, testTitle)
        let expectedOptions: [MessageViewActionSheetAction] = [.reply,
                                                               .forward,
                                                               .markUnread,
                                                               .labelAs,
                                                               .star,
                                                               .trash,
                                                               .archive,
                                                               .spam,
                                                               .moveTo,
                                                               .print,
                                                               .viewHeaders,
                                                               .viewHTML,
                                                               .reportPhishing]
        XCTAssertEqual(sut.items, expectedOptions)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.inbox.rawValue,
                                              includeStarring: true,
                                              isStarred: true,
                                              isBodyDecryptable: true,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false)
        let expectedOptions2: [MessageViewActionSheetAction] = [.reply,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .unstar,
                                                                .trash,
                                                                .archive,
                                                                .spam,
                                                                .moveTo,
                                                                .print,
                                                                .viewHeaders,
                                                                .viewHTML,
                                                                .reportPhishing]
        // check isStarred
        XCTAssertEqual(sut.items, expectedOptions2)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.inbox.rawValue,
                                              includeStarring: true,
                                              isStarred: true,
                                              isBodyDecryptable: false,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false)
        let expectedOptions3: [MessageViewActionSheetAction] = [.reply,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .unstar,
                                                                .trash,
                                                                .archive,
                                                                .spam,
                                                                .moveTo,
                                                                .print,
                                                                .viewHeaders,
                                                                .reportPhishing]
        // check isBodyDecryptable
        XCTAssertEqual(sut.items, expectedOptions3)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.inbox.rawValue,
                                              includeStarring: false,
                                              isStarred: true,
                                              isBodyDecryptable: false,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false)
        let expectedOptions4: [MessageViewActionSheetAction] = [.reply,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .trash,
                                                                .archive,
                                                                .spam,
                                                                .moveTo,
                                                                .print,
                                                                .viewHeaders,
                                                                .reportPhishing]
        // check includeStarring
        XCTAssertEqual(sut.items, expectedOptions4)
    }

    func testActionSheet_openInTrash() {
        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.trash.rawValue,
                                              includeStarring: true,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false)
        XCTAssertEqual(sut.title, testTitle)
        let expectedOptions: [MessageViewActionSheetAction] = [.reply,
                                                               .forward,
                                                               .markUnread,
                                                               .labelAs,
                                                               .star,
                                                               .archive,
                                                               .inbox,
                                                               .delete,
                                                               .moveTo,
                                                               .print,
                                                               .viewHeaders,
                                                               .viewHTML,
                                                               .reportPhishing]
        XCTAssertEqual(sut.items, expectedOptions)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.trash.rawValue,
                                              includeStarring: false,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false)
        let expectedOptions2: [MessageViewActionSheetAction] = [.reply,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .archive,
                                                                .inbox,
                                                                .delete,
                                                                .moveTo,
                                                                .print,
                                                                .viewHeaders,
                                                                .viewHTML,
                                                                .reportPhishing]
        // check inCludeStarring
        XCTAssertEqual(sut.items, expectedOptions2)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.trash.rawValue,
                                              includeStarring: true,
                                              isStarred: true,
                                              isBodyDecryptable: true,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false)
        let expectedOptions3: [MessageViewActionSheetAction] = [.reply,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .unstar,
                                                                .archive,
                                                                .inbox,
                                                                .delete,
                                                                .moveTo,
                                                                .print,
                                                                .viewHeaders,
                                                                .viewHTML,
                                                                .reportPhishing]
        // check isStarred
        XCTAssertEqual(sut.items, expectedOptions3)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.trash.rawValue,
                                              includeStarring: true,
                                              isStarred: true,
                                              isBodyDecryptable: false,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false)
        let expectedOptions4: [MessageViewActionSheetAction] = [.reply,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .unstar,
                                                                .archive,
                                                                .inbox,
                                                                .delete,
                                                                .moveTo,
                                                                .print,
                                                                .viewHeaders,
                                                                .reportPhishing]
        // check isBodyDecryptable
        XCTAssertEqual(sut.items, expectedOptions4)
    }

    func testActionSheet_openInSpam() {
        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.spam.rawValue,
                                              includeStarring: true,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false)
        XCTAssertEqual(sut.title, testTitle)
        let expectedOptions: [MessageViewActionSheetAction] = [.reply,
                                                               .forward,
                                                               .markUnread,
                                                               .labelAs,
                                                               .star,
                                                               .trash,
                                                               .spamMoveToInbox,
                                                               .delete,
                                                               .moveTo,
                                                               .print,
                                                               .viewHeaders,
                                                               .viewHTML,
                                                               .reportPhishing]
        XCTAssertEqual(sut.items, expectedOptions)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.spam.rawValue,
                                              includeStarring: false,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false)
        let expectedOptions2: [MessageViewActionSheetAction] = [.reply,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .trash,
                                                                .spamMoveToInbox,
                                                                .delete,
                                                                .moveTo,
                                                                .print,
                                                                .viewHeaders,
                                                                .viewHTML,
                                                                .reportPhishing]
        // check inCludeStarring
        XCTAssertEqual(sut.items, expectedOptions2)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.spam.rawValue,
                                              includeStarring: true,
                                              isStarred: true,
                                              isBodyDecryptable: true,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false)
        let expectedOptions3: [MessageViewActionSheetAction] = [.reply,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .unstar,
                                                                .trash,
                                                                .spamMoveToInbox,
                                                                .delete,
                                                                .moveTo,
                                                                .print,
                                                                .viewHeaders,
                                                                .viewHTML,
                                                                .reportPhishing]
        // check isStarred
        XCTAssertEqual(sut.items, expectedOptions3)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.spam.rawValue,
                                              includeStarring: true,
                                              isStarred: true,
                                              isBodyDecryptable: false,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false)
        let expectedOptions4: [MessageViewActionSheetAction] = [.reply,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .unstar,
                                                                .trash,
                                                                .spamMoveToInbox,
                                                                .delete,
                                                                .moveTo,
                                                                .print,
                                                                .viewHeaders,
                                                                .reportPhishing]
        // check isBodyDecryptable
        XCTAssertEqual(sut.items, expectedOptions4)
    }

    func testActionSheet_withDarkModeEnable() {
        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.inbox.rawValue,
                                              includeStarring: true,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .dark,
                                              shouldShowRenderModeOption: true)
        XCTAssertEqual(sut.title, testTitle)
        let expectedOptions: [MessageViewActionSheetAction] = [.reply,
                                                               .forward,
                                                               .markUnread,
                                                               .labelAs,
                                                               .star,
                                                               .viewInLightMode,
                                                               .trash,
                                                               .archive,
                                                               .spam,
                                                               .moveTo,
                                                               .print,
                                                               .viewHeaders,
                                                               .viewHTML,
                                                               .reportPhishing]
        XCTAssertEqual(sut.items, expectedOptions)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.inbox.rawValue,
                                              includeStarring: true,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              hasMoreThanOneRecipient: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: true)
        XCTAssertEqual(sut.title, testTitle)
        let expectedOptions2: [MessageViewActionSheetAction] = [.reply,
                                                               .forward,
                                                               .markUnread,
                                                               .labelAs,
                                                               .star,
                                                               .trash,
                                                               .archive,
                                                               .spam,
                                                               .moveTo,
                                                               .print,
                                                               .viewHeaders,
                                                               .viewHTML,
                                                               .reportPhishing]
        XCTAssertEqual(sut.items, expectedOptions2)
    }
}
