// Copyright (c) 2023 Proton Technologies AG
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

@testable import ProtonMail
import XCTest

class ConversationMessageModelTests: XCTestCase {
    var sut: ConversationMessageModel!

    func testAutoDeletingConversationShouldBeTrueIfSpamWithExpirationTagAndWithNonFrozenExpiration() {
        let location = Message.Location.spam
        let expirationTag = TagUIModel.init(title: "",
                                            titleColor: UIColor.clear,
                                            titleWeight: .black,
                                            icon: nil,
                                            tagColor: UIColor.clear)
        let isFrozen = false
        sut = ConversationMessageModel(messageLocation: location,
                                       isCustomFolderLocation: Bool.random(),
                                       initial: nil,
                                       isRead: Bool.random(),
                                       sender: [],
                                       time: "",
                                       isForwarded: Bool.random(),
                                       isReplied: Bool.random(),
                                       isRepliedToAll: Bool.random(),
                                       isStarred: Bool.random(),
                                       hasAttachment: Bool.random(),
                                       tags: [],
                                       expirationTag: expirationTag,
                                       isDraft: Bool.random(),
                                       isScheduled: Bool.random(),
                                       isSent: Bool.random(),
                                       isExpirationFrozen: isFrozen)
        XCTAssertTrue(sut.isAutoDeletingMessage)
    }

    func testAutoDeletingConversationShouldBeTrueIfTrashWithExpirationTagAndWithNonFrozenExpiration() {
        let location = Message.Location.trash
        let expirationTag = TagUIModel.init(title: "",
                                            titleColor: UIColor.clear,
                                            titleWeight: .black,
                                            icon: nil,
                                            tagColor: UIColor.clear)
        let isFrozen = false
        sut = ConversationMessageModel(messageLocation: location,
                                       isCustomFolderLocation: Bool.random(),
                                       initial: nil,
                                       isRead: Bool.random(),
                                       sender: [],
                                       time: "",
                                       isForwarded: Bool.random(),
                                       isReplied: Bool.random(),
                                       isRepliedToAll: Bool.random(),
                                       isStarred: Bool.random(),
                                       hasAttachment: Bool.random(),
                                       tags: [],
                                       expirationTag: expirationTag,
                                       isDraft: Bool.random(),
                                       isScheduled: Bool.random(),
                                       isSent: Bool.random(),
                                       isExpirationFrozen: isFrozen)
        XCTAssertTrue(sut.isAutoDeletingMessage)
    }

    func testAutoDeletingConversationShouldBeFalseIfLocationOtherThanSpamTrash() {
        let location = Message.Location.inbox
        let expirationTag = TagUIModel.init(title: "",
                                            titleColor: UIColor.clear,
                                            titleWeight: .black,
                                            icon: nil,
                                            tagColor: UIColor.clear)
        let isFrozen = false
        sut = ConversationMessageModel(messageLocation: location,
                                       isCustomFolderLocation: Bool.random(),
                                       initial: nil,
                                       isRead: Bool.random(),
                                       sender: [],
                                       time: "",
                                       isForwarded: Bool.random(),
                                       isReplied: Bool.random(),
                                       isRepliedToAll: Bool.random(),
                                       isStarred: Bool.random(),
                                       hasAttachment: Bool.random(),
                                       tags: [],
                                       expirationTag: expirationTag,
                                       isDraft: Bool.random(),
                                       isScheduled: Bool.random(),
                                       isSent: Bool.random(),
                                       isExpirationFrozen: isFrozen)
        XCTAssertFalse(sut.isAutoDeletingMessage)
    }

    func testAutoDeletingConversationShouldBeFalseIfExpirationTagIsNil() {
        let location = Message.Location.trash
        let expirationTag: TagUIModel? = nil
        let isFrozen = false
        sut = ConversationMessageModel(messageLocation: location,
                                       isCustomFolderLocation: Bool.random(),
                                       initial: nil,
                                       isRead: Bool.random(),
                                       sender: [],
                                       time: "",
                                       isForwarded: Bool.random(),
                                       isReplied: Bool.random(),
                                       isRepliedToAll: Bool.random(),
                                       isStarred: Bool.random(),
                                       hasAttachment: Bool.random(),
                                       tags: [],
                                       expirationTag: expirationTag,
                                       isDraft: Bool.random(),
                                       isScheduled: Bool.random(),
                                       isSent: Bool.random(),
                                       isExpirationFrozen: isFrozen)
        XCTAssertFalse(sut.isAutoDeletingMessage)
    }

    func testAutoDeletingConversationShouldBeFalseIfExpirationTimeIsFrozen() {
        let location = Message.Location.trash
        let expirationTag = TagUIModel.init(title: "",
                                            titleColor: UIColor.clear,
                                            titleWeight: .black,
                                            icon: nil,
                                            tagColor: UIColor.clear)
        let isFrozen = true
        sut = ConversationMessageModel(messageLocation: location,
                                       isCustomFolderLocation: Bool.random(),
                                       initial: nil,
                                       isRead: Bool.random(),
                                       sender: [],
                                       time: "",
                                       isForwarded: Bool.random(),
                                       isReplied: Bool.random(),
                                       isRepliedToAll: Bool.random(),
                                       isStarred: Bool.random(),
                                       hasAttachment: Bool.random(),
                                       tags: [],
                                       expirationTag: expirationTag,
                                       isDraft: Bool.random(),
                                       isScheduled: Bool.random(),
                                       isSent: Bool.random(),
                                       isExpirationFrozen: isFrozen)
        XCTAssertFalse(sut.isAutoDeletingMessage)
    }
}
