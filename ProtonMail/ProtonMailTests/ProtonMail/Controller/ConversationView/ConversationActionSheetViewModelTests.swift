// Copyright (c) 2022 Proton AG
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

class ConversationActionSheetViewModelTests: XCTestCase {
    private var dummyTitle: String { String.randomString(100) }

    private let expectedForAllInTrashDraftOrSent: [MessageViewActionSheetAction] = [.inbox, .archive, .delete, .moveTo, .toolbarCustomization]
    private let expectedForAllInArchive: [MessageViewActionSheetAction] = [.trash, .inbox, .spam, .moveTo, .toolbarCustomization]
    private let expectedForAllInSpam: [MessageViewActionSheetAction] = [.trash, .spamMoveToInbox, .delete, .moveTo, .toolbarCustomization]
    private let expectedForMessInDifferentFolders: [MessageViewActionSheetAction] = [.trash, .archive, .spam, .moveTo, .toolbarCustomization]

    func testInit_whenActionsAreUnreadAndStarred() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: true,
            isStarred: true,
            areAllMessagesIn: { _ in irrelevantForTheTest }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.prefix(3)) == [.markRead, .unstar, .labelAs])
    }

    func testInit_whenActionsAreReadAndStarred() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: false,
            isStarred: true,
            areAllMessagesIn: { _ in irrelevantForTheTest }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.prefix(3)) == [.markUnread, .unstar, .labelAs])
    }

    func testInit_whenActionsAreUnreadAndNotStarred() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: true,
            isStarred: false,
            areAllMessagesIn: { _ in irrelevantForTheTest }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.prefix(3)) == [.markRead, .star, .labelAs])
    }

    func testInit_whenActionsAreReadAndNotStarred() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: false,
            isStarred: false,
            areAllMessagesIn: { _ in irrelevantForTheTest }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.prefix(3)) == [.markUnread, .star, .labelAs])
    }

    func testInit_whenAllMessagesAreLocatedInInbox() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            areAllMessagesIn: { location in location == .inbox }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.suffix(5)) == expectedForMessInDifferentFolders)
    }

    func testInit_whenAllMessagesAreLocatedInTrash() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            areAllMessagesIn: { location in location == .trash }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.suffix(5)) == expectedForAllInTrashDraftOrSent)
    }

    func testInit_whenAllMessagesAreLocatedInDraft() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            areAllMessagesIn: { location in location == .draft }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.suffix(5)) == expectedForAllInTrashDraftOrSent)
    }

    func testInit_whenAllMessagesAreLocatedInSent() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            areAllMessagesIn: { location in location == .sent }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.suffix(5)) == expectedForAllInTrashDraftOrSent)
    }

    func testInit_whenAllMessagesAreLocatedInArchive() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            areAllMessagesIn: { location in location == .archive }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.suffix(5)) == expectedForAllInArchive)
    }

    func testInit_whenAllMessagesAreLocatedInSpam() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            areAllMessagesIn: { location in location == .spam }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.suffix(5)) == expectedForAllInSpam)
    }
}
