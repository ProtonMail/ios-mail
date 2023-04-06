// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

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
                                              labelID: Message.Location.inbox.labelID,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false,
                                              isScheduledSend: false)
        XCTAssertEqual(sut.title, testTitle)
        let expectedOptions: [MessageViewActionSheetAction] = [.reply,
                                                               .replyAll,
                                                               .forward,
                                                               .markUnread,
                                                               .labelAs,
                                                               .star,
                                                               .trash,
                                                               .archive,
                                                               .spam,
                                                               .moveTo,
                                                               .saveAsPDF,
                                                               .print,
                                                               .toolbarCustomization,
                                                               .viewHeaders,
                                                               .viewHTML,
                                                               .reportPhishing]
        XCTAssertEqual(sut.items, expectedOptions)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.inbox.labelID,
                                              isStarred: true,
                                              isBodyDecryptable: true,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false,
                                              isScheduledSend: false)
        let expectedOptions2: [MessageViewActionSheetAction] = [.reply,
                                                                .replyAll,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .unstar,
                                                                .trash,
                                                                .archive,
                                                                .spam,
                                                                .moveTo,
                                                                .saveAsPDF,
                                                                .print,
                                                                .toolbarCustomization,
                                                                .viewHeaders,
                                                                .viewHTML,
                                                                .reportPhishing]
        // check isStarred
        XCTAssertEqual(sut.items, expectedOptions2)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.inbox.labelID,
                                              isStarred: true,
                                              isBodyDecryptable: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false,
                                              isScheduledSend: false)
        let expectedOptions3: [MessageViewActionSheetAction] = [.reply,
                                                                .replyAll,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .unstar,
                                                                .trash,
                                                                .archive,
                                                                .spam,
                                                                .moveTo,
                                                                .saveAsPDF,
                                                                .print,
                                                                .toolbarCustomization,
                                                                .viewHeaders,
                                                                .reportPhishing]
        // check isBodyDecryptable
        XCTAssertEqual(sut.items, expectedOptions3)
    }

    func testActionSheet_openInTrash() {
        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.trash.labelID,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false,
                                              isScheduledSend: false)
        XCTAssertEqual(sut.title, testTitle)
        let expectedOptions: [MessageViewActionSheetAction] = [.reply,
                                                               .replyAll,
                                                               .forward,
                                                               .markUnread,
                                                               .labelAs,
                                                               .star,
                                                               .archive,
                                                               .inbox,
                                                               .delete,
                                                               .moveTo,
                                                               .saveAsPDF,
                                                               .print,
                                                               .toolbarCustomization,
                                                               .viewHeaders,
                                                               .viewHTML,
                                                               .reportPhishing]
        XCTAssertEqual(sut.items, expectedOptions)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.trash.labelID,
                                              isStarred: true,
                                              isBodyDecryptable: true,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false,
                                              isScheduledSend: false)
        let expectedOptions3: [MessageViewActionSheetAction] = [.reply,
                                                                .replyAll,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .unstar,
                                                                .archive,
                                                                .inbox,
                                                                .delete,
                                                                .moveTo,
                                                                .saveAsPDF,
                                                                .print,
                                                                .toolbarCustomization,
                                                                .viewHeaders,
                                                                .viewHTML,
                                                                .reportPhishing]
        // check isStarred
        XCTAssertEqual(sut.items, expectedOptions3)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.trash.labelID,
                                              isStarred: true,
                                              isBodyDecryptable: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false,
                                              isScheduledSend: false)
        let expectedOptions4: [MessageViewActionSheetAction] = [.reply,
                                                                .replyAll,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .unstar,
                                                                .archive,
                                                                .inbox,
                                                                .delete,
                                                                .moveTo,
                                                                .saveAsPDF,
                                                                .print,
                                                                .toolbarCustomization,
                                                                .viewHeaders,
                                                                .reportPhishing]
        // check isBodyDecryptable
        XCTAssertEqual(sut.items, expectedOptions4)
    }

    func testActionSheet_openInSpam() {
        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.spam.labelID,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false,
                                              isScheduledSend: false)
        XCTAssertEqual(sut.title, testTitle)
        let expectedOptions: [MessageViewActionSheetAction] = [.reply,
                                                               .replyAll,
                                                               .forward,
                                                               .markUnread,
                                                               .labelAs,
                                                               .star,
                                                               .trash,
                                                               .spamMoveToInbox,
                                                               .delete,
                                                               .moveTo,
                                                               .saveAsPDF,
                                                               .print,
                                                               .toolbarCustomization,
                                                               .viewHeaders,
                                                               .viewHTML,
                                                               .reportPhishing]
        XCTAssertEqual(sut.items, expectedOptions)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.spam.labelID,
                                              isStarred: true,
                                              isBodyDecryptable: true,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false,
                                              isScheduledSend: false)
        let expectedOptions3: [MessageViewActionSheetAction] = [.reply,
                                                                .replyAll,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .unstar,
                                                                .trash,
                                                                .spamMoveToInbox,
                                                                .delete,
                                                                .moveTo,
                                                                .saveAsPDF,
                                                                .print,
                                                                .toolbarCustomization,
                                                                .viewHeaders,
                                                                .viewHTML,
                                                                .reportPhishing]
        // check isStarred
        XCTAssertEqual(sut.items, expectedOptions3)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.spam.labelID,
                                              isStarred: true,
                                              isBodyDecryptable: false,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false,
                                              isScheduledSend: false)
        let expectedOptions4: [MessageViewActionSheetAction] = [.reply,
                                                                .replyAll,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .unstar,
                                                                .trash,
                                                                .spamMoveToInbox,
                                                                .delete,
                                                                .moveTo,
                                                                .saveAsPDF,
                                                                .print,
                                                                .toolbarCustomization,
                                                                .viewHeaders,
                                                                .reportPhishing]
        // check isBodyDecryptable
        XCTAssertEqual(sut.items, expectedOptions4)
    }

    func testActionSheet_withDarkModeEnable() {
        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.inbox.labelID,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              messageRenderStyle: .dark,
                                              shouldShowRenderModeOption: true,
                                              isScheduledSend: false)
        XCTAssertEqual(sut.title, testTitle)
        let expectedOptions: [MessageViewActionSheetAction] = [.reply,
                                                               .replyAll,
                                                               .forward,
                                                               .markUnread,
                                                               .labelAs,
                                                               .star,
                                                               .viewInLightMode,
                                                               .trash,
                                                               .archive,
                                                               .spam,
                                                               .moveTo,
                                                               .saveAsPDF,
                                                               .print,
                                                               .toolbarCustomization,
                                                               .viewHeaders,
                                                               .viewHTML,
                                                               .reportPhishing]
        XCTAssertEqual(sut.items, expectedOptions)

        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.inbox.labelID,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: true,
                                              isScheduledSend: false)
        XCTAssertEqual(sut.title, testTitle)
        let expectedOptions2: [MessageViewActionSheetAction] = [.reply,
                                                                .replyAll,
                                                                .forward,
                                                                .markUnread,
                                                                .labelAs,
                                                                .star,
                                                                .viewInDarkMode,
                                                                .trash,
                                                                .archive,
                                                                .spam,
                                                                .moveTo,
                                                                .saveAsPDF,
                                                                .print,
                                                                .toolbarCustomization,
                                                                .viewHeaders,
                                                                .viewHTML,
                                                                .reportPhishing]
        XCTAssertEqual(sut.items, expectedOptions2)
    }

    func testActionSheet_inScheduledLocation_withSingleMessageMode() {
        sut = MessageViewActionSheetViewModel(title: testTitle,
                                              labelID: Message.Location.scheduled.labelID,
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              messageRenderStyle: .dark,
                                              shouldShowRenderModeOption: true,
                                              isScheduledSend: false)
        XCTAssertEqual(sut.title, testTitle)
        let expectedOptions: [MessageViewActionSheetAction] = [
            .reply,
            .replyAll,
            .forward,
            .markUnread,
            .labelAs,
            .star,
            .viewInLightMode,
            .trash,
            .archive,
            .spam,
            .moveTo,
            .saveAsPDF,
            .print,
            .toolbarCustomization,
            .viewHeaders,
            .viewHTML,
            .reportPhishing
        ]
        XCTAssertEqual(sut.items, expectedOptions)
    }

    func testShouldProperlySetTitle() {
        let aTitle = String.randomString(5)
        sut = makeSUT(title: aTitle)
        XCTAssertEqual(sut.title, aTitle)
    }

    func testShouldAlwaysIncludeCommonItems() {
        sut = MessageViewActionSheetViewModel(title: "",
                                              labelID: "",
                                              isStarred: false,
                                              isBodyDecryptable: true,
                                              messageRenderStyle: .lightOnly,
                                              shouldShowRenderModeOption: false,
                                              isScheduledSend: false)

        let expectedOptions: [MessageViewActionSheetAction] = [
            .reply,
            .replyAll,
            .forward,
            .markUnread,
            .labelAs,
            .star,
            .trash,
            .archive,
            .spam,
            .moveTo,
            .saveAsPDF,
            .print,
            .toolbarCustomization,
            .viewHeaders,
            .viewHTML,
            .reportPhishing
        ]
        XCTAssertEqual(sut.items, expectedOptions)
    }

    // MARK: starring

    func testShouldIncludeStarringOnlyWhenIncludeStarringIsTrue() {
        sut = makeSUT(isStarred: false)
        XCTAssert(sut.items.contains(.star))

        sut = makeSUT(isStarred: true)
        XCTAssert(sut.items.contains(.unstar))
    }

    // MARK: LabelID

    func testShouldIncludeTrashIfLabelIdIsOtherThanTrash() {
        sut = makeSUT()
        XCTAssert(sut.items.contains(.trash))
    }

    func testShouldNotIncludeTrashIfLabelIdIsTrash() {
        sut = makeSUT(labelID: Message.Location.trash.labelID)
        XCTAssertFalse(sut.items.contains(.trash))
    }

    func testShouldNotIncludeArchiveIfLabelIdIsArchiveOrSpam() {
        sut = makeSUT(labelID: Message.Location.archive.labelID)
        XCTAssertFalse(sut.items.contains(.archive))

        sut = makeSUT(labelID: Message.Location.spam.labelID)
        XCTAssertFalse(sut.items.contains(.archive))
    }

    func testShouldIncludeArchiveIfLabelIdIsOtherThanArchiveOrSpam() {
        sut = makeSUT()
        XCTAssert(sut.items.contains(.archive))
    }

    func testShouldNotIncludeInboxIfLabelIdIsOtherThanArchiveOrTrash() {
        sut = makeSUT()
        XCTAssertFalse(sut.items.contains(.inbox))
    }

    func testShouldIncludeInboxIfLabelIdIsArchiveOrTrash() {
        sut = makeSUT(labelID: Message.Location.archive.labelID)
        XCTAssert(sut.items.contains(.inbox))
        sut = makeSUT(labelID: Message.Location.trash.labelID)
        XCTAssert(sut.items.contains(.inbox))
    }

    func testShouldNotIncludeSpamMoveToInboxIfLabelIdIsOtherThanSpam() {
        sut = makeSUT()
        XCTAssertFalse(sut.items.contains(.spamMoveToInbox))
    }

    func testShouldIncludeSpamMoveToInboxIfLabelIdIsSpam() {
        sut = makeSUT(labelID: Message.Location.spam.labelID)
        XCTAssert(sut.items.contains(.spamMoveToInbox))
    }

    func testShouldIncludeDeleteIfDraftSentSpamTrash() {
        sut = makeSUT(labelID: Message.Location.draft.labelID)
        XCTAssert(sut.items.contains(.delete))

        sut = makeSUT(labelID: Message.Location.sent.labelID)
        XCTAssert(sut.items.contains(.delete))

        sut = makeSUT(labelID: Message.Location.spam.labelID)
        XCTAssert(sut.items.contains(.delete))

        sut = makeSUT(labelID: Message.Location.trash.labelID)
        XCTAssert(sut.items.contains(.delete))
    }

    func testShouldIncludeSpamIfOtherThanDraftSentSpamTrash() {
        sut = makeSUT()
        XCTAssert(sut.items.contains(.spam))
    }

    func testMessageIsScheduleSend_Reply_ReplyAll_Forward_willNotBeSeen() {
        sut = makeSUT(isScheduledSend: true)
        XCTAssertFalse(sut.items.contains(.reply))
        XCTAssertFalse(sut.items.contains(.replyAll))
        XCTAssertFalse(sut.items.contains(.forward))
    }

    private func makeSUT(
        title: String = "",
        labelID: LabelID = "",
        isStarred: Bool = .random(),
        isBodyDecryptable: Bool = .random(),
        messageRenderStyle: MessageRenderStyle = .lightOnly,
        shouldShowRenderModeOption: Bool = .random(),
        isScheduledSend: Bool = .random()
    ) -> MessageViewActionSheetViewModel {
        .init(
            title: title,
            labelID: labelID,
            isStarred: isStarred,
            isBodyDecryptable: isBodyDecryptable,
            messageRenderStyle: messageRenderStyle,
            shouldShowRenderModeOption: shouldShowRenderModeOption,
            isScheduledSend: isScheduledSend
        )
    }
}
