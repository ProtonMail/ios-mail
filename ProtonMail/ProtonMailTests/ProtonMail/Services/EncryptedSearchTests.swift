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

class EncryptedSearchTests: XCTestCase {
    var testUserID: String!
    var testMessageID: String!
    var testSearchIndexDBName: String!
    var connectionToSearchIndexDB: Connection!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.testUserID = "test"
        self.testMessageID = "uniqueID1"

        // Create a test search index for user 'test'
        self.createTestSearchIndexDB()
        let doesTestIndexExist: Bool = EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.testUserID)
        print("Test database created: \(doesTestIndexExist)")
        let numberOfEntries = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
        print("Entries in db: \(numberOfEntries)")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        // Delete test search index for user 'test'
        try self.deleteTestSearchIndexDB()
    }

    func createTestSearchIndexDB(){
        self.testSearchIndexDBName = "encryptedSearchIndex_test.sqlite3"
        self.connectionToSearchIndexDB = EncryptedSearchIndexService.shared.connectToSearchIndex(for: self.testUserID)!
        EncryptedSearchIndexService.shared.createSearchIndexTable(using: self.connectionToSearchIndexDB)

        let testMessage: ESMessage = ESMessage(id: self.testMessageID, order: 1, conversationID: "", subject: "subject", unread: 1, type: 1, senderAddress: "sender", senderName: "sender", sender: ESSender(Name: "sender", Address: "address"), toList: [], ccList: [], bccList: [], time: 1637058775, size: 5, isEncrypted: 1, expirationTime: Date(), isReplied: 0, isRepliedAll: 0, isForwarded: 0, spamScore: 0, addressID: "", numAttachments: 0, flags: 0, labelIDs: ["5", "1"], externalID: "", body: "hello", header: "", mimeType: "", userID: self.testUserID)
        let testMessageSecond: ESMessage = ESMessage(id: "uniqueID2", order: 2, conversationID: "", subject: "subject", unread: 1, type: 1, senderAddress: "sender", senderName: "sender", sender: ESSender(Name: "sender", Address: "address"), toList: [], ccList: [], bccList: [], time: 1637141557, size: 5, isEncrypted: 1, expirationTime: Date(), isReplied: 0, isRepliedAll: 0, isForwarded: 0, spamScore: 0, addressID: "", numAttachments: 0, flags: 0, labelIDs: ["5", "1"], externalID: "", body: "hello2", header: "", mimeType: "", userID: self.testUserID)
        let encryptedContent: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: testMessage, cleanedBody: "hello", userID: self.testUserID)
        let encryptedContent2: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: testMessageSecond, cleanedBody: "hello2", userID: self.testUserID)
        EncryptedSearchService.shared.addMessageKewordsToSearchIndex(testUserID, testMessage, encryptedContent, false)
        EncryptedSearchService.shared.addMessageKewordsToSearchIndex(testUserID, testMessageSecond, encryptedContent2, false)
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

    func testEncryptedSearchServiceSingleton() throws {
        XCTAssertNotNil(EncryptedSearchService.shared)
    }

    func testDetermineEncryptedSearchState() throws {
        /*let sut = EncryptedSearchIndexService.shared.getSearchIndexName
        let testUserID: String = "123"
        let result: String = sut(testUserID)

        XCTAssertEqual(result, "encryptedSearchIndex_123.sqlite3")*/
        //TODO
    }

    func testBuildSearchIndex() throws {
        //TODO
        
    }

    func testCheckIfIndexingIsComplete() throws {
        //TODO
    }

    func testCleanUpAfterIndexing() throws {
        //TODO
    }

    func testPauseAndResumeIndexingByUser() throws {
        //TODO
    }

    func testPauseAndResumeIndexingDueToInterruption() throws {
        //TODO
    }

    // Private Function
    /*func testPauseAndResumeIndexing() throws {
        //TODO
    }*/

    func testPauseIndexingDueToNetworkSwitch() throws {
        //TODO
    }

    func testUpdateSearchIndex() throws {
        //TODO
    }

    func testProcessEventsAfterIndexing() throws {
        //TODO
    }

    func testInsertSingleMessageToSearchIndex() throws {
        //TODO
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
