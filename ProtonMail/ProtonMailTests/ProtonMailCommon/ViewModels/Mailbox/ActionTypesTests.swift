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

class ActionTypesTests: XCTestCase {

    var sut: MailboxViewModel.ActionTypes!

    func testGetNameFromActions() {
        XCTAssertEqual(MailboxViewModel.ActionTypes.trash.name,
                       LocalString._action_bar_title_trash)
        XCTAssertEqual(MailboxViewModel.ActionTypes.delete.name,
                       LocalString._action_bar_title_delete)
        XCTAssertEqual(MailboxViewModel.ActionTypes.moveTo.name,
                       LocalString._action_bar_title_moveTo)
        XCTAssertEqual(MailboxViewModel.ActionTypes.more.name,
                       LocalString._action_bar_title_more)
        XCTAssertEqual(MailboxViewModel.ActionTypes.labelAs.name,
                       LocalString._action_bar_title_labelAs)
        XCTAssertEqual(MailboxViewModel.ActionTypes.reply.name,
                       LocalString._action_bar_title_reply)
        XCTAssertEqual(MailboxViewModel.ActionTypes.replyAll.name,
                       LocalString._action_bar_title_replyAll)
        XCTAssertEqual(MailboxViewModel.ActionTypes.readUnread.name,
                       "")
    }

    func testGetIconImageFromActions() {
        XCTAssertEqual(MailboxViewModel.ActionTypes.delete.iconImage,
                       Asset.actionBarDelete.image)
        XCTAssertEqual(MailboxViewModel.ActionTypes.trash.iconImage,
                       Asset.actionBarTrash.image)
        XCTAssertEqual(MailboxViewModel.ActionTypes.moveTo.iconImage,
                       Asset.actionBarMoveTo.image)
        XCTAssertEqual(MailboxViewModel.ActionTypes.more.iconImage,
                       Asset.actionBarMore.image)
        XCTAssertEqual(MailboxViewModel.ActionTypes.labelAs.iconImage,
                       Asset.actionBarLabel.image)
        XCTAssertEqual(MailboxViewModel.ActionTypes.reply.iconImage,
                       Asset.actionBarReply.image)
        XCTAssertEqual(MailboxViewModel.ActionTypes.replyAll.iconImage,
                       Asset.actionBarReplyAll.image)
        XCTAssertEqual(MailboxViewModel.ActionTypes.readUnread.iconImage,
                       Asset.actionBarReadUnread.image)
    }
}
