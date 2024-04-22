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
    private let viewModes: [ViewMode] = [.singleMessage, .conversation]
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
        for viewMode in viewModes {
            sut = MailListActionSheetViewModel(
                labelId: Message.Location.inbox.rawValue,
                title: randomTitle,
                locationViewMode: viewMode
            )
            XCTAssertEqual(sut.title, randomTitle)
            var expected: [MailListActionSheetItemViewModel] = [
                .starActionViewModel(),
                .unstarActionViewModel(),
                .markUnreadActionViewModel(),
                .markReadActionViewModel(),
                .labelAsActionViewModel(),
                .removeActionViewModel(),
                .moveToArchive(),
                .moveToSpam(),
                .moveToActionViewModel(),
                .customizeToolbarActionViewModel()
            ]
            if viewMode == .conversation {
                expected.insert(.snooze(), at: 4)
            }
            XCTAssertEqual(sut.items, expected)
        }
    }

    func testInit_scheduled() {
        for viewMode in viewModes {
            sut = MailListActionSheetViewModel(
                labelId: Message.Location.scheduled.rawValue,
                title: randomTitle,
                locationViewMode: viewMode
            )
            XCTAssertEqual(sut.title, randomTitle)
            let expected: [MailListActionSheetItemViewModel] = [
                .starActionViewModel(),
                .unstarActionViewModel(),
                .markUnreadActionViewModel(),
                .markReadActionViewModel(),
                .labelAsActionViewModel(),
                .removeActionViewModel(),
                .moveToArchive(),
                .moveToActionViewModel(),
                .customizeToolbarActionViewModel()
            ]
            XCTAssertEqual(sut.items, expected)
        }
    }

    func testInit_draft() {
        sut = MailListActionSheetViewModel(
            labelId: Message.Location.draft.rawValue,
            title: randomTitle,
            locationViewMode: .singleMessage
        )
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
            .moveToActionViewModel(),
            .customizeToolbarActionViewModel()
        ]
        XCTAssertEqual(sut.items, expected)
    }

    func testInit_sent() {
        sut = MailListActionSheetViewModel(
            labelId: Message.Location.sent.rawValue,
            title: randomTitle,
            locationViewMode: .singleMessage
        )
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
            .moveToActionViewModel(),
            .customizeToolbarActionViewModel()
        ]
        XCTAssertEqual(sut.items, expected)
    }

    func testInit_starred() {
        for viewMode in viewModes {
            sut = MailListActionSheetViewModel(
                labelId: Message.Location.starred.rawValue,
                title: randomTitle,
                locationViewMode: viewMode
            )
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
                .moveToActionViewModel(),
                .customizeToolbarActionViewModel()
            ]
            XCTAssertEqual(sut.items, expected)
        }
    }

    func testInit_archive() {
        for viewMode in viewModes {
            sut = MailListActionSheetViewModel(
                labelId: Message.Location.archive.rawValue,
                title: randomTitle,
                locationViewMode: viewMode
            )
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
                .moveToActionViewModel(),
                .customizeToolbarActionViewModel()
            ]
            XCTAssertEqual(sut.items, expected)
        }
    }

    func testInit_spam() {
        for viewMode in viewModes {
            sut = MailListActionSheetViewModel(
                labelId: Message.Location.spam.rawValue,
                title: randomTitle,
                locationViewMode: viewMode
            )
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
                .moveToActionViewModel(),
                .customizeToolbarActionViewModel()
            ]
            XCTAssertEqual(sut.items, expected)
        }
    }

    func testInit_trash() {
        for viewMode in viewModes {
            sut = MailListActionSheetViewModel(
                labelId: Message.Location.trash.rawValue,
                title: randomTitle,
                locationViewMode: viewMode
            )
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
                .moveToActionViewModel(),
                .customizeToolbarActionViewModel()
            ]
            XCTAssertEqual(sut.items, expected)
        }
    }

    func testInit_allMail() {
        for viewMode in viewModes {
            sut = MailListActionSheetViewModel(
                labelId: Message.Location.allmail.rawValue,
                title: randomTitle,
                locationViewMode: viewMode
            )
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
                .moveToActionViewModel(),
                .customizeToolbarActionViewModel()
            ]
            XCTAssertEqual(sut.items, expected)
        }
    }

    func testCustomLabel() {
        for viewMode in viewModes {
            sut = MailListActionSheetViewModel(
                labelId: String.randomString(100),
                title: randomTitle,
                locationViewMode: viewMode
            )
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
                .moveToActionViewModel(),
                .customizeToolbarActionViewModel()
            ]
            XCTAssertEqual(sut.items, expected)
        }
    }
}
