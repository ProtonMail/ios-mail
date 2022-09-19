// Copyright (c) 2021 Proton Technologies AG
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
import SQLite
import Crypto
@testable import ProtonMail

class EncryptedSearchIndexServiceTests: XCTestCase {
    var testUserID: String!
    var testMessageID: String!
    var testSearchIndexDBName: String!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // Create a test table for user 'test'.
        self.testUserID = "test"
        self.testMessageID = "uniqueID"
        self.testSearchIndexDBName = "encryptedSearchIndex_test.sqlite3"
        let pathToDocumentsDirectory: String = ((FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))[0]).absoluteString
        let pathToTestDB: String = pathToDocumentsDirectory + self.testSearchIndexDBName

        EncryptedSearchService.shared.setESState(userID: self.testUserID, indexingState: .complete)

        // Create the table
        EncryptedSearchIndexService.shared.createSearchIndexTable(userID: self.testUserID)
        // Add one entry in the table
        _ = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex(userID: self.testUserID,
                                                                        messageID: self.testMessageID,
                                                                        time: 1637058775,
                                                                        order: 1,
                                                                        labelIDs: ["5", "1"],
                                                                        encryptionIV: Data("iv".utf8).base64EncodedString(),
                                                                        encryptedContent: Data("content".utf8).base64EncodedString(),
                                                                        encryptedContentFile: "linktofile",
                                                                        encryptedContentSize: Data("content".utf8).base64EncodedString().count)
        _ = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex(userID: self.testUserID,
                                                                        messageID: "uniqueID2",
                                                                        time: 1637141557,
                                                                        order: 2,
                                                                        labelIDs: ["5", "1"],
                                                                        encryptionIV: Data("iv".utf8).base64EncodedString(),
                                                                        encryptedContent: Data("content".utf8).base64EncodedString(),
                                                                        encryptedContentFile: "linktofile",
                                                                        encryptedContentSize: Data("content".utf8).base64EncodedString().count)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        // Create the path to the database for user 'test'.
        let pathToTestDB: String = EncryptedSearchIndexService.shared.getSearchIndexPathToDB(self.testSearchIndexDBName)
        let urlToDB: URL? = URL(string: pathToTestDB)

        // Remove the database file.
        try FileManager.default.removeItem(atPath: urlToDB!.path)
    }

    func testEncryptedSearchIndexServiceSingleton() throws {
        XCTAssertNotNil(EncryptedSearchIndexService.shared)
    }

    func testGetSearchIndexName() throws {
        let sut = EncryptedSearchIndexService.shared.getSearchIndexName
        let testUserID: String = "123"
        let result: String = sut(testUserID)

        XCTAssertEqual(result, "encryptedSearchIndex_123.sqlite3")
    }

    func testGetSearchIndexPathToDB() throws {
        let sut = EncryptedSearchIndexService.shared.getSearchIndexPathToDB
        let dbName: String = "test.sqlite3"
        let result: String = sut(dbName)
        let pathToDocumentsDirectory: String = ((FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))[0]).absoluteString

        XCTAssertEqual(result, pathToDocumentsDirectory+dbName)
    }

    func testCheckIfSearchIndexExists() throws {
        let sut = EncryptedSearchIndexService.shared.checkIfSearchIndexExists
        let resultTrue: Bool = sut(self.testUserID)
        let userIDNonExisting: String = "abc"
        let resultFalse: Bool = sut(userIDNonExisting)

        XCTAssertEqual(resultTrue, true)
        XCTAssertEqual(resultFalse, false)
    }

    func testDeleteSearchIndex() throws {
        let sut = EncryptedSearchIndexService.shared.deleteSearchIndex
        let userID: String = "test2"
        let dbName: String = EncryptedSearchIndexService.shared.getSearchIndexName(userID)
        let pathToDB: String = EncryptedSearchIndexService.shared.getSearchIndexPathToDB(dbName)
        let urlToDB: URL? = URL(string: pathToDB)
        EncryptedSearchService.shared.setESState(userID: userID, indexingState: .downloading)
        _ = EncryptedSearchIndexService.shared.connectToSearchIndex(for: userID)

        // delete db
        let result: Bool = sut(userID)
        XCTAssertEqual(result, true)

        // check if file still exists
        let fileExists: Bool = FileManager.default.fileExists(atPath: urlToDB!.path)
        XCTAssertEqual(fileExists, false)
    }

    func testAddNewEntryToSearchIndex() throws {
        EncryptedSearchService.shared.setESState(userID: self.testUserID, indexingState: .complete)
        let sut = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex
        let messageID: String = "testMessage"
        let time: Int = 1637058775
        let labelIDs: Set<String> = ["5", "1"]
        let order: Int = 1
        let encryptionIV: String = Data("iv".utf8).base64EncodedString()
        let encryptedContent: String = Data("content".utf8).base64EncodedString()
        let encryptedContentFile: String = "test"
        let encryptedContentSize: Int = encryptedContent.count

        let result: Int64? = sut(self.testUserID,
                                 messageID,
                                 time,
                                 order,
                                 labelIDs,
                                 encryptionIV,
                                 encryptedContent,
                                 encryptedContentFile,
                                 encryptedContentSize)

        XCTAssertEqual(result, 3)   // There are already 2 entries in the db, therefore this should be entry number 3.
    }

    func testGetNumberOfEntriesInSearchIndexNonExistingUser() throws {
        let sut = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex
        let resultZero: Int = sut("abc")
        XCTAssertEqual(resultZero, -1)
    }

    func testGetSizeOfSearchIndex() throws {
        let sut = EncryptedSearchIndexService.shared.getSizeOfSearchIndex
        let resultString: String = sut(self.testUserID).asString
        let resultInteger: Int64? = sut(self.testUserID).asInt64
        XCTAssertEqual(resultString, "12 KB")
        XCTAssertEqual(resultInteger, 12288)
    }
}
