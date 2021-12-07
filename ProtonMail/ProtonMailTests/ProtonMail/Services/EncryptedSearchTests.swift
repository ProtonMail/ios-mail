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

import ProtonCore_Doh
import ProtonCore_Services
import ProtonCore_Networking
import ProtonCore_DataModel

@testable import ProtonMail

class EncryptedSearchTests: XCTestCase {
    var testUserID: String!
    var testMessageID: String!
    var testSearchIndexDBName: String!
    var connectionToSearchIndexDB: Connection!

    var coreDataService: CoreDataService!
    var testContext: NSManagedObjectContext!
    let customLabelId = "Vg_DqN6s-xg488vZQBkiNGz0U-62GKN6jMYRnloXY-isM9s5ZR-rWCs_w8k9Dtcc-sVC-qnf8w301Q-1sA6dyw=="

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        self.testUserID = self.setUpTestUser()!
        print("Test user id: \(self.testUserID)")

        self.testMessageID = "uniqueID1"

        // Create a test search index for user 'test'
        self.createTestSearchIndexDB()
        let doesTestIndexExist: Bool = EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.testUserID)
        print("Test database created: \(doesTestIndexExist)")
        let numberOfEntries = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
        print("Entries in db: \(numberOfEntries)")
        
        // Set up core data to create some test messages
        try self.setupCoreData()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        // Delete test search index for user 'test'
        try self.deleteTestSearchIndexDB()

        // Reset some values in EncryptedSearchService Singleton
        EncryptedSearchService.shared.numInterruptions = 0
        EncryptedSearchService.shared.numPauses = 0

        // Delete core data
        self.deleteCoreData()
    }

    private func setUpTestUser() -> String? {
        let users: UsersManager = sharedServices.get(by: UsersManager.self)
        let testUserInfo = UserInfo(displayName: "test display name", maxSpace: 42, notificationEmail: "test notification name",signature: "test signature", usedSpace: 123, userAddresses: [], autoSC: 321, language: "DE", maxUpload: 234, notify: 2345, showImage: 645, swipeL: 3452, swipeR: 4132, role: 1234, delinquent: 4123, keys: [], userId: "test", sign: 1234, attachPublicKey: 5467, linkConfirmation: "test link confirmation", credit: 098, currency: "BOL", pwdMode: 667, twoFA: 776, enableFolderColor: 77, inheritParentFolderColor: 88, subscribed: 12, groupingMode: 1, weekStart: 0)
        let testAuth = AuthCredential(sessionID: "test session id", accessToken: "test access token", refreshToken: "test refresh token",expiration: .distantFuture, userName: "test user name", userID: "test", privateKey: "test private key", passwordKeySalt: "test password key salt")
        let apiService = PMAPIService(doh: users.doh, sessionUID: "test session id")
        let user: UserManager = UserManager(api: apiService, userinfo: testUserInfo, auth: testAuth, parent: users)
        users.users.append(user)
        return users.firstUser?.userInfo.userId
    }

    private func createTestSearchIndexDB() {
        self.testSearchIndexDBName = EncryptedSearchIndexService.shared.getSearchIndexName(self.testUserID)
        self.connectionToSearchIndexDB = EncryptedSearchIndexService.shared.connectToSearchIndex(for: self.testUserID)!
        EncryptedSearchIndexService.shared.createSearchIndexTable(using: self.connectionToSearchIndexDB)

        let testMessage: ESMessage = ESMessage(id: self.testMessageID, order: 1, conversationID: "", subject: "subject", unread: 1, type: 1, senderAddress: "sender", senderName: "sender", sender: ESSender(Name: "sender", Address: "address"), toList: [], ccList: [], bccList: [], time: 1637058775, size: 5, isEncrypted: 1, expirationTime: Date(), isReplied: 0, isRepliedAll: 0, isForwarded: 0, spamScore: 0, addressID: "", numAttachments: 0, flags: 0, labelIDs: ["5", "1"], externalID: "", body: "hello", header: "", mimeType: "", userID: self.testUserID)
        let testMessageSecond: ESMessage = ESMessage(id: "uniqueID2", order: 2, conversationID: "", subject: "subject", unread: 1, type: 1, senderAddress: "sender", senderName: "sender", sender: ESSender(Name: "sender", Address: "address"), toList: [], ccList: [], bccList: [], time: 1637141557, size: 5, isEncrypted: 1, expirationTime: Date(), isReplied: 0, isRepliedAll: 0, isForwarded: 0, spamScore: 0, addressID: "", numAttachments: 0, flags: 0, labelIDs: ["5", "1"], externalID: "", body: "hello2", header: "", mimeType: "", userID: self.testUserID)
        let encryptedContent: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: testMessage, cleanedBody: "hello", userID: self.testUserID)
        let encryptedContent2: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: testMessageSecond, cleanedBody: "hello2", userID: self.testUserID)
        EncryptedSearchService.shared.addMessageKewordsToSearchIndex(testUserID, testMessage, encryptedContent, false)
        EncryptedSearchService.shared.addMessageKewordsToSearchIndex(testUserID, testMessageSecond, encryptedContent2, false)
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

    private func makeTestMessageIn(_ labelId: String) -> Message? {
        let parsedObject = testMessageMetaData.parseObjectAny()!
        let message = try? GRTJSONSerialization
            .object(withEntityName: Message.Attributes.entityName,
                    fromJSONDictionary: parsedObject,
                    in: testContext) as? Message
        message?.remove(labelID: "0")
        message?.add(labelID: labelId)
        try? testContext.save()
        return message
    }

    func testEncryptedSearchServiceSingleton() throws {
        XCTAssertNotNil(EncryptedSearchService.shared)
    }

    func testDetermineEncryptedSearchState() throws {
        let sut = EncryptedSearchService.shared.determineEncryptedSearchState
        sut()

        XCTAssertEqual(EncryptedSearchService.shared.state, EncryptedSearchService.EncryptedSearchIndexState.undetermined)
    }

    func testBuildSearchIndex() throws {
        //TODO
    }

    // Private Function
    /* func testCheckIfIndexingIsComplete() throws {
        //TODO
    } */

    // Private function
    /* func testCleanUpAfterIndexing() throws {
        //TODO
    } */

    func testPauseAndResumeIndexingByUser() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingByUser

        // Test pause
        sut(true)
        XCTAssertEqual(EncryptedSearchService.shared.state, EncryptedSearchService.EncryptedSearchIndexState.paused)
        XCTAssertEqual(EncryptedSearchService.shared.numPauses, 1)
        XCTAssertFalse(EncryptedSearchService.shared.indexBuildingInProgress)

        // Test resume
        sut(false)
        XCTAssertEqual(EncryptedSearchService.shared.state, EncryptedSearchService.EncryptedSearchIndexState.downloading)
        XCTAssertEqual(EncryptedSearchService.shared.numPauses, 1)  // should not increase compared to before
        XCTAssertTrue(EncryptedSearchService.shared.indexBuildingInProgress)
    }

    func testPauseIndexingDueToLowBattery() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToLowBattery = true
        sut(true, nil)
        XCTAssertEqual(EncryptedSearchService.shared.state, EncryptedSearchService.EncryptedSearchIndexState.paused)
        XCTAssertEqual(EncryptedSearchService.shared.numInterruptions, 1)
        XCTAssertFalse(EncryptedSearchService.shared.indexBuildingInProgress)
    }

    func testPauseIndexingDueToOverheating() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToOverheating = true
        sut(true, nil)
        XCTAssertEqual(EncryptedSearchService.shared.state, EncryptedSearchService.EncryptedSearchIndexState.paused)
        XCTAssertEqual(EncryptedSearchService.shared.numInterruptions, 1)
        XCTAssertFalse(EncryptedSearchService.shared.indexBuildingInProgress)
    }

    func testPauseIndexingDueToLowStorage() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToLowStorage = true
        sut(true, nil)
        XCTAssertEqual(EncryptedSearchService.shared.state, EncryptedSearchService.EncryptedSearchIndexState.paused)
        XCTAssertEqual(EncryptedSearchService.shared.numInterruptions, 1)
        XCTAssertFalse(EncryptedSearchService.shared.indexBuildingInProgress)
    }

    func testPauseIndexingDueToWiFiNotDetected() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToWiFiNotDetected = true
        sut(true, nil)
        XCTAssertEqual(EncryptedSearchService.shared.state, EncryptedSearchService.EncryptedSearchIndexState.paused)
        XCTAssertEqual(EncryptedSearchService.shared.numInterruptions, 1)
        XCTAssertFalse(EncryptedSearchService.shared.indexBuildingInProgress)
    }

    func testPauseIndexingDueToNetworkConnectivityIssues() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToNetworkConnectivityIssues = true
        sut(true, nil)
        XCTAssertEqual(EncryptedSearchService.shared.state, EncryptedSearchService.EncryptedSearchIndexState.paused)
        XCTAssertEqual(EncryptedSearchService.shared.numInterruptions, 1)
        XCTAssertFalse(EncryptedSearchService.shared.indexBuildingInProgress)
    }

    // Private Function
    /*func testPauseAndResumeIndexing() throws {
        //TODO
    }*/

    func testUpdateSearchIndex() throws {
        //TODO
    }

    func testProcessEventsAfterIndexing() throws {
        //TODO
    }

    func testInsertSingleMessageToSearchIndex() throws {
        let sut = EncryptedSearchService.shared.insertSingleMessageToSearchIndex
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.allmail.rawValue))
        sut(message)
        // Wait for the message to be inserted
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let numberOfMessagesInSearchIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
            XCTAssertEqual(numberOfMessagesInSearchIndex, 3)
        }
    }

    func testDeleteMessageFromSearchIndex() throws {
        //TODO
    }

    func testDeleteSearchIndex() throws {
        let sut = EncryptedSearchService.shared.deleteSearchIndex
        sut()

        XCTAssertEqual(EncryptedSearchService.shared.state, EncryptedSearchService.EncryptedSearchIndexState.disabled)
        XCTAssertFalse(EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.testUserID))
        XCTAssertFalse(EncryptedSearchService.shared.indexBuildingInProgress)
    }

    // Private Function
    /* func testUpdateMessageMetadataInSearchIndex() throws {
        //TODO
    } */

    // Private Function
    /* func testUpdateCurrentUserIfNeeded() throws {
        //TODO
    } */

    // Private Function
    /* func testGetTotalMessages() throws {
        //TODO
    } */

    func testConvertMessageToESMessage() throws {
        //TODO
    }

    // Private function
    /* func testJsonStringToESMessage() throws {
        //TODO
    } */

    // Private function
    /* func testParseMessageResponse() throws {
        //TODO
    } */

    // Private function
    /* func testParseMessageDetailResponse() throws {
        //TODO
    } */

    // Private function
    /* func testFetchSingleMessageFromServer() throws {
        //TODO
    } */

    func testFetchMessages() throws {
        //TODO
    }

    func testFetchMessageDetailForMessage() throws {
        //TODO
    }

    // Private Function
    /* func testDownloadAndProcessPage() throws {
        //TODO
    } */

    // Private function
    /* func testDownloadPage() throws {
        //TODO
    } */

    func testProcessPageOneByOne() throws {
        //TODO
    }

    func testGetMessageDetailsForSingleMessage() throws {
        //TODO
    }

    // TODO remove?
    //func testParseMessageObjectFromResponse() throws {
        //TODO
    //}

    // Private function
    /* func testGetMessage() throws {
        //TODO
    } */

    func testDecryptBodyIfNeeded() throws {
        //TODO
    }

    func testDecryptAndExtractDataSingleMessage() throws {
        //TODO
    }

    func testCreateEncryptedContent() throws {
        //TODO
    }

    // Private function
    /*func testGetCipher() throws {
        let sut = EncryptedSearchService.shared.getCipher

        let result: EncryptedsearchAESGCMCipher = sut(self.testUserID)

        let testKey = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + self.testUserID)
        let cipher = EncryptedsearchAESGCMCipher(testKey!)

        //XCTAssertEqual(result.)
        //TODO
    }*/

    // Private function
    /*func testGenerateSearchIndexKey() throws {
        let sut = EncryptedSearchService.shared.generateSearchIndexKey

        let result: Data? = sut(self.testUserID)
        
        XCTAssertEqual(result!.count, 32)   // should be 32 byte
        XCTAssertFalse(result!.isEmpty)     // should be false
        
        let decoded = Data(base64Encoded: result!)  // check if the result is base64
        XCTAssertNil(decoded)   // should not be nil
    }*/

    // Private function
    /* func testStoreSearchIndexKey() throws {
        //TODO
    } */

    // Private function
    /* func testRetrieveSearchIndexKey() throws {
        //TODO
    } */

    func testAddMessageKewordsToSearchIndex() throws {
        //TODO
    }

    func testSlowDownIndexing() throws {
        //TODO
    }

    func testSpeedUpIndexing() throws {
        //TODO
    }

    func testSearch() throws {
        //TODO
    }

    // Private function
    /* func testHasSearchedBefore() throws {
        //TODO
    } */

    func testClearSearchState() throws {
        //TODO
    }

    // Private function
    /* func testGetSearcher() throws {
        let sut = EncryptedSearchService.shared.getSearcher
        let testQuery: String = "test query"
        let result: EncryptedsearchSimpleSearcher = sut(testQuery)

        let testStringList: EncryptedsearchStringList = EncryptedSearchService.shared.createEncryptedSearchStringList(testQuery)
        let testSearcher = EncryptedsearchSimpleSearcher(testStringList, contextSize: 50)
        //XCTAssertEqual(result, testSearcher)
        //TODO how to test this?
    } */

    // Private function
    /* func testCreateEncryptedSearchStringList() throws {
        let sut = EncryptedSearchService.shared.createEncryptedSearchStringList
        let testQuery: String = "test query"
        let result: EncryptedsearchStringList = sut(testQuery)

        XCTAssertEqual(result.length(), 2)
        XCTAssertEqual(result.get(0, error: nil), "test")
        XCTAssertEqual(result.get(1, error: nil), "query")
    } */

    // Private function
    /* func testGetCache() throws {
        let sut = EncryptedSearchService.shared.getCache

        let testKey = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + self.testUserID)
        let cipher = EncryptedsearchAESGCMCipher(testKey!)
        let result: EncryptedsearchCache = sut(cipher!, self.testUserID)

        let dbParams = EncryptedSearchIndexService.shared.getDBParams(self.testUserID)
        let cache: EncryptedsearchCache = EncryptedSearchCacheService.shared.buildCacheForUser(userId: self.testUserID, dbParams: dbParams, cipher: cipher!)

        XCTAssertTrue(result.isBuilt())
        XCTAssertEqual(result.getLength(), cache.getLength())
    } */

    // Private function
    /* func testExtractSearchResults() throws {
        //TODO
    } */

    // Private function
    /* func testDoIndexSearch() throws {
        //TODO
    } */

    // Private function
    /* func testGetIndex() throws {
        //TODO
    } */

    // Private function
    /* func testDoCachedSearch() throws {
        //TODO
    } */

    // Private function
    /* func testPublishIntermediateResults() throws {
        //TODO
    } */

    // Private function
    /* func testContinueIndexingInBackground() throws {
        //TODO
    } */

    // Private function
    /* func testEndBackgroundTask() throws {
        //TODO
    } */

    func testRegisterBGProcessingTask() throws {
        //TODO
    }

    // Private function
    /* func testCancelBGProcessingTask() throws {
        //TODO
    } */

    // Private function
    /* func testScheduleNewBGProcessingTask() throws {
        //TODO
    } */

    // Private function
    /* func testBgProcessingTask() throws {
        //TODO
    } */

    func testRegisterBGAppRefreshTask() throws {
        //TODO
    }

    // Private function
    /* func testCancelBGAppRefreshTask() throws {
        //TODO
    } */

    // Private function
    /* func testScheduleNewAppRefreshTask() throws {
        //TODO
    } */

    // Private function
    /* func testAppRefreshTask() throws {
        //TODO
    } */

    // Private function
    /* func testSendIndexingMetrics() throws {
        //TODO
    } */

    // Private function
    /* func testSendSearchMetrics() throws {
        //TODO
    } */

    // Private function
    /* func testSendMetrics() throws {
        //TODO
    } */

    // Private function
    /* func testSendNotification() throws {
        //TODO
    } */

    // Private function
    /* func testAppMovedToBackground() throws {
        //TODO
    } */

    // Private function
    /* func testCheckIfEnoughStorage() throws {
        //TODO
    } */

    // Private function
    /* func testEstimateIndexingTime() throws {
        //TODO
    } */

    // Private function
    /* func testUpdateRemainingIndexingTime() throws {
        //TODO
    } */

    // Private function
    /* func testRegisterForBatteryLevelChangeNotifications() throws {
        //TODO
    } */

    // Private function
    /* func testRegisterForPowerStateChangeNotifications() throws {
        //TODO
    } */

    // Private function
    /* func testResponseToLowPowerMode() throws {
        //TODO
    } */

    // Private function
    /* func testResponseToBatteryLevel() throws {
        //TODO
    } */

    // Private function
    /* func testRegisterForTermalStateChangeNotifications() throws {
        //TODO
    } */

    // Private function
    /* func testResponseToHeat() throws {
        //TODO
    } */

    func testGetTotalAvailableMemory() throws {
        //TODO
    }

    // Private function
    /* func testGetCurrentlyAvailableAppMemory() throws {
        //TODO
    } */

    // Private function
    /* func testUpdateIndexBuildingProgress() throws {
        //TODO
    } */

    // TODO remove?
    /*func testUpdateUIWithProgressBarStatus() throws {
        //TODO
    }*/

    // Private function
    /* func testUpdateUIWithIndexingStatus() throws {
        //TODO
    } */

    // Private function
    /* func testUpdateUIIndexingComplete() throws {
        //TODO
    } */
}
