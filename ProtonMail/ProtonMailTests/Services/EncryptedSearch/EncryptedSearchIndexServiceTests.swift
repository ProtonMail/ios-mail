// Copyright (c) 2022 Proton Technologies AG
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
import SQLite
import XCTest

class EncryptedSearchIndexServiceTests: XCTestCase {
    var userID: UserID!
    var esStateProviderMock: MockESIndexingStateProvider!
    var esFeatureStatusProviderMock: MockESFeatureStatusProvider!
    var sut: EncryptedSearchIndexService!

    override func setUp() {
        super.setUp()
        userID = UserID(String.randomString(20))
        esStateProviderMock = .init()
        esFeatureStatusProviderMock = .init()
        sut = EncryptedSearchIndexService(
            userID: userID,
            esStateProvider: esStateProviderMock,
            esEnableStatusProvider: esFeatureStatusProviderMock
        )
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        try removeTestDBFile(userID: userID)
        userID = nil
        sut = nil
        esStateProviderMock = nil
        esFeatureStatusProviderMock = nil
    }

    func testTimeToDateString() {
        let testDate = Date.fixture("2022-01-02 12:00:00")
        let timeInterval = testDate.timeIntervalSince1970

        let result = EncryptedSearchIndexService.timeToDateString(time: .init(timeInterval))
        XCTAssertEqual(result, "Jan 02, 2022")
    }

    func testGetSearchIndexName() {
        let result = EncryptedSearchIndexService.getSearchIndexName(userID)
        XCTAssertEqual(result, "encryptedSearchIndex_\(userID.rawValue).sqlite3")
    }

    func testGetSearchIndexPathToDB() {
        let dbName = String.randomString(20)

        let result = EncryptedSearchIndexService.getSearchIndexPathToDB(dbName)
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(String(result.suffix(dbName.count)), dbName)
    }

    func testCheckIfSearchIndexExists() throws {
        XCTAssertFalse(EncryptedSearchIndexService.checkIfSearchIndexExists(for: userID))

        try createTestDBFile(userID: userID)

        XCTAssertTrue(EncryptedSearchIndexService.checkIfSearchIndexExists(for: userID))
    }

    func testConnectToSearchIndex() throws {
        XCTAssertNotNil(sut.connectToSearchIndex())

        XCTAssertFalse(sut.getDBConnectionsDictionary().isEmpty)
        XCTAssertNotNil(sut.getDBConnectionsDictionary()[userID])
    }

    func testForceDatabaseConnection() {
        // create connection first
        XCTAssertNotNil(sut.connectToSearchIndex())

        XCTAssertNotNil(sut.getDBConnectionsDictionary()[userID])

        // Close DB connection
        sut.forceCloseDatabaseConnection()

        XCTAssertNil(sut.getDBConnectionsDictionary()[userID])
    }

    func testCreateSearchIndexDBIfNotExisting() {
        XCTAssertTrue(sut.createSearchIndexDBIfNotExisting())

        XCTAssertFalse(sut.createSearchIndexDBIfNotExisting())
    }

    func testAddNewEntryToSearchIndex_withExpectedState_rowIDNotMinus1() throws {
        sut.createSearchIndexDBIfNotExisting()
        esStateProviderMock.callGetESSate.bodyIs { _, _ in
            return EncryptedSearchIndexService.Constant.expectedESState.randomElement()!
        }

        let result = try sut.addNewEntryToSearchIndex(
            messageID: MessageID(String.randomString(20)),
            time: 1000,
            order: 1,
            labelIDs: [],
            encryptionIV: String.randomString(20),
            encryptedContent: String.randomString(20),
            encryptedContentFile: String.randomString(20),
            encryptedContentSize: 9999
        )

        XCTAssertNotEqual(result, -1)
        XCTAssertEqual(result, 1)
    }

    func testAddNewEntryToSearchIndex_withNotExpectedState_throwsError() {
        sut.createSearchIndexDBIfNotExisting()
        var allCases = EncryptedSearchIndexState.allCases
        allCases.removeAll(where: { EncryptedSearchIndexService.Constant.expectedESState.contains($0) })
        esStateProviderMock.callGetESSate.bodyIs { _, _ in
            return allCases.randomElement()!
        }

        XCTAssertThrowsError(
            try sut.addNewEntryToSearchIndex(
                messageID: MessageID(String.randomString(20)),
                time: 1000,
                order: 1,
                labelIDs: [],
                encryptionIV: String.randomString(20),
                encryptedContent: String.randomString(20),
                encryptedContentFile: String.randomString(20),
                encryptedContentSize: 9999
            )
        )
    }

    func testRemoveEntryFromSearchIndex() throws {
        let messageID = MessageID(String.randomString(20))
        sut.createSearchIndexDBIfNotExisting()
        esStateProviderMock.callGetESSate.bodyIs { _, _ in
            return .complete
        }
        esFeatureStatusProviderMock.isESOnStub.fixture = true
        _ = createTestData(messageID: messageID)

        let result = try sut.removeEntryFromSearchIndex(message: messageID)

        XCTAssertNotEqual(result, -1)
    }

    func testRemoveEntryFromSearchIndex_messageIDNotContained() throws {
        let messageID = MessageID(String.randomString(20))
        sut.createSearchIndexDBIfNotExisting()
        esStateProviderMock.callGetESSate.bodyIs { _, _ in
            return .complete
        }
        esFeatureStatusProviderMock.isESOnStub.fixture = true
        _ = createTestData(messageID: messageID)

        let result = try sut.removeEntryFromSearchIndex(
            message: .init(String.randomString(20))
        )

        XCTAssertNotEqual(result, -1)
    }

    func testRemoveEntryFromSearchIndex_esOff_throwError() throws {
        esFeatureStatusProviderMock.isESOnStub.fixture = false

        XCTAssertThrowsError(
            try sut.removeEntryFromSearchIndex(message: .init("test"))
        )
    }

    func testRemoveEntryFromSearchIndex_esDisable_throwError() {
        esStateProviderMock.callGetESSate.bodyIs { _, _ in
            return .disabled
        }

        XCTAssertThrowsError(
            try sut.removeEntryFromSearchIndex(message: .init("test"))
        )
    }

    func testUpdateEntryInSearchIndex() throws {
        let messageID = MessageID(String.randomString(20))
        sut.createSearchIndexDBIfNotExisting()
        _ = createTestData(messageID: messageID)
        esFeatureStatusProviderMock.isESOnStub.fixture = true
        let newEncryptedContent = String.randomString(20)
        let newIV = String.randomString(20)
        let newSize = 100

        sut.updateEntryInSearchIndex(
            messageID: messageID,
            encryptedContent: newEncryptedContent,
            encryptionIV: newIV,
            encryptedContentSize: newSize
        )

        let table = sut.getSearchableMessagesTable()
        let schema = sut.getDatabaseSchema()
        let connection = sut.getDBConnectionsDictionary()[userID]
        let newMsgQuery = table.filter(schema.messageID == messageID.rawValue)
        let results = try XCTUnwrap(try connection?.prepare(newMsgQuery))
        for result in results {
            let content = result[schema.encryptedContent]
            let iv = result[schema.encryptionIV]
            let size = result[schema.encryptedContentSize]

            XCTAssertEqual(content, newEncryptedContent)
            XCTAssertEqual(iv, newIV)
            XCTAssertEqual(size, newSize)
        }
    }

    func testGetNumberOfEntriesInSearchIndex_indexNotExists_returnMinus2() {
        XCTAssertEqual(sut.getNumberOfEntriesInSearchIndex(), -2)
    }

    func testGetNumberOfEntriesInSearchIndex_esOff_returnMinus1() {
        esFeatureStatusProviderMock.isESOnStub.fixture = false
        sut.createSearchIndexDBIfNotExisting()

        XCTAssertEqual(sut.getNumberOfEntriesInSearchIndex(), -1)
    }

    func testGetNumberOfEntriesInSearchIndex_noData_return0() {
        esFeatureStatusProviderMock.isESOnStub.fixture = true
        sut.createSearchIndexDBIfNotExisting()

        XCTAssertEqual(sut.getNumberOfEntriesInSearchIndex(), 0)
    }

    func testGetNumberOfEntriesInSearchIndex_withData_return1() {
        esFeatureStatusProviderMock.isESOnStub.fixture = true
        sut.createSearchIndexDBIfNotExisting()
        _ = createTestData(messageID: "msgID")

        XCTAssertEqual(sut.getNumberOfEntriesInSearchIndex(), 1)
    }

    func testDeleteSearchIndex() {
        esFeatureStatusProviderMock.isESOnStub.fixture = true
        sut.createSearchIndexDBIfNotExisting()

        XCTAssertNoThrow(try sut.deleteSearchIndex())
    }

    func testDeleteSearchIndex_indexNotExist_noErrorIsThrown() {
        XCTAssertNoThrow(try sut.deleteSearchIndex())
    }

    func testShrinkSearchIndex_esDisabled_returnFalse() {
        XCTAssertFalse(sut.shrinkSearchIndex(expectedSize: 100))
    }

    func testShrinkSearchIndex_esEnabled_returnTrue() {
        esFeatureStatusProviderMock.isESOnStub.fixture = true
        sut.createSearchIndexDBIfNotExisting()
        let originalSize = sut.getSizeOfSearchIndex().size
        _ = createTestData(messageID: MessageID(String.randomString(10)), fileSize: 100)

        XCTAssertTrue(sut.shrinkSearchIndex(expectedSize: 0))

        XCTAssertEqual(sut.getSizeOfSearchIndex().size, originalSize)
    }

    func testGetOldestMessageInSearchIndex_esDisabled_return0() {
        XCTAssertEqual(sut.getOldestMessageInSearchIndex().asInt, 0)
        XCTAssertEqual(sut.getOldestMessageInSearchIndex().asString, "")
    }

    func testGetOldestMessageInSearchIndex_esEnabled_returnDateOfTheOldestMessage() {
        esFeatureStatusProviderMock.isESOnStub.fixture = true
        sut.createSearchIndexDBIfNotExisting()
        let expectedDate = Date.fixture("2022-01-23 00:00:00")
        let date = expectedDate.addingTimeInterval(100000)
        _ = createTestData(messageID: MessageID("1"), date: expectedDate)
        _ = createTestData(messageID: MessageID("2"), date: date)

        let result = sut.getOldestMessageInSearchIndex()

        XCTAssertEqual(result.asInt, Int(expectedDate.timeIntervalSince1970))
        XCTAssertEqual(result.asString, "Jan 23, 2022")
    }

    func testGetListOfMessagesInSearchIndex() {
        esFeatureStatusProviderMock.isESOnStub.fixture = true
        sut.createSearchIndexDBIfNotExisting()
        _ = createTestData(messageID: MessageID("1"), date: Date.fixture("2022-01-23 00:00:00"))
        _ = createTestData(messageID: MessageID("2"), date: Date.fixture("2022-01-24 00:00:00"))
        _ = createTestData(messageID: MessageID("3"), date: Date.fixture("2022-01-25 00:00:00"))
        let queryDate = Date.fixture("2022-01-24 00:00:00")

        let result = sut.getListOfMessagesInSearchIndex(endDate: queryDate)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.map(\.messageID), ["3", "2"])
    }

    func testGetMessageIDOfOldestMessageInSearchIndex_esDisable_returnNil() {
        XCTAssertNil(sut.getMessageIDOfOldestMessageInSearchIndex())
    }

    func testGetMessageIDOfOldestMessageInSearchIndex() {
        esFeatureStatusProviderMock.isESOnStub.fixture = true
        sut.createSearchIndexDBIfNotExisting()
        _ = createTestData(messageID: MessageID("1"), date: Date.fixture("2022-01-23 00:00:00"))
        _ = createTestData(messageID: MessageID("2"), date: Date.fixture("2022-01-24 00:00:00"))
        _ = createTestData(messageID: MessageID("3"), date: Date.fixture("2022-01-25 00:00:00"))

        let result = sut.getMessageIDOfOldestMessageInSearchIndex()

        XCTAssertEqual(result, "1")
    }

    func testGetMessageIDOfOldestMessageInSearchIndex_noIndex_returnNil() {
        esFeatureStatusProviderMock.isESOnStub.fixture = true
        sut.createSearchIndexDBIfNotExisting()

        let result = sut.getMessageIDOfOldestMessageInSearchIndex()

        XCTAssertNil(result)
    }
}

extension EncryptedSearchIndexServiceTests {
    private func createTestDBFile(userID: UserID) throws {
        let fileName = "encryptedSearchIndex_\(userID.rawValue).sqlite3"
        let url = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true).appendingPathComponent(fileName)
        try "test".data(using: .utf8)?.write(to: url)
    }

    private func removeTestDBFile(userID: UserID) throws {
        let fileName = "encryptedSearchIndex_\(userID.rawValue).sqlite3"
        let url = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true).appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: url.relativePath) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private func createTestData(
        messageID: MessageID,
        fileSize: Int = 100,
        date: Date? = nil
    ) -> Int? {
        return try? sut.addNewEntryToSearchIndex(
            messageID: messageID,
            time: Int(date?.timeIntervalSince1970 ?? 1000),
            order: 1,
            labelIDs: [],
            encryptionIV: String.randomString(20),
            encryptedContent: String.randomString(20),
            encryptedContentFile: String.randomString(fileSize),
            encryptedContentSize: fileSize
        )
    }
}
