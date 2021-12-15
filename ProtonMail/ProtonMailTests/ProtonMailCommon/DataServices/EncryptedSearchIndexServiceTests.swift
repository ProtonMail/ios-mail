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
    var connection: Connection!
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
        // Connect to test database.
        self.connection = try Connection(pathToTestDB)
        // Create the table
        EncryptedSearchIndexService.shared.createSearchIndexTable(using: self.connection)
        // Add one entry in the table
        _ = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex(for: self.testUserID, messageID: self.testMessageID, time: 1637058775, labelIDs: ["5", "1"], isStarred: false, unread: false, location: 1, order: 1, hasBody: true, decryptionFailed: false, encryptionIV: Data("iv".utf8).base64EncodedData(), encryptedContent: Data("content".utf8).base64EncodedData(), encryptedContentFile: "linktofile", encryptedContentSize: Data("content".utf8).base64EncodedData().count)
        _ = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex(for: self.testUserID, messageID: "uniqueID2", time: 1637141557, labelIDs: ["5", "1"], isStarred: false, unread: false, location: 1, order: 2, hasBody: true, decryptionFailed: false, encryptionIV: Data("iv".utf8).base64EncodedData(), encryptedContent: Data("content".utf8).base64EncodedData(), encryptedContentFile: "linktofile", encryptedContentSize: Data("content".utf8).base64EncodedData().count)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        // Create the path to the database for user 'test'.
        let pathToTestDB: String = EncryptedSearchIndexService.shared.getSearchIndexPathToDB(self.testSearchIndexDBName)
        let urlToDB: URL? = URL(string: pathToTestDB)

        // Explicitly close the handle of the connection to the database.
        sqlite3_close(self.connection.handle)
        // Set to connection to nil.
        self.connection = nil
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

    func testConnectToSearchIndex() throws {
        let sut = EncryptedSearchIndexService.shared.connectToSearchIndex
        var result: Connection? = sut(self.testUserID)
        XCTAssertEqual(result!.description, self.connection.description)

        var resultSecond: Connection? = sut(self.testUserID)
        XCTAssertEqual(result!.description, resultSecond!.description)

        //close connection
        sqlite3_close(result?.handle)
        result = nil
        sqlite3_close(resultSecond?.handle)
        resultSecond = nil
    }

    func testCreateSearchIndexTable() throws {
        let sut = EncryptedSearchIndexService.shared.createSearchIndexTable
        sut(self.connection)

        //check if table exists
        let result: Bool = (try self.connection.scalar("SELECT EXISTS(SELECT name FROM sqlite_master WHERE name = ?)", EncryptedSearchIndexService.DatabaseConstants.Table_Searchable_Messages) as! Int64) > 0
        XCTAssertEqual(result, true)
    }

    func testCreateSearchIndexDBIfNotExisting() throws {
        let sut = EncryptedSearchIndexService.shared.createSearchIndexDBIfNotExisting
        sut(self.testUserID)

        //check if table exists
        let result: Bool = (try self.connection.scalar("SELECT EXISTS(SELECT name FROM sqlite_master WHERE name = ?)", EncryptedSearchIndexService.DatabaseConstants.Table_Searchable_Messages) as! Int64) > 0
        XCTAssertEqual(result, true)
    }

    func testDeleteSearchIndex() throws {
        let sut = EncryptedSearchIndexService.shared.deleteSearchIndex
        let userID: String = "test2"
        let dbName: String = EncryptedSearchIndexService.shared.getSearchIndexName(userID)
        let pathToDB: String = EncryptedSearchIndexService.shared.getSearchIndexPathToDB(dbName)
        let urlToDB: URL? = URL(string: pathToDB)
        _ = EncryptedSearchIndexService.shared.connectToSearchIndex(for: userID)

        //delete db
        let result: Bool = sut(userID)
        XCTAssertEqual(result, true)

        //check if file still exists
        let fileExists: Bool = FileManager.default.fileExists(atPath: urlToDB!.path)
        XCTAssertEqual(fileExists, false)
    }

    func testResizeSearchIndex() throws {
        let sut = EncryptedSearchIndexService.shared.resizeSearchIndex
        let result: Bool = sut(self.testUserID, 8000)

        XCTAssertEqual(result, true)

        let numberOfEntries: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
        XCTAssertEqual(numberOfEntries, 1)
        let sizeOfIndex: Int64? = EncryptedSearchIndexService.shared.getSizeOfSearchIndex(for: self.testUserID).asInt64
        XCTAssertEqual(sizeOfIndex, 5)
    }

    func testAddNewEntryToSearchIndex() throws {
        let sut = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex
        let messageID: String = "testMessage"
        let time: Int = 42
        let labelIDs: Set<String> = ["5", "1"]
        let isStarred: Bool = true
        let unread: Bool = true
        let location: Int = 1
        let order: Int = 1
        let hasBody: Bool = true
        let decryptionFailed: Bool = false
        let encryptionIV: Data = Data("iv".utf8).base64EncodedData()
        let encryptedContent: Data = Data("content".utf8).base64EncodedData()
        let encryptedContentFile: String = "test"
        let encryptedContentSize: Int = encryptedContent.count

        let result: Int64? = sut(self.testUserID, messageID, time, labelIDs, isStarred, unread, location, order, hasBody, decryptionFailed, encryptionIV, encryptedContent, encryptedContentFile, encryptedContentSize)

        XCTAssertEqual(result, 3)   // There are already 2 entries in the db, therefore this should be entry number 3.
    }

    func testRemoveEntryFromSearchIndex() throws {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let sut = EncryptedSearchIndexService.shared.removeEntryFromSearchIndex
            let result: Int? = sut(self.testUserID, self.testMessageID)
            XCTAssertEqual(result!, 1)  // We delete 1 entry from the db.
        }
    }

    func testGetNumberOfEntriesInSearchIndex() throws {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let sut = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex
            let result: Int = sut(self.testUserID)
            XCTAssertEqual(result, 2)

            // Test for non existing user
            let resultZero: Int = sut("abc")
            XCTAssertEqual(resultZero, 0)
        }
    }

    func testGetOldestMessageInSearchIndex() throws {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let sut = EncryptedSearchIndexService.shared.getOldestMessageInSearchIndex
            let result: String = sut(self.testUserID)
            XCTAssertEqual(result, "Nov 16, 2021")
        }
    }

    /*func testGetNewestMessageInSearchIndex() throws {
        let sut = EncryptedSearchIndexService.shared.getNewestMessageInSearchIndex
        let result: String = sut(self.testUserID)
        XCTAssertEqual(result, "Nov 17, 2021")
    }*/

    func testGetSizeOfSearchIndex() throws {
        let sut = EncryptedSearchIndexService.shared.getSizeOfSearchIndex
        let resultString: String = sut(self.testUserID).asString
        let resultInteger: Int64? = sut(self.testUserID).asInt64
        XCTAssertEqual(resultString, "12 KB")
        XCTAssertEqual(resultInteger, 12288)
    }

    /*func testGetDBParams() throws {
        let sut = EncryptedSearchIndexService.shared.getDBParams
        let result: EncryptedsearchDBParams = sut(self.testUserID)

        let pathToDocumentsDirectory: String = ((FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))[0]).absoluteString
        let pathToTestDB: String = pathToDocumentsDirectory + self.testSearchIndexDBName
        let dbParams: EncryptedsearchDBParams? = EncryptedsearchNewDBParams(pathToTestDB, "SearchableMessage", "ID", "Time", "Location", "Unread", "IsStarred", "LabelIDs", "EncryptionIV", "EncryptedContent", "EncryptedContentFile")
        XCTAssertEqual(result.description, dbParams!.description)
    }*/

    // func getFreeDiskSpace dependes on the hardware you run the test on.
    // func timeToDateString is private
    // func compressSearchIndex cannot easily be tested. It should defragment the sqlite database.
}
