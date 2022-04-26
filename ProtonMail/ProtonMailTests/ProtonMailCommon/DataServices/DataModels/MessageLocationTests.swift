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

class MessageLocationTests: XCTestCase {

    func testGetLicalizedTitle() {
        XCTAssertEqual(Message.Location.inbox.localizedTitle,
                       LocalString._locations_inbox_title)
        XCTAssertEqual(Message.Location.starred.localizedTitle,
                       LocalString._locations_starred_title)
        XCTAssertEqual(Message.Location.draft.localizedTitle,
                       LocalString._locations_draft_title)
        XCTAssertEqual(Message.Location.sent.localizedTitle,
                       LocalString._locations_outbox_title)
        XCTAssertEqual(Message.Location.trash.localizedTitle,
                       LocalString._locations_trash_title)
        XCTAssertEqual(Message.Location.archive.localizedTitle,
                       LocalString._locations_archive_title)
        XCTAssertEqual(Message.Location.spam.localizedTitle,
                       LocalString._locations_spam_title)
        XCTAssertEqual(Message.Location.allmail.localizedTitle,
                       LocalString._locations_all_mail_title)
    }

    func testInit() {
        let labelID = LabelID("0")
        let sut = Message.Location("0")
        XCTAssertEqual(sut?.rawValue, labelID.rawValue)
    }

    func testGetLabelID() {
        let allCases = Message.Location.allCases
        allCases.forEach { location in
            XCTAssertEqual(location.labelID, LabelID(location.rawValue))
        }
    }
}
