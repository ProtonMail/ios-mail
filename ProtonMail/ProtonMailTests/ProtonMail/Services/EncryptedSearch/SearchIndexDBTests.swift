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

import XCTest
@testable import ProtonMail

final class SearchIndexDBTests: XCTestCase {
    var sut: SearchIndexDB!

    override func setUpWithError() throws {
        let userID = UserID("testUser")
        sut = SearchIndexDB(userID: userID)
        try sut.deleteSearchIndex()
    }

    override func tearDownWithError() throws {
        try sut.deleteSearchIndex()
        sut = nil
    }

    func testCreateIndexDB() throws {
        XCTAssertFalse(sut.dbExists)
        createDB()
        XCTAssertTrue(sut.dbExists)
    }

    func testGetDBSize() throws {
        createDB()
        _ = try XCTUnwrap(sut.size)
    }

    func testAddEntryToSearchIndex_with_unexpected_states() throws {
        createDB()

        for num in 0...3 {
            let rowID = try sut.addNewEntryToSearchIndex(
                messageID: MessageID(String.randomString(7)),
                time: Int.random(in: 4...99),
                order: Int.random(in: 4...99),
                labelIDs: [],
                encryptionIV: nil,
                encryptedContent: nil,
                encryptedContentFile: String.randomString(7),
                encryptedContentSize: 3
            )
            let count = try XCTUnwrap(rowID)
            XCTAssertEqual(count, num + 1)
        }
    }

    func testUpdateEntryInSearchIndex() throws {
        createDB()
        let existingID = MessageID("existing")
        let unknownID = MessageID("unknown")
        let rowID = try sut.addNewEntryToSearchIndex(
            messageID: existingID,
            time: 2000,
            order: 2,
            labelIDs: [],
            encryptionIV: nil,
            encryptedContent: nil,
            encryptedContentFile: "file",
            encryptedContentSize: 3
        )
        XCTAssertEqual(try XCTUnwrap(rowID), 1)

        XCTAssertTrue(try sut.updateEntryInSearchIndex(
            messageID: existingID,
            encryptedContent: "New content",
            encryptionIV: "New iv",
            encryptedContentSize: 20
        ))

        XCTAssertFalse(try sut.updateEntryInSearchIndex(
            messageID: unknownID,
            encryptedContent: "aaa",
            encryptionIV: "bbb",
            encryptedContentSize: 999
        ))
    }

    func testRemoveEntryFromSearchIndex_with_unexpected_precondition() throws {
        createDB()
        XCTAssertThrowsError(try sut.removeEntryFromSearchIndex(
            isEncryptedSearchOn: false,
            currentState: .downloading,
            messageID: MessageID("r")
        ))
        XCTAssertThrowsError(try sut.removeEntryFromSearchIndex(
            isEncryptedSearchOn: true,
            currentState: .disabled,
            messageID: MessageID("r")
        ))
    }

    func testRemoveEntryFromSearchIndex() throws {
        createDB()
        let messages = (0...5).map { MessageID("message\($0)") }
        for (index, id) in messages.enumerated() {
            let rowID = try sut.addNewEntryToSearchIndex(
                messageID: id,
                time: index * 1000,
                order: index,
                labelIDs: [],
                encryptionIV: nil,
                encryptedContent: nil,
                encryptedContentFile: "file",
                encryptedContentSize: 20
            )
            XCTAssertEqual(rowID, index + 1)
        }

        for id in messages.reversed() {
            let isDeleted = try sut.removeEntryFromSearchIndex(
                isEncryptedSearchOn: true,
                currentState: .downloading,
                messageID: id
            )
            XCTAssertTrue(isDeleted)
        }
        let isDeleted = try sut.removeEntryFromSearchIndex(
            isEncryptedSearchOn: true,
            currentState: .downloading,
            messageID: MessageID("unknown")
        )
        XCTAssertFalse(isDeleted)
    }

    func testGetOldestTime_and_numOfEntries() throws {
        createDB()
        let messages = (0...5).map { MessageID("message\($0)") }
        for (index, id) in messages.enumerated() {
            var time = (index + 1) * 2000
            if index == 3 {
                time = 2
            }
            let rowID = try sut.addNewEntryToSearchIndex(
                messageID: id,
                time: time,
                order: index,
                labelIDs: [],
                encryptionIV: nil,
                encryptedContent: nil,
                encryptedContentFile: "file",
                encryptedContentSize: 20
            )
            XCTAssertEqual(rowID, index + 1)
        }
        let oldestTime = try XCTUnwrap(sut.oldestMessageTime())
        XCTAssertEqual(oldestTime, 2)
        let number = try sut.numberOfEntries()
        XCTAssertEqual(number, 6)
    }

    func testShrinkSearchIndex() throws {
        createDB()
        let messages = (0...5).map { MessageID("message\($0)") }
        for (index, id) in messages.enumerated() {
            var time = (index + 1) * 2000
            if index == 3 {
                time = 2
            }
            let rowID = try sut.addNewEntryToSearchIndex(
                messageID: id,
                time: time,
                order: index,
                labelIDs: [],
                encryptionIV: nil,
                encryptedContent: nil,
                encryptedContentFile: "file",
                encryptedContentSize: 20
            )
            XCTAssertEqual(rowID, index + 1)
        }
        // Default size on my mac is 12288, not sure if it changes on the other mac
        let defaultDBSize: ByteCount = 12_288
        let expectedSize: ByteCount = defaultDBSize + 30
        try sut.shrinkSearchIndex(expectedSize: expectedSize)
        let dbSize = try XCTUnwrap(sut.size)
        XCTAssertLessThanOrEqual(dbSize, expectedSize)
    }

    func testSequenceAdd_and_remove() throws {
        createDB()
        let messages = (0...5).map { MessageID("message\($0)") }
        for (index, id) in messages.enumerated() {
            var time = (index + 1) * 2000
            let rowID = try sut.addNewEntryToSearchIndex(
                messageID: id,
                time: time,
                order: index,
                labelIDs: [],
                encryptionIV: nil,
                encryptedContent: nil,
                encryptedContentFile: "file",
                encryptedContentSize: 20
            )
            XCTAssertEqual(rowID, index + 1)
        }

        for index in 4...5 {
            let id = messages[index]
            let isDeleted = try sut.removeEntryFromSearchIndex(
                isEncryptedSearchOn: true,
                currentState: .downloading,
                messageID: id
            )
            XCTAssertTrue(isDeleted)
        }
        let rowID = try sut.addNewEntryToSearchIndex(
            messageID: MessageID("hi"),
            time: 500,
            order: 2,
            labelIDs: [],
            encryptionIV: nil,
            encryptedContent: nil,
            encryptedContentFile: "file",
            encryptedContentSize: 20
        )
        XCTAssertEqual(rowID, 5)
    }
}

extension SearchIndexDBTests {
    private func createDB() {
        sut.createIfNeeded()
        XCTAssertTrue(sut.dbExists)
    }
}
