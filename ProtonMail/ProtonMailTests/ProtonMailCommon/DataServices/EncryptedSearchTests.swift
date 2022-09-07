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

import CoreData
import Crypto
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services
import SQLite
import XCTest

@testable import ProtonMail

class EncryptedSearchTests: XCTestCase {
    var testUserID: String!
    var testMessageID: String!
    var testSearchIndexDBName: String!
    var connectionToSearchIndexDB: Connection!
    var testCache: EncryptedsearchCache!

    var coreDataService: CoreDataService!
    var user: UserManager!
    var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.testUserID = self.setUpTestUser()!
        self.testMessageID = "uniqueID1"

        // Create a test search index for user 'test'
        self.createTestSearchIndexDB()
        let doesTestIndexExist: Bool = EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.testUserID)
        print("Test database created: \(doesTestIndexExist)")
        let numberOfEntries = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
        print("Entries in db: \(numberOfEntries)")

        // build the cache for user 'test'
        self.buildTestCache()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        // Delete test search index for user 'test'
        let doesTestIndexExist: Bool = EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.testUserID)
        if doesTestIndexExist {
            try self.deleteTestSearchIndexDB()  // delete test index if it exists
        }

        // Reset some values in EncryptedSearchService Singleton
        EncryptedSearchService.shared.pauseIndexingDueToOverheating = false
        EncryptedSearchService.shared.pauseIndexingDueToLowBattery = false
        EncryptedSearchService.shared.pauseIndexingDueToWiFiNotDetected = false
        EncryptedSearchService.shared.pauseIndexingDueToNetworkIssues = false

        // delete cache for user 'test'
        _ = EncryptedSearchCacheService.shared.deleteCache(userID: self.testUserID)
    }

    private func setUpTestUser() -> String? {
        let users: UsersManager = sharedServices.get(by: UsersManager.self)
        let testUserInfo = UserInfo(displayName: "test display name", maxSpace: 42, notificationEmail: "test notification name",signature: "test signature", usedSpace: 123, userAddresses: [], autoSC: 321, language: "DE", maxUpload: 234, notify: 2345, showImage: 645, swipeL: 3452, swipeR: 4132, role: 1234, delinquent: 4123, keys: [], userId: "test", sign: 1234, attachPublicKey: 5467, linkConfirmation: "test link confirmation", credit: 098, currency: "BOL", pwdMode: 667, twoFA: 776, enableFolderColor: 77, inheritParentFolderColor: 88, subscribed: 12, groupingMode: 1, weekStart: 0, delaySendSeconds: 0)
        let testAuth = AuthCredential(sessionID: "test session id", accessToken: "test access token", refreshToken: "test refresh token",expiration: .distantFuture, userName: "test user name", userID: "test", privateKey: "test private key", passwordKeySalt: "test password key salt")
        let apiService = PMAPIService(doh: users.doh, sessionUID: "test session id")
        self.user = UserManager(api: apiService, userinfo: testUserInfo, auth: testAuth, parent: users)
        users.users.append(self.user)
        return users.firstUser?.userInfo.userId
    }

    private func createTestSearchIndexDB() {
        EncryptedSearchService.shared.setESState(userID: self.testUserID, indexingState: .downloading)
        userCachedStatus.isEncryptedSearchOn = true
        self.testSearchIndexDBName = EncryptedSearchIndexService.shared.getSearchIndexName(self.testUserID)
        self.connectionToSearchIndexDB = EncryptedSearchIndexService.shared.connectToSearchIndex(userID: self.testUserID)!
        EncryptedSearchIndexService.shared.createSearchIndexTable(userID: self.testUserID)

        let testMessage: ESMessage = ESMessage(id: self.testMessageID, order: 1, conversationID: "", subject: "subject", unread: 1, type: 1, senderAddress: "sender", senderName: "sender", sender: ESSender(name: "sender", address: "address"), toList: [], ccList: [], bccList: [], time: 1637058775, size: 5, isEncrypted: 1, expirationTime: Date(), isReplied: 0, isRepliedAll: 0, isForwarded: 0, spamScore: 0, addressID: "", numAttachments: 0, flags: 0, labelIDs: ["5", "1"], externalID: "", body: "hello", header: "", mimeType: "", userID: self.testUserID)
        let testMessageSecond: ESMessage = ESMessage(id: "uniqueID2", order: 2, conversationID: "", subject: "subject", unread: 1, type: 1, senderAddress: "sender", senderName: "sender", sender: ESSender(name: "sender", address: "address"), toList: [], ccList: [], bccList: [], time: 1637141557, size: 5, isEncrypted: 1, expirationTime: Date(), isReplied: 0, isRepliedAll: 0, isForwarded: 0, spamScore: 0, addressID: "", numAttachments: 0, flags: 0, labelIDs: ["5", "1"], externalID: "", body: "hello2", header: "", mimeType: "", userID: self.testUserID)
        let encryptedContent: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: MessageEntity(testMessage.toMessage()), cleanedBody: "hello", userID: self.testUserID)
        let encryptedContent2: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: MessageEntity(testMessageSecond.toMessage()), cleanedBody: "hello2", userID: self.testUserID)
        EncryptedSearchService.shared.addMessageToSearchIndex(userID: testUserID, message: MessageEntity(testMessage.toMessage()), encryptedContent: encryptedContent, completionHandler: {})
        EncryptedSearchService.shared.addMessageToSearchIndex(userID: testUserID, message: MessageEntity(testMessageSecond.toMessage()), encryptedContent: encryptedContent2, completionHandler: {})
    }

    private func buildTestCache(){
        let dbParams = EncryptedSearchIndexService.shared.getDBParams(self.testUserID)
        let testKey: Data? = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + self.testUserID)
        let cipher = EncryptedsearchAESGCMCipher(testKey!)

        self.testCache = EncryptedSearchCacheService.shared.buildCacheForUser(userId: self.testUserID, dbParams: dbParams!, cipher: cipher!)
    }

    private func deleteTestSearchIndexDB() throws {
        // Create the path to the database for user 'test'.
        let pathToTestDB: String = EncryptedSearchIndexService.shared.getSearchIndexPathToDB(self.testSearchIndexDBName)
        let urlToDB: URL? = URL(string: pathToTestDB)

        // Tear down search index db
        sqlite3_close(self.connectionToSearchIndexDB.handle)
        self.connectionToSearchIndexDB = nil

        // Remove the database file.
        try FileManager.default.removeItem(atPath: urlToDB!.path)
    }

    func testEncryptedSearchServiceSingleton() throws {
        XCTAssertNotNil(EncryptedSearchService.shared)
    }

    func testPauseIndexingByUser() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingByUser

        sut(true, self.testUserID)
        // Wait for 2 seconds - as pausing is async
        _ = XCTWaiter.wait(for: [expectation(description: "Wait for n seconds")], timeout: 2.0)

        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.paused)
    }

    func testPauseIndexingDueToLowBattery() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToLowBattery = true
        sut(true, self.testUserID)
        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.paused)
    }

    func testPauseIndexingDueToOverheating() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToOverheating = true
        sut(true, self.testUserID)
        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.paused)
    }

    func testPauseIndexingDueToWiFiNotDetected() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToWiFiNotDetected = true
        sut(true, self.testUserID)
        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.paused)
    }

    func testPauseIndexingDueToNetworkConnectivityIssues() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToNetworkIssues = true
        sut(true, self.testUserID)
        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.paused)
    }

    func testDeleteSearchIndex() throws {
        let sut = EncryptedSearchService.shared.deleteSearchIndex
        sut(self.testUserID, {})

        // Wait for 2 seconds - as deleting the search index is async
        _ = XCTWaiter.wait(for: [expectation(description: "Wait for n seconds")], timeout: 2.0)
        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.disabled)
        XCTAssertFalse(EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.testUserID))
    }

    func testAddMessageToSearchIndex() throws {
        EncryptedSearchService.shared.setESState(userID: self.testUserID, indexingState: .downloading)
        let sut = EncryptedSearchService.shared.addMessageToSearchIndex
        let testMessage: ESMessage = ESMessage(id: "uniqueID3",
                                               order: 3,
                                               conversationID: "",
                                               subject: "subject",
                                               unread: 1,
                                               type: 1,
                                               senderAddress: "sender",
                                               senderName: "sender",
                                               sender: ESSender(name: "sender", address: "address"),
                                               toList: [],
                                               ccList: [],
                                               bccList: [],
                                               time: 1637058776,
                                               size: 5,
                                               isEncrypted: 1,
                                               expirationTime: Date(),
                                               isReplied: 0,
                                               isRepliedAll: 0,
                                               isForwarded: 0,
                                               spamScore: 0,
                                               addressID: "",
                                               numAttachments: 0,
                                               flags: 0,
                                               labelIDs: ["5", "1"],
                                               externalID: "",
                                               body: "hello",
                                               header: "",
                                               mimeType: "",
                                               userID: self.testUserID)
        let encryptedContent: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: MessageEntity(testMessage.toMessage()),
                                                                 cleanedBody: "hello",
                                                                 userID: self.testUserID)
        sut(self.testUserID, MessageEntity(testMessage.toMessage()), encryptedContent, {})

        let numberOfEntries = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
        XCTAssertEqual(numberOfEntries, 3)
    }

    func testClearSearchState() throws {
        let sut = EncryptedSearchService.shared.clearSearchState
        sut()
        XCTAssertNil(EncryptedSearchService.shared.searchState)
    }

    /*func testHighlightKeyWords() throws {
        let sut = EncryptedSearchService.shared.highlightKeyWords
        EncryptedSearchService.shared.searchQuery = ["custom", "folders"]
        let html = """
<html>
 <head></head>
 <body>
  <p>Hello,</p>
  <p>You have 1 new message(s) in your inbox and custom folders.</p>
  <p>Please log in at <a href="https://mail.protonmail.com">https://mail.protonmail.com</a> to check them. These notifications can be turned off by logging into your account and disabling the daily notification setting.</p>
  <p>Best regards,</p>
  <p>The ProtonMail Team</p>
 </body>
</html>
"""
        var result = sut(html)
        var expectedResult: String = """
  <p>Hello,</p>
  <p>
   <span>
    You have 1 new message(s) in your inbox and
    <mark style="background-color: #8498E9">custom</mark>
    <mark style="background-color: #8498E9">
    folders</mark>.</span></p>
  <p>Please log in at <a href="https://mail.protonmail.com">https://mail.protonmail.com</a> to check them. These notifications can be turned off by logging into your account and disabling the daily notification setting.</p>
  <p>Best regards,</p>
  <p>The ProtonMail Team</p>
"""
        result = result.components(separatedBy: .whitespacesAndNewlines).joined()
        expectedResult = expectedResult.components(separatedBy: .whitespacesAndNewlines).joined()
        XCTAssertEqual(result, expectedResult)
    }*/

    func testEncryptedSearchIndexServiceSingleton() throws {
        XCTAssertNotNil(EncryptedSearchIndexService.shared)
    }

    func testGetSearchIndexName() throws {
        let sut = EncryptedSearchIndexService.shared.getSearchIndexName
        let testUserID: String = "123"
        let result: String = sut(testUserID)

        XCTAssertEqual(result, "encryptedSearchIndex_123.sqlite3")
    }

    /*func testGetSearchIndexPathToDB() throws {
        let sut = EncryptedSearchIndexService.shared.getSearchIndexPathToDB
        let dbName: String = "test.sqlite3"
        let result: String = sut(dbName)
        let pathToDocumentsDirectory: String = ((FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))[0]).absoluteString

        XCTAssertEqual(result, pathToDocumentsDirectory+dbName)
    }*/

    /*func testCheckIfSearchIndexExists() throws {
        let sut = EncryptedSearchIndexService.shared.checkIfSearchIndexExists
        let resultTrue: Bool = sut(self.testUserID)
        let userIDNonExisting: String = "abc"
        let resultFalse: Bool = sut(userIDNonExisting)

        XCTAssertEqual(resultTrue, true)
        XCTAssertEqual(resultFalse, false)
    }*/

    func testDeleteSearchIndexDB() throws {
        let sut = EncryptedSearchIndexService.shared.deleteSearchIndex
        let userID: String = "test2"
        let dbName: String = EncryptedSearchIndexService.shared.getSearchIndexName(userID)
        let pathToDB: String = EncryptedSearchIndexService.shared.getSearchIndexPathToDB(dbName)
        let urlToDB: URL? = URL(string: pathToDB)
        EncryptedSearchService.shared.setESState(userID: userID, indexingState: .downloading)
        _ = EncryptedSearchIndexService.shared.connectToSearchIndex(userID: userID)

        // delete db
        let result: Bool = sut(userID)
        XCTAssertEqual(result, true)

        // check if file still exists
        let fileExists: Bool = FileManager.default.fileExists(atPath: urlToDB!.path)
        XCTAssertEqual(fileExists, false)
    }

    /*func testAddNewEntryToSearchIndex() throws {
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
                                 MessageID(messageID),
                                 time,
                                 order,
                                 LabelEntity.convert(from: labelIDs as NSSet),
                                 encryptionIV,
                                 encryptedContent,
                                 encryptedContentFile,
                                 encryptedContentSize)

        XCTAssertEqual(result, 3)   // There are already 2 entries in the db, therefore this should be entry number 3.
    }*/

    /*func testGetNumberOfEntriesInSearchIndexNonExistingUser() throws {
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
    }*/

    func testEncryptedSearchCacheServiceSingleton() throws {
        XCTAssertNotNil(EncryptedSearchCacheService.shared)
    }

    /*func testBuildCacheForUser() throws {
        let sut = EncryptedSearchCacheService.shared.buildCacheForUser

        let dbParams = EncryptedSearchIndexService.shared.getDBParams(self.testUserID)!
        let testKey = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + self.testUserID)
        let cipher = EncryptedsearchAESGCMCipher(testKey)

        let result: EncryptedsearchCache? = sut(self.testUserID, dbParams, cipher!)

        XCTAssertEqual(result?.getLength(), 2)   // There should be two cached messages
    }*/

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

    /*func testIsCacheBuilt() throws {
        let sut = EncryptedSearchCacheService.shared.isCacheBuilt

        // Build cache
        let dbParams = EncryptedSearchIndexService.shared.getDBParams(self.testUserID)
        let testKey: Data? = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + self.testUserID)
        let cipher = EncryptedsearchAESGCMCipher(testKey!)
        _ = EncryptedSearchCacheService.shared.buildCacheForUser(userId: self.testUserID, dbParams: dbParams!, cipher: cipher!)
        // Wait until cache is built
        _ = XCTWaiter.wait(for: [expectation(description: "Wait for n seconds")], timeout: 4.0)

        let resultTrue: Bool = sut(self.testUserID)
        XCTAssertTrue(resultTrue)
    }*/

    func testIsPartial() throws {
        let sut = EncryptedSearchCacheService.shared.isPartial
        let result: Bool = sut(self.testUserID)
        XCTAssertFalse(result)  // cache for just the two testmessages should be build completely
    }

    /*func testGetNumberOfCachedMessages() throws {
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
    }*/

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
