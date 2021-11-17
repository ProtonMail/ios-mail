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
import Crypto
import SQLite
@testable import ProtonMail

class EncryptedSearchCacheServiceTests: XCTestCase {
    var testUserID: String!
    var testMessageID: String!
    var connectionToSearchIndexDB: Connection!
    var testSearchIndexDBName: String!
    var testCache: EncryptedsearchCache!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        self.testUserID = "test"
        self.testMessageID = "uniqueID1"

        // Create a search index db for user 'test'.
        self.createTestSearchIndexDB()

        //build the cache for user 'test'
        self.buildTestCache()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        // delete search index db for user 'test'
        try self.deleteTestSearchIndexDB()

        // delete cache for user 'test'
        EncryptedSearchCacheService.shared.deleteCache(userID: self.testUserID)
    }

    func createTestSearchIndexDB(){
        self.testSearchIndexDBName = "encryptedSearchIndex_test.sqlite3"
        self.connectionToSearchIndexDB = EncryptedSearchIndexService.shared.connectToSearchIndex(for: self.testUserID)!
        EncryptedSearchIndexService.shared.createSearchIndexTable(using: self.connectionToSearchIndexDB)
        _ = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex(for: self.testUserID, messageID: self.testMessageID, time: 1637058775, labelIDs: ["5", "1"], isStarred: false, unread: false, location: 1, order: 1, hasBody: true, decryptionFailed: false, encryptionIV: Data("iv".utf8), encryptedContent: Data("content".utf8), encryptedContentFile: "linktofile")
        _ = EncryptedSearchIndexService.shared.addNewEntryToSearchIndex(for: self.testUserID, messageID: "uniqueID2", time: 1637141557, labelIDs: ["5", "1"], isStarred: false, unread: false, location: 1, order: 2, hasBody: true, decryptionFailed: false, encryptionIV: Data("iv".utf8), encryptedContent: Data("content".utf8), encryptedContentFile: "linktofile")
    }
    
    func deleteTestSearchIndexDB() throws {
        // Create the path to the database for user 'test'.
        let pathToTestDB: String = EncryptedSearchIndexService.shared.getSearchIndexPathToDB(self.testSearchIndexDBName)
        let urlToDB: URL? = URL(string: pathToTestDB)

        // Tear down search index db
        sqlite3_close(self.connectionToSearchIndexDB.handle)
        self.connectionToSearchIndexDB = nil

        // Remove the database file.
        try FileManager.default.removeItem(atPath: urlToDB!.path)
    }

    func buildTestCache(){
        let dbParams = EncryptedSearchIndexService.shared.getDBParams(self.testUserID)
        var error: NSError?
        let testKey = CryptoRandomToken(32, &error)
        let cipher = EncryptedsearchAESGCMCipher(testKey)
        self.testCache = EncryptedSearchCacheService.shared.buildCacheForUser(userId: self.testUserID, dbParams: dbParams, cipher: cipher!)
    }

    func testEncryptedSearchCacheServiceSingleton() throws {
        XCTAssertNotNil(EncryptedSearchCacheService.shared)
    }

    func testBuildCacheForUser() throws {
        let sut = EncryptedSearchCacheService.shared.buildCacheForUser
        let dbname = EncryptedSearchIndexService.shared.getSearchIndexName(self.testUserID)
        print("path to db: \(EncryptedSearchIndexService.shared.getSearchIndexPathToDB(dbname))")
        let dbParams = EncryptedSearchIndexService.shared.getDBParams(self.testUserID)
        var error: NSError?
        let testKey = CryptoRandomToken(32, &error)
        let cipher = EncryptedsearchAESGCMCipher(testKey)

        let result: EncryptedsearchCache = sut(self.testUserID, dbParams, cipher!)

        XCTAssertEqual(result.getLength(), 2)   // There should be two cached messages
    }

    func testDeleteCache() throws {
        let sut = EncryptedSearchCacheService.shared.deleteCache
        sut(self.testUserID)

        let isCacheStillExisting: Bool = EncryptedSearchCacheService.shared.isCacheBuilt(userID: self.testUserID)
        XCTAssertEqual(isCacheStillExisting, false) // Cache should not exist anymore.
    }

    //func testUpdateCachedMessage() throws {
        //TODO
    //}

    func testDeleteCachedMessage() throws {
        let sut = EncryptedSearchCacheService.shared.deleteCachedMessage
        let result: Bool = sut(self.testUserID, self.testMessageID)
        XCTAssertEqual(result, true)

        let resultFalse: Bool = sut(self.testUserID, "unknownMessageID")
        XCTAssertEqual(resultFalse, false)
    }

    func testIsCacheBuilt() throws {
        let sut = EncryptedSearchCacheService.shared.isCacheBuilt
        let userIDNotExisting: String = "abc"
        let resultFalse: Bool = sut(userIDNotExisting)
        XCTAssertFalse(resultFalse)

        self.buildTestCache()
        let resultTrue: Bool = sut(self.testUserID)
        XCTAssertTrue(resultTrue)
    }
}
