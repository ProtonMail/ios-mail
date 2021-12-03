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
@testable import ProtonMail

class EncryptedSearchTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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

    func testPauseAndResumeIndexing() throws {
        //TODO
    }

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
        //TODO
    }

    func testUpdateMessageMetadataInSearchIndex() throws {
        //TODO
    }

    func testUpdateCurrentUserIfNeeded() throws {
        //TODO
    }

    func testGetTotalMessages() throws {
        //TODO
    }

    func testConvertMessageToESMessage() throws {
        //TODO
    }

    func testJsonStringToESMessage() throws {
        //TODO
    }

    func testParseMessageResponse() throws {
        //TODO
    }

    func testParseMessageDetailResponse() throws {
        //TODO
    }

    func testFetchSingleMessageFromServer() throws {
        //TODO
    }

    func testFetchMessages() throws {
        //TODO
    }

    func testFetchMessageDetailForMessage() throws {
        //TODO
    }

    func testDownloadAndProcessPage() throws {
        //TODO
    }

    func testDownloadPage() throws {
        //TODO
    }

    func testProcessPageOneByOne() throws {
        //TODO
    }

    func testGetMessageDetailsForSingleMessage() throws {
        //TODO
    }

    func testParseMessageObjectFromResponse() throws {
        //TODO
    }

    func testGetMessage() throws {
        //TODO
    }

    func testDecryptBodyIfNeeded() throws {
        //TODO
    }

    func testDecryptAndExtractDataSingleMessage() throws {
        //TODO
    }

    func testCreateEncryptedContent() throws {
        //TODO
    }

    func testGetCipher() throws {
        //TODO
    }

    func testGenerateSearchIndexKey() throws {
        //TODO
    }

    func testStoreSearchIndexKey() throws {
        //TODO
    }

    func testRetrieveSearchIndexKey() throws {
        //TODO
    }

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

    func testHasSearchedBefore() throws {
        //TODO
    }

    func testClearSearchState() throws {
        //TODO
    }

    func testGetSearcher() throws {
        //TODO
    }

    func testCreateEncryptedSearchStringList() throws {
        //TODO
    }

    func testGetCache() throws {
        //TODO
    }

    func testExtractSearchResults() throws {
        //TODO
    }

    func testDoIndexSearch() throws {
        //TODO
    }

    func testGetIndex() throws {
        //TODO
    }

    func testDoCachedSearch() throws {
        //TODO
    }

    func testPublishIntermediateResults() throws {
        //TODO
    }

    func testContinueIndexingInBackground() throws {
        //TODO
    }

    func testEndBackgroundTask() throws {
        //TODO
    }

    func testRegisterBGProcessingTask() throws {
        //TODO
    }

    func testCancelBGProcessingTask() throws {
        //TODO
    }

    func testScheduleNewBGProcessingTask() throws {
        //TODO
    }

    func testBgProcessingTask() throws {
        //TODO
    }

    func testRegisterBGAppRefreshTask() throws {
        //TODO
    }

    func testCancelBGAppRefreshTask() throws {
        //TODO
    }

    func testScheduleNewAppRefreshTask() throws {
        //TODO
    }

    func testAppRefreshTask() throws {
        //TODO
    }

    func testSendIndexingMetrics() throws {
        //TODO
    }

    func testSendSearchMetrics() throws {
        //TODO
    }

    func testSendMetrics() throws {
        //TODO
    }

    func testSendNotification() throws {
        //TODO
    }

    func testAppMovedToBackground() throws {
        //TODO
    }

    func testCheckIfEnoughStorage() throws {
        //TODO
    }

    func testEstimateIndexingTime() throws {
        //TODO
    }

    func testUpdateRemainingIndexingTime() throws {
        //TODO
    }

    func testRegisterForBatteryLevelChangeNotifications() throws {
        //TODO
    }

    func testRegisterForPowerStateChangeNotifications() throws {
        //TODO
    }

    func testResponseToLowPowerMode() throws {
        //TODO
    }

    func testResponseToBatteryLevel() throws {
        //TODO
    }

    func testRegisterForTermalStateChangeNotifications() throws {
        //TODO
    }

    func testResponseToHeat() throws {
        //TODO
    }

    func testGetTotalAvailableMemory() throws {
        //TODO
    }

    func testGetCurrentlyAvailableAppMemory() throws {
        //TODO
    }

    func testUpdateIndexBuildingProgress() throws {
        //TODO
    }

    func testUpdateUIWithProgressBarStatus() throws {
        //TODO
    }

    func testUpdateUIWithIndexingStatus() throws {
        //TODO
    }

    func testUpdateUIIndexingComplete() throws {
        //TODO
    }
}
