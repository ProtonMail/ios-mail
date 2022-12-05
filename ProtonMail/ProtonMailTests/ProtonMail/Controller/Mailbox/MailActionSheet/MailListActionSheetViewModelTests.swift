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

class MailListActionSheetViewModelTests: XCTestCase {

    var sut: MailListActionSheetViewModel!
    var randomTitle = ""
    override func setUp() {
        super.setUp()
        randomTitle = String.randomString(100)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        randomTitle = .empty
    }

    func testInit_inbox() {
        sut = MailListActionSheetViewModel(labelId: Message.Location.inbox.rawValue,
                                           title: randomTitle)
        XCTAssertEqual(sut.title, randomTitle)
        let expected: [MailListActionSheetItemViewModel] = [
            .starActionViewModel(),
            .unstarActionViewModel(),
            .markUnreadActionViewModel(),
            .markReadActionViewModel(),
            .labelAsActionViewModel(),
            .removeActionViewModel(),
            .moveToArchive(),
            .moveToSpam(),
            .moveToActionViewModel()
        ]
        XCTAssertEqual(sut.items, expected)
    }

    func testInit_scheduled() {
        sut = MailListActionSheetViewModel(labelId: Message.Location.scheduled.rawValue,
                                           title: randomTitle)
        XCTAssertEqual(sut.title, randomTitle)
        let expected: [MailListActionSheetItemViewModel] = [
            .starActionViewModel(),
            .unstarActionViewModel(),
            .markUnreadActionViewModel(),
            .markReadActionViewModel(),
            .labelAsActionViewModel(),
            .removeActionViewModel(),
            .moveToArchive(),
            .moveToActionViewModel()
        ]
        XCTAssertEqual(sut.items, expected)
    }

    func testInit_draft() {
        sut = MailListActionSheetViewModel(labelId: Message.Location.draft.rawValue,
                                           title: randomTitle)
        XCTAssertEqual(sut.title, randomTitle)
        let expected: [MailListActionSheetItemViewModel] = [
            .starActionViewModel(),
            .unstarActionViewModel(),
            .markUnreadActionViewModel(),
            .markReadActionViewModel(),
            .labelAsActionViewModel(),
            .removeActionViewModel(),
            .moveToArchive(),
            .deleteActionViewModel(),
            .moveToActionViewModel()
        ]
        XCTAssertEqual(sut.items, expected)
    }

    func testInit_sent() {
        sut = MailListActionSheetViewModel(labelId: Message.Location.sent.rawValue,
                                           title: randomTitle)
        XCTAssertEqual(sut.title, randomTitle)
        let expected: [MailListActionSheetItemViewModel] = [
            .starActionViewModel(),
            .unstarActionViewModel(),
            .markUnreadActionViewModel(),
            .markReadActionViewModel(),
            .labelAsActionViewModel(),
            .removeActionViewModel(),
            .moveToArchive(),
            .deleteActionViewModel(),
            .moveToActionViewModel()
        ]
        XCTAssertEqual(sut.items, expected)
    }

    func testInit_starred() {
        sut = MailListActionSheetViewModel(labelId: Message.Location.starred.rawValue,
                                           title: randomTitle)
        XCTAssertEqual(sut.title, randomTitle)
        let expected: [MailListActionSheetItemViewModel] = [
            .starActionViewModel(),
            .unstarActionViewModel(),
            .markUnreadActionViewModel(),
            .markReadActionViewModel(),
            .labelAsActionViewModel(),
            .removeActionViewModel(),
            .moveToArchive(),
            .moveToSpam(),
            .moveToActionViewModel()
        ]
        XCTAssertEqual(sut.items, expected)
    }

    func testInit_archive() {
        sut = MailListActionSheetViewModel(labelId: Message.Location.archive.rawValue,
                                           title: randomTitle)
        XCTAssertEqual(sut.title, randomTitle)
        let expected: [MailListActionSheetItemViewModel] = [
            .starActionViewModel(),
            .unstarActionViewModel(),
            .markUnreadActionViewModel(),
            .markReadActionViewModel(),
            .labelAsActionViewModel(),
            .removeActionViewModel(),
            .moveToInboxActionViewModel(),
            .moveToSpam(),
            .moveToActionViewModel()
        ]
        XCTAssertEqual(sut.items, expected)
    }

    func testInit_spam() {
        sut = MailListActionSheetViewModel(labelId: Message.Location.spam.rawValue,
                                           title: randomTitle)
        XCTAssertEqual(sut.title, randomTitle)
        let expected: [MailListActionSheetItemViewModel] = [
            .starActionViewModel(),
            .unstarActionViewModel(),
            .markUnreadActionViewModel(),
            .markReadActionViewModel(),
            .labelAsActionViewModel(),
            .removeActionViewModel(),
            .notSpamActionViewModel(),
            .deleteActionViewModel(),
            .moveToActionViewModel()
        ]
        XCTAssertEqual(sut.items, expected)
    }

    func testInit_trash() {
        sut = MailListActionSheetViewModel(labelId: Message.Location.trash.rawValue,
                                           title: randomTitle)
        XCTAssertEqual(sut.title, randomTitle)
        let expected: [MailListActionSheetItemViewModel] = [
            .starActionViewModel(),
            .unstarActionViewModel(),
            .markUnreadActionViewModel(),
            .markReadActionViewModel(),
            .labelAsActionViewModel(),
            .moveToInboxActionViewModel(),
            .moveToArchive(),
            .deleteActionViewModel(),
            .moveToActionViewModel()
        ]
        XCTAssertEqual(sut.items, expected)
    }

    func testInit_allMail() {
        sut = MailListActionSheetViewModel(labelId: Message.Location.allmail.rawValue,
                                           title: randomTitle)
        XCTAssertEqual(sut.title, randomTitle)
        let expected: [MailListActionSheetItemViewModel] = [
            .starActionViewModel(),
            .unstarActionViewModel(),
            .markUnreadActionViewModel(),
            .markReadActionViewModel(),
            .labelAsActionViewModel(),
            .removeActionViewModel(),
            .moveToArchive(),
            .moveToSpam(),
            .moveToActionViewModel()
        ]
        XCTAssertEqual(sut.items, expected)
    }

    func testCustomLabel() {
        sut = MailListActionSheetViewModel(labelId: String.randomString(100),
                                           title: randomTitle)
        XCTAssertEqual(sut.title, randomTitle)
        let expected: [MailListActionSheetItemViewModel] = [
            .starActionViewModel(),
            .unstarActionViewModel(),
            .markUnreadActionViewModel(),
            .markReadActionViewModel(),
            .labelAsActionViewModel(),
            .removeActionViewModel(),
            .moveToArchive(),
            .moveToSpam(),
            .moveToActionViewModel()
        ]
        XCTAssertEqual(sut.items, expected)
    }
}
