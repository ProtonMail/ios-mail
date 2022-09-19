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
import CoreData
import Groot
@testable import ProtonMail

class EncryptedSearchCacheServiceTests: XCTestCase {
    var testUserID: String!
    var testMessageID: String!
    var testSearchIndexDBName: String!
    var testCache: EncryptedsearchCache!

    var coreDataService: CoreDataService!
    var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        self.testUserID = "testCache"
        self.testMessageID = "uniqueID1"

        // Create a search index db for user 'test'.
        self.createTestSearchIndexDB()

        // build the cache for user 'test'
        self.buildTestCache()

        // Set up core data to create some test messages
        try self.setupCoreData()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        // delete search index db for user 'test'
        try self.deleteTestSearchIndexDB()

        // delete cache for user 'test'
        _ = EncryptedSearchCacheService.shared.deleteCache(userID: self.testUserID)

        // Delete core data
        self.deleteCoreData()
    }

    private func createTestSearchIndexDB(){
        self.testSearchIndexDBName = "encryptedSearchIndex_testCache.sqlite3"
        userCachedStatus.isEncryptedSearchOn = true
        EncryptedSearchService.shared.setESState(userID: self.testUserID, indexingState: .downloading)
        EncryptedSearchIndexService.shared.createSearchIndexTable(userID: self.testUserID)

        let testMessage: ESMessage = ESMessage(id: self.testMessageID, order: 1, conversationID: "", subject: "subject", unread: 1, type: 1, senderAddress: "sender", senderName: "sender", sender: ESSender(Name: "sender", Address: "address"), toList: [], ccList: [], bccList: [], time: 1637058775, size: 5, isEncrypted: 1, expirationTime: Date(), isReplied: 0, isRepliedAll: 0, isForwarded: 0, spamScore: 0, addressID: "", numAttachments: 0, flags: 0, labelIDs: ["5", "1"], externalID: "", body: "hello", header: "", mimeType: "", userID: self.testUserID)
        let testMessageSecond: ESMessage = ESMessage(id: "uniqueID2", order: 2, conversationID: "", subject: "subject", unread: 1, type: 1, senderAddress: "sender", senderName: "sender", sender: ESSender(Name: "sender", Address: "address"), toList: [], ccList: [], bccList: [], time: 1637141557, size: 5, isEncrypted: 1, expirationTime: Date(), isReplied: 0, isRepliedAll: 0, isForwarded: 0, spamScore: 0, addressID: "", numAttachments: 0, flags: 0, labelIDs: ["5", "1"], externalID: "", body: "hello2", header: "", mimeType: "", userID: self.testUserID)
        let encryptedContent: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: testMessage, cleanedBody: "hello", userID: self.testUserID)
        let encryptedContent2: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: testMessageSecond, cleanedBody: "hello2", userID: self.testUserID)
        EncryptedSearchService.shared.addMessageToSearchIndex(userID: testUserID, message: testMessage, encryptedContent: encryptedContent, completionHandler: {})
        EncryptedSearchService.shared.addMessageToSearchIndex(userID: testUserID, message: testMessageSecond, encryptedContent: encryptedContent2, completionHandler: {})
    }

    private func deleteTestSearchIndexDB() throws {
        // Create the path to the database for user 'test'.
        let pathToTestDB: String = EncryptedSearchIndexService.shared.getSearchIndexPathToDB(self.testSearchIndexDBName)
        let urlToDB: URL? = URL(string: pathToTestDB)

        // Remove the database file.
        try FileManager.default.removeItem(atPath: urlToDB!.path)
    }

    private func buildTestCache(){
        let dbParams = EncryptedSearchIndexService.shared.getDBParams(self.testUserID)
        let testKey: Data? = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + self.testUserID)
        let cipher = EncryptedsearchAESGCMCipher(testKey!)

        self.testCache = EncryptedSearchCacheService.shared.buildCacheForUser(userId: self.testUserID, dbParams: dbParams, cipher: cipher!)
    }

    private func setupCoreData() throws {
        coreDataService = CoreDataService(container: CoreDataStore.shared.memoryPersistentContainer)
        testContext = coreDataService.rootSavingContext

        let parsedLabel = testLabelsData.parseJson()!
        _ = try GRTJSONSerialization.objects(withEntityName: Label.Attributes.entityName,
                                             fromJSONArray: parsedLabel,
                                             in: testContext)

        try testContext.save()
    }

    private func deleteCoreData() {
        coreDataService = nil
        testContext = nil
    }

    private func makeTestMessageIn(_ labelId: String, messageID: String) -> Message? {
        let parsedObject = testMessageMetaData.parseObjectAny()!
        let message = try? GRTJSONSerialization
            .object(withEntityName: Message.Attributes.entityName,
                    fromJSONDictionary: parsedObject,
                    in: testContext) as? Message
        message?.remove(labelID: "0")
        message?.add(labelID: labelId)
        message?.messageID = messageID
        try? testContext.save()
        return message
    }

    func testEncryptedSearchCacheServiceSingleton() throws {
        XCTAssertNotNil(EncryptedSearchCacheService.shared)
    }

    func testBuildCacheForUser() throws {
        let sut = EncryptedSearchCacheService.shared.buildCacheForUser

        let dbParams = EncryptedSearchIndexService.shared.getDBParams(self.testUserID)
        let testKey = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + self.testUserID)
        let cipher = EncryptedsearchAESGCMCipher(testKey!)

        let result: EncryptedsearchCache = sut(self.testUserID, dbParams, cipher!)

        XCTAssertEqual(result.getLength(), 2)   // There should be two cached messages
    }

    func testDeleteCache() throws {
        let sut = EncryptedSearchCacheService.shared.deleteCache
        let result: Bool = sut(self.testUserID)

        XCTAssertEqual(result, false) // Cache should not exist anymore.
    }

    func testDeleteCachedMessageUnKnownMessage() throws {
        let sut = EncryptedSearchCacheService.shared.deleteCachedMessage
        let resultFalse: Bool = sut(self.testUserID, "unknownMessageID")
        XCTAssertEqual(resultFalse, false)
    }

    func testIsCacheBuiltUserUnknown() throws {
        let sut = EncryptedSearchCacheService.shared.isCacheBuilt
        let userIDNotExisting: String = "abc"
        let resultFalse: Bool = sut(userIDNotExisting)
        XCTAssertFalse(resultFalse)
    }

    func testIsCacheBuilt() throws {
        let sut = EncryptedSearchCacheService.shared.isCacheBuilt

        // Build cache
        let dbParams = EncryptedSearchIndexService.shared.getDBParams(self.testUserID)
        let testKey: Data? = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + self.testUserID)
        let cipher = EncryptedsearchAESGCMCipher(testKey!)
        _ = EncryptedSearchCacheService.shared.buildCacheForUser(userId: self.testUserID, dbParams: dbParams, cipher: cipher!)
        // Wait until cache is built
        _ = XCTWaiter.wait(for: [expectation(description: "Wait for n seconds")], timeout: 4.0)

        let resultTrue: Bool = sut(self.testUserID)
        XCTAssertTrue(resultTrue)
    }

    func testIsPartial() throws {
        let sut = EncryptedSearchCacheService.shared.isPartial
        let result: Bool = sut(self.testUserID)
        XCTAssertFalse(result)  // cache for just the two testmessages should be build completely
    }

    func testGetNumberOfCachedMessages() throws {
        let sut = EncryptedSearchCacheService.shared.getNumberOfCachedMessages

        // Wait until cache is built
        _ = XCTWaiter.wait(for: [expectation(description: "Wait for n seconds")], timeout: 4.0)

        let result: Int = sut(self.testUserID)
        XCTAssertEqual(result, 2)   // There should be 2 messages in the cache
    }

    func testContainsMessage() throws {
            let sut = EncryptedSearchCacheService.shared.containsMessage
            let result: Bool = sut(self.testUserID, self.testMessageID)
            XCTAssertEqual(result, true)
    }

    func testContainsMessageUnknownMessage() throws {
            let sut = EncryptedSearchCacheService.shared.containsMessage
            let resultFalse: Bool = sut(self.testUserID, "unknownMessageID")
            XCTAssertFalse(resultFalse)
    }

    func testgetLastCacheUserID() throws {
        let sut = EncryptedSearchCacheService.shared.getLastCacheUserID
        let result: String? = sut()
        XCTAssertEqual(result, self.testUserID)
    }
}
