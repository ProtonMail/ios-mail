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

@testable import ProtonMail
import XCTest

class MailBoxSwipeActionHelperTests: XCTestCase {
    var sut: MailBoxSwipeActionHelper!
    override func setUp() {
        super.setUp()
        sut = MailBoxSwipeActionHelper()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testCheckIsSwipeActionValidInArchiveFolder() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .archive, action: .archive))

        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .archive, action: .star))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .archive, action: .unstar))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .archive, action: .spam))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .archive, action: .unread))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .archive, action: .read))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .archive, action: .labelAs))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .archive, action: .moveTo))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .archive, action: .trash))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .archive, action: .none))
    }

    func testCheckIsSwipeActionValidInStarFolder() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .starred, action: .star))

        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .starred, action: .archive))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .starred, action: .unstar))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .starred, action: .spam))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .starred, action: .unread))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .starred, action: .read))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .starred, action: .labelAs))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .starred, action: .moveTo))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .starred, action: .trash))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .starred, action: .none))
    }

    func testCheckIsSwipeActionValidInSpamFolder() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .spam, action: .spam))

        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .spam, action: .archive))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .spam, action: .star))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .spam, action: .unstar))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .spam, action: .unread))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .spam, action: .read))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .spam, action: .labelAs))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .spam, action: .moveTo))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .spam, action: .trash))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .spam, action: .none))
    }

    func testCheckIsSwipeActionValidInDraftFolder() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .draft, action: .spam))
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .draft, action: .archive))

        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .draft, action: .star))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .draft, action: .unstar))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .draft, action: .unread))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .draft, action: .read))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .draft, action: .labelAs))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .draft, action: .moveTo))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .draft, action: .trash))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .draft, action: .none))
    }

    func testCheckIsSwipeActionValidInSentFolder() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .sent, action: .spam))

        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .sent, action: .archive))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .sent, action: .star))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .sent, action: .unstar))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .sent, action: .unread))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .sent, action: .read))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .sent, action: .labelAs))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .sent, action: .moveTo))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .sent, action: .trash))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .sent, action: .none))
    }

    func testCheckIsSwipeActionValidInTrashFolder() {
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .trash, action: .spam))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .trash, action: .archive))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .trash, action: .star))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .trash, action: .unstar))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .trash, action: .unread))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .trash, action: .read))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .trash, action: .labelAs))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .trash, action: .moveTo))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .trash, action: .trash))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .trash, action: .none))
    }

    func testCheckIsSwipeActionValidInAllMailFolder() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .allmail, action: .spam))
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .allmail, action: .archive))
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .allmail, action: .star))
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .allmail, action: .unstar))
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .allmail, action: .unread))
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .allmail, action: .read))
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .allmail, action: .labelAs))
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .allmail, action: .moveTo))
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .allmail, action: .trash))
        XCTAssertFalse(sut.checkIsSwipeActionValidOn(location: .allmail, action: .none))
    }

    func testCheckIsSwipeActionValidInInboxFolder() {
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .inbox, action: .spam))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .inbox, action: .archive))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .inbox, action: .star))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .inbox, action: .unstar))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .inbox, action: .unread))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .inbox, action: .read))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .inbox, action: .labelAs))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .inbox, action: .moveTo))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .inbox, action: .trash))
        XCTAssertTrue(sut.checkIsSwipeActionValidOn(location: .inbox, action: .none))
    }

    func testCheckIsSwipeActionValidOnMessage_actionIsNone_getFalse() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                            isUnread: Bool.random(),
                                                            isStar: Bool.random(),
                                                            isInTrash: Bool.random(),
                                                            isInArchive: Bool.random(),
                                                            isInSent: Bool.random(),
                                                            isInSpam: Bool.random(),
                                                            action: .none))
    }

    func testCheckIsSwipeActionValidOnMessage_actionIsUnread() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                            isUnread: true,
                                                            isStar: Bool.random(),
                                                            isInTrash: Bool.random(),
                                                            isInArchive: Bool.random(),
                                                            isInSent: Bool.random(),
                                                            isInSpam: Bool.random(),
                                                            action: .unread))

        XCTAssertTrue(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                           isUnread: false,
                                                           isStar: Bool.random(),
                                                           isInTrash: Bool.random(),
                                                           isInArchive: Bool.random(),
                                                           isInSent: Bool.random(),
                                                           isInSpam: Bool.random(),
                                                           action: .unread))
    }

    func testCheckIsSwipeActionValidOnMessage_actionIsRead() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                            isUnread: false,
                                                            isStar: Bool.random(),
                                                            isInTrash: Bool.random(),
                                                            isInArchive: Bool.random(),
                                                            isInSent: Bool.random(),
                                                            isInSpam: Bool.random(),
                                                            action: .read))

        XCTAssertTrue(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                           isUnread: true,
                                                           isStar: Bool.random(),
                                                           isInTrash: Bool.random(),
                                                           isInArchive: Bool.random(),
                                                           isInSent: Bool.random(),
                                                           isInSpam: Bool.random(),
                                                           action: .read))
    }

    func testCheckIsSwipeActionValidOnMessage_actionIsStar() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                            isUnread: Bool.random(),
                                                            isStar: true,
                                                            isInTrash: Bool.random(),
                                                            isInArchive: Bool.random(),
                                                            isInSent: Bool.random(),
                                                            isInSpam: Bool.random(),
                                                            action: .star))

        XCTAssertTrue(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                           isUnread: Bool.random(),
                                                           isStar: false,
                                                           isInTrash: Bool.random(),
                                                           isInArchive: Bool.random(),
                                                           isInSent: Bool.random(),
                                                           isInSpam: Bool.random(),
                                                           action: .star))
    }

    func testCheckIsSwipeActionValidOnMessage_actionIsUnStar() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                            isUnread: Bool.random(),
                                                            isStar: false,
                                                            isInTrash: Bool.random(),
                                                            isInArchive: Bool.random(),
                                                            isInSent: Bool.random(),
                                                            isInSpam: Bool.random(),
                                                            action: .unstar))

        XCTAssertTrue(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                           isUnread: Bool.random(),
                                                           isStar: true,
                                                           isInTrash: Bool.random(),
                                                           isInArchive: Bool.random(),
                                                           isInSent: Bool.random(),
                                                           isInSpam: Bool.random(),
                                                           action: .unstar))
    }

    func testCheckIsSwipeActionValidOnMessage_actionIsTrash() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                            isUnread: Bool.random(),
                                                            isStar: Bool.random(),
                                                            isInTrash: true,
                                                            isInArchive: Bool.random(),
                                                            isInSent: Bool.random(),
                                                            isInSpam: Bool.random(),
                                                            action: .trash))

        XCTAssertTrue(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                           isUnread: Bool.random(),
                                                           isStar: Bool.random(),
                                                           isInTrash: false,
                                                           isInArchive: Bool.random(),
                                                           isInSent: Bool.random(),
                                                           isInSpam: Bool.random(),
                                                           action: .trash))
    }

    func testCheckIsSwipeActionValidOnMessage_actionIsLabelAs_getTrue() {
        XCTAssertTrue(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                           isUnread: Bool.random(),
                                                           isStar: Bool.random(),
                                                           isInTrash: Bool.random(),
                                                           isInArchive: Bool.random(),
                                                           isInSent: Bool.random(),
                                                           isInSpam: Bool.random(),
                                                           action: .labelAs))
    }

    func testCheckIsSwipeActionValidOnMessage_actionIsMoveTo_getTrue() {
        XCTAssertTrue(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                           isUnread: Bool.random(),
                                                           isStar: Bool.random(),
                                                           isInTrash: Bool.random(),
                                                           isInArchive: Bool.random(),
                                                           isInSent: Bool.random(),
                                                           isInSpam: Bool.random(),
                                                           action: .moveTo))
    }

    func testCheckIsSwipeActionValidOnMessage_actionIsArchive() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                            isUnread: Bool.random(),
                                                            isStar: Bool.random(),
                                                            isInTrash: Bool.random(),
                                                            isInArchive: true,
                                                            isInSent: Bool.random(),
                                                            isInSpam: Bool.random(),
                                                            action: .archive))

        XCTAssertTrue(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                           isUnread: Bool.random(),
                                                           isStar: Bool.random(),
                                                           isInTrash: Bool.random(),
                                                           isInArchive: false,
                                                           isInSent: Bool.random(),
                                                           isInSpam: Bool.random(),
                                                           action: .archive))
    }

    func testCheckIsSwipeActionValidOnMessage_actionIsSpam() {
        XCTAssertTrue(sut.checkIsSwipeActionValidOnMessage(isDraft: false,
                                                           isUnread: Bool.random(),
                                                           isStar: Bool.random(),
                                                           isInTrash: Bool.random(),
                                                           isInArchive: Bool.random(),
                                                           isInSent: false,
                                                           isInSpam: false,
                                                           action: .spam))

        XCTAssertFalse(sut.checkIsSwipeActionValidOnMessage(isDraft: true,
                                                            isUnread: Bool.random(),
                                                            isStar: Bool.random(),
                                                            isInTrash: Bool.random(),
                                                            isInArchive: Bool.random(),
                                                            isInSent: Bool.random(),
                                                            isInSpam: Bool.random(),
                                                            action: .spam))

        XCTAssertFalse(sut.checkIsSwipeActionValidOnMessage(isDraft: Bool.random(),
                                                            isUnread: Bool.random(),
                                                            isStar: Bool.random(),
                                                            isInTrash: Bool.random(),
                                                            isInArchive: Bool.random(),
                                                            isInSent: Bool.random(),
                                                            isInSpam: true,
                                                            action: .spam))

        XCTAssertFalse(sut.checkIsSwipeActionValidOnMessage(isDraft: true,
                                                            isUnread: Bool.random(),
                                                            isStar: Bool.random(),
                                                            isInTrash: Bool.random(),
                                                            isInArchive: Bool.random(),
                                                            isInSent: true,
                                                            isInSpam: Bool.random(),
                                                            action: .spam))
    }

    func testCheckIsSwipeActionValidOnConversation_actionIsNone_getFalse() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                 isStar: Bool.random(),
                                                                 isInArchive: Bool.random(),
                                                                 isInSpam: Bool.random(),
                                                                 isInSent: Bool.random(),
                                                                 action: .none))
    }

    func testCheckIsSwipeActionValidOnConversation_actionIsUnread() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnConversation(isUnread: true,
                                                                 isStar: Bool.random(),
                                                                 isInArchive: Bool.random(),
                                                                 isInSpam: Bool.random(),
                                                                 isInSent: Bool.random(),
                                                                 action: .unread))

        XCTAssertTrue(sut.checkIsSwipeActionValidOnConversation(isUnread: false,
                                                                isStar: Bool.random(),
                                                                isInArchive: Bool.random(),
                                                                isInSpam: Bool.random(),
                                                                isInSent: Bool.random(),
                                                                action: .unread))
    }

    func testCheckIsSwipeActionValidOnConversation_actionIsRead() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnConversation(isUnread: false,
                                                                 isStar: Bool.random(),
                                                                 isInArchive: Bool.random(),
                                                                 isInSpam: Bool.random(),
                                                                 isInSent: Bool.random(),
                                                                 action: .read))

        XCTAssertTrue(sut.checkIsSwipeActionValidOnConversation(isUnread: true,
                                                                isStar: Bool.random(),
                                                                isInArchive: Bool.random(),
                                                                isInSpam: Bool.random(),
                                                                isInSent: Bool.random(),
                                                                action: .read))
    }

    func testCheckIsSwipeActionValidOnConversation_actionIsStar() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                 isStar: true,
                                                                 isInArchive: Bool.random(),
                                                                 isInSpam: Bool.random(),
                                                                 isInSent: Bool.random(),
                                                                 action: .star))

        XCTAssertTrue(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                isStar: false,
                                                                isInArchive: Bool.random(),
                                                                isInSpam: Bool.random(),
                                                                isInSent: Bool.random(),
                                                                action: .star))
    }

    func testCheckIsSwipeActionValidOnConversation_actionIsUnstar() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                 isStar: false,
                                                                 isInArchive: Bool.random(),
                                                                 isInSpam: Bool.random(),
                                                                 isInSent: Bool.random(),
                                                                 action: .unstar))

        XCTAssertTrue(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                isStar: true,
                                                                isInArchive: Bool.random(),
                                                                isInSpam: Bool.random(),
                                                                isInSent: Bool.random(),
                                                                action: .unstar))
    }

    func testCheckIsSwipeActionValidOnConversation_actionIsTrash_getTrue() {
        XCTAssertTrue(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                isStar: Bool.random(),
                                                                isInArchive: Bool.random(),
                                                                isInSpam: Bool.random(),
                                                                isInSent: Bool.random(),
                                                                action: .trash))
    }

    func testCheckIsSwipeActionValidOnConversation_actionIsLabelAs_getTrue() {
        XCTAssertTrue(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                isStar: Bool.random(),
                                                                isInArchive: Bool.random(),
                                                                isInSpam: Bool.random(),
                                                                isInSent: Bool.random(),
                                                                action: .labelAs))
    }

    func testCheckIsSwipeActionValidOnConversation_actionIsMoveTo_getTrue() {
        XCTAssertTrue(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                isStar: Bool.random(),
                                                                isInArchive: Bool.random(),
                                                                isInSpam: Bool.random(),
                                                                isInSent: Bool.random(),
                                                                action: .moveTo))
    }

    func testCheckIsSwipeActionValidOnConversation_actionIsArchive() {
        XCTAssertFalse(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                 isStar: Bool.random(),
                                                                 isInArchive: true,
                                                                 isInSpam: Bool.random(),
                                                                 isInSent: Bool.random(),
                                                                 action: .archive))

        XCTAssertTrue(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                isStar: Bool.random(),
                                                                isInArchive: false,
                                                                isInSpam: Bool.random(),
                                                                isInSent: Bool.random(),
                                                                action: .archive))
    }

    func testCheckIsSwipeActionValidOnConversation_actionIsSpam() {
        XCTAssertTrue(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                isStar: Bool.random(),
                                                                isInArchive: Bool.random(),
                                                                isInSpam: false,
                                                                isInSent: false,
                                                                action: .spam))

        XCTAssertFalse(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                 isStar: Bool.random(),
                                                                 isInArchive: Bool.random(),
                                                                 isInSpam: true,
                                                                 isInSent: Bool.random(),
                                                                 action: .spam))

        XCTAssertFalse(sut.checkIsSwipeActionValidOnConversation(isUnread: Bool.random(),
                                                                 isStar: Bool.random(),
                                                                 isInArchive: Bool.random(),
                                                                 isInSpam: Bool.random(),
                                                                 isInSent: true,
                                                                 action: .spam))
    }
}
