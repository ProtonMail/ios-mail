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

@testable import ProtonMail
import XCTest

final class EncryptedSearchUserDefaultCacheTests: XCTestCase {
    var sut: EncryptedSearchUserDefaultCache!
    var userDefaults: UserDefaults!
    let suiteName = String.randomString(10)
    let userID = UserID(String.randomString(10))
    let userID2 = UserID(String.randomString(10))

    override func setUp() {
        super.setUp()

        userDefaults = .init(suiteName: suiteName)!
        sut = .init(userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()
        userDefaults.removePersistentDomain(forName: suiteName)
        sut = nil
        userDefaults = nil
    }

    func testIsEncryptedSearchOn() {
        XCTAssertFalse(sut.isEncryptedSearchOn(of: userID))
        XCTAssertFalse(sut.isEncryptedSearchOn(of: userID2))

        sut.setIsEncryptedSearchOn(of: userID, value: true)
        XCTAssertTrue(sut.isEncryptedSearchOn(of: userID))
        XCTAssertFalse(sut.isEncryptedSearchOn(of: userID2))

        sut.setIsEncryptedSearchOn(of: userID2, value: true)
        XCTAssertTrue(sut.isEncryptedSearchOn(of: userID))
        XCTAssertTrue(sut.isEncryptedSearchOn(of: userID2))
    }

    func testCanDownloadViaMobileData() {
        XCTAssertFalse(sut.canDownloadViaMobileData(of: userID))
        XCTAssertFalse(sut.canDownloadViaMobileData(of: userID2))

        sut.setCanDownloadViaMobileData(of: userID, value: true)
        XCTAssertTrue(sut.canDownloadViaMobileData(of: userID))
        XCTAssertFalse(sut.canDownloadViaMobileData(of: userID2))

        sut.setCanDownloadViaMobileData(of: userID2, value: true)
        XCTAssertTrue(sut.canDownloadViaMobileData(of: userID))
        XCTAssertTrue(sut.canDownloadViaMobileData(of: userID2))
    }

    func testIsAppFreshInstalled() {
        XCTAssertFalse(sut.isAppFreshInstalled(of: userID))
        XCTAssertFalse(sut.isAppFreshInstalled(of: userID2))

        sut.setIsAppFreshInstalled(of: userID, value: true)
        XCTAssertTrue(sut.isAppFreshInstalled(of: userID))
        XCTAssertFalse(sut.isAppFreshInstalled(of: userID2))

        sut.setIsAppFreshInstalled(of: userID2, value: true)
        XCTAssertTrue(sut.isAppFreshInstalled(of: userID))
        XCTAssertTrue(sut.isAppFreshInstalled(of: userID2))
    }

    func testTotalMessages() {
        XCTAssertEqual(sut.totalMessages(of: userID), 0)
        XCTAssertEqual(sut.totalMessages(of: userID2), 0)

        sut.setTotalMessages(of: userID, value: 1)
        XCTAssertEqual(sut.totalMessages(of: userID), 1)
        XCTAssertEqual(sut.totalMessages(of: userID2), 0)

        sut.setTotalMessages(of: userID2, value: 10)
        XCTAssertEqual(sut.totalMessages(of: userID), 1)
        XCTAssertEqual(sut.totalMessages(of: userID2), 10)
    }

    func testLastIndexedMessageID() {
        XCTAssertNil(sut.lastIndexedMessageID(of: userID))
        XCTAssertNil(sut.lastIndexedMessageID(of: userID2))

        let msgID = MessageID(String.randomString(10))
        sut.setLastIndexedMessageID(of: userID, value: msgID)
        XCTAssertEqual(sut.lastIndexedMessageID(of: userID), msgID)
        XCTAssertNil(sut.lastIndexedMessageID(of: userID2))

        let msgID2 = MessageID(String.randomString(10))
        sut.setLastIndexedMessageID(of: userID2, value: msgID2)
        XCTAssertEqual(sut.lastIndexedMessageID(of: userID), msgID)
        XCTAssertEqual(sut.lastIndexedMessageID(of: userID2), msgID2)
    }

    func testProcessedMessagesCount() {
        XCTAssertEqual(sut.processedMessagesCount(of: userID), 0)
        XCTAssertEqual(sut.processedMessagesCount(of: userID2), 0)

        sut.setProcessedMessagesCount(of: userID, value: 1)
        XCTAssertEqual(sut.processedMessagesCount(of: userID), 1)
        XCTAssertEqual(sut.processedMessagesCount(of: userID2), 0)

        sut.setProcessedMessagesCount(of: userID2, value: 10)
        XCTAssertEqual(sut.processedMessagesCount(of: userID), 1)
        XCTAssertEqual(sut.processedMessagesCount(of: userID2), 10)
    }

    func testPreviousProcessedMessagesCount() {
        XCTAssertEqual(sut.previousProcessedMessagesCount(of: userID), 0)
        XCTAssertEqual(sut.previousProcessedMessagesCount(of: userID2), 0)

        sut.setPreviousProcessedMessagesCount(of: userID, value: 1)
        XCTAssertEqual(sut.previousProcessedMessagesCount(of: userID), 1)
        XCTAssertEqual(sut.previousProcessedMessagesCount(of: userID2), 0)

        sut.setPreviousProcessedMessagesCount(of: userID2, value: 10)
        XCTAssertEqual(sut.previousProcessedMessagesCount(of: userID), 1)
        XCTAssertEqual(sut.previousProcessedMessagesCount(of: userID2), 10)
    }

    func testIndexingPausedByUser() {
        XCTAssertFalse(sut.indexingPausedByUser(of: userID))
        XCTAssertFalse(sut.indexingPausedByUser(of: userID2))

        sut.setIndexingPausedByUser(of: userID, value: true)
        XCTAssertTrue(sut.indexingPausedByUser(of: userID))
        XCTAssertFalse(sut.indexingPausedByUser(of: userID2))

        sut.setIndexingPausedByUser(of: userID2, value: true)
        XCTAssertTrue(sut.indexingPausedByUser(of: userID))
        XCTAssertTrue(sut.indexingPausedByUser(of: userID2))
    }

    func testNumberOfPauses() {
        XCTAssertEqual(sut.numberOfPauses(of: userID), 0)
        XCTAssertEqual(sut.numberOfPauses(of: userID2), 0)

        sut.setNumberOfPauses(of: userID, value: 1)
        XCTAssertEqual(sut.numberOfPauses(of: userID), 1)
        XCTAssertEqual(sut.numberOfPauses(of: userID2), 0)

        sut.setNumberOfPauses(of: userID2, value: 10)
        XCTAssertEqual(sut.numberOfPauses(of: userID), 1)
        XCTAssertEqual(sut.numberOfPauses(of: userID2), 10)
    }

    func testNumberOfInterruptions() {
        XCTAssertEqual(sut.numberOfInterruptions(of: userID), 0)
        XCTAssertEqual(sut.numberOfInterruptions(of: userID2), 0)

        sut.setNumberOfInterruptions(of: userID, value: 1)
        XCTAssertEqual(sut.numberOfInterruptions(of: userID), 1)
        XCTAssertEqual(sut.numberOfInterruptions(of: userID2), 0)

        sut.setNumberOfInterruptions(of: userID2, value: 10)
        XCTAssertEqual(sut.numberOfInterruptions(of: userID), 1)
        XCTAssertEqual(sut.numberOfInterruptions(of: userID2), 10)
    }

    func testInitialIndexingTimeEstimated() {
        XCTAssertTrue(sut.initialIndexingTimeEstimated(of: userID))
        XCTAssertTrue(sut.initialIndexingTimeEstimated(of: userID2))

        sut.setInitialIndexingTimeEstimated(of: userID, value: false)
        XCTAssertFalse(sut.initialIndexingTimeEstimated(of: userID))
        XCTAssertTrue(sut.initialIndexingTimeEstimated(of: userID2))

        sut.setInitialIndexingTimeEstimated(of: userID2, value: false)
        XCTAssertFalse(sut.initialIndexingTimeEstimated(of: userID))
        XCTAssertFalse(sut.initialIndexingTimeEstimated(of: userID2))
    }

    func testInitialIndexingEstimationTime() {
        XCTAssertEqual(sut.initialIndexingEstimationTime(of: userID), 0)
        XCTAssertEqual(sut.initialIndexingEstimationTime(of: userID2), 0)

        sut.setInitialIndexingEstimationTime(of: userID, value: 1)
        XCTAssertEqual(sut.initialIndexingEstimationTime(of: userID), 1)
        XCTAssertEqual(sut.initialIndexingEstimationTime(of: userID2), 0)

        sut.setInitialIndexingEstimationTime(of: userID2, value: 10)
        XCTAssertEqual(sut.initialIndexingEstimationTime(of: userID), 1)
        XCTAssertEqual(sut.initialIndexingEstimationTime(of: userID2), 10)
    }

    func testIndexStartTime() {
        XCTAssertEqual(sut.indexStartTime(of: userID), CFAbsoluteTimeGetCurrent(), accuracy: 0.1)
        XCTAssertEqual(sut.indexStartTime(of: userID2), CFAbsoluteTimeGetCurrent(), accuracy: 0.1)

        sut.setIndexStartTime(of: userID, value: 9999.9)
        XCTAssertEqual(sut.indexStartTime(of: userID), 9999.9)
        XCTAssertEqual(sut.indexStartTime(of: userID2), CFAbsoluteTimeGetCurrent(), accuracy: 0.1)

        sut.setIndexStartTime(of: userID2, value:  6666.6)
        XCTAssertEqual(sut.indexStartTime(of: userID), 9999.9)
        XCTAssertEqual(sut.indexStartTime(of: userID2), 6666.6)
    }

    func testIsExternalRefreshed() {
        XCTAssertFalse(sut.isExternalRefreshed(of: userID))
        XCTAssertFalse(sut.isExternalRefreshed(of: userID2))

        sut.setIsExternalRefreshed(of: userID, value: true)
        XCTAssertTrue(sut.isExternalRefreshed(of: userID))
        XCTAssertFalse(sut.isExternalRefreshed(of: userID2))

        sut.setIsExternalRefreshed(of: userID2, value: true)
        XCTAssertTrue(sut.isExternalRefreshed(of: userID))
        XCTAssertTrue(sut.isExternalRefreshed(of: userID2))
    }

    func testStorageLimit() {
        XCTAssertEqual(sut.storageLimit, Constants.EncryptedSearch.defaultStorageLimit)

        let newValue = 1000
        sut.storageLimit = newValue

        XCTAssertEqual(sut.storageLimit, 1000)
    }

    func testPauseIndexingDueToNetworkIssues() {
        XCTAssertFalse(sut.pauseIndexingDueToNetworkIssues)

        sut.pauseIndexingDueToNetworkIssues = true

        XCTAssertTrue(sut.pauseIndexingDueToNetworkIssues)
    }

    func testPauseIndexingDueToWifiNotDetected() {
        XCTAssertFalse(sut.pauseIndexingDueToWifiNotDetected)

        sut.pauseIndexingDueToWifiNotDetected = true

        XCTAssertTrue(sut.pauseIndexingDueToWifiNotDetected)
    }

    func testPauseIndexingDueToOverHeating() {
        XCTAssertFalse(sut.pauseIndexingDueToOverHeating)

        sut.pauseIndexingDueToOverHeating = true

        XCTAssertTrue(sut.pauseIndexingDueToOverHeating)
    }

    func testPauseIndexingDueToLowBattery() {
        XCTAssertFalse(sut.pauseIndexingDueToLowBattery)

        sut.pauseIndexingDueToLowBattery = true

        XCTAssertTrue(sut.pauseIndexingDueToLowBattery)
    }

    func testInterruptStatus() {
        XCTAssertNil(sut.interruptStatus)

        let newValue = String.randomString(20)
        sut.interruptStatus = newValue

        XCTAssertEqual(sut.interruptStatus, newValue)
    }

    func testInterruptAdvice() {
        XCTAssertNil(sut.interruptAdvice)

        let newValue = String.randomString(20)
        sut.interruptAdvice = newValue

        XCTAssertEqual(sut.interruptAdvice, newValue)
    }

    func testCleanGlobal() {
        sut.storageLimit = 100
        sut.pauseIndexingDueToNetworkIssues = true
        sut.pauseIndexingDueToLowBattery = true
        sut.pauseIndexingDueToOverHeating = true
        sut.pauseIndexingDueToWifiNotDetected = true
        sut.interruptStatus = String.randomString(10)
        sut.interruptAdvice = String.randomString(10)

        sut.cleanGlobal()

        XCTAssertEqual(sut.storageLimit, Constants.EncryptedSearch.defaultStorageLimit)
        XCTAssertFalse(sut.pauseIndexingDueToNetworkIssues)
        XCTAssertFalse(sut.pauseIndexingDueToLowBattery)
        XCTAssertFalse(sut.pauseIndexingDueToOverHeating)
        XCTAssertFalse(sut.pauseIndexingDueToWifiNotDetected)
        XCTAssertNil(sut.interruptStatus)
        XCTAssertNil(sut.interruptAdvice)
    }

    func testLogout() {
        sut.setIsEncryptedSearchOn(of: userID, value: true)
        sut.setCanDownloadViaMobileData(of: userID, value: true)
        sut.setIsAppFreshInstalled(of: userID, value: true)
        sut.setTotalMessages(of: userID, value: 100)
        sut.setLastIndexedMessageID(of: userID, value: .init(String.randomString(10)))
        sut.setProcessedMessagesCount(of: userID, value: 5)
        sut.setPreviousProcessedMessagesCount(of: userID, value: 3)
        sut.setIndexingPausedByUser(of: userID, value: true)
        sut.setNumberOfPauses(of: userID, value: 4)
        sut.setNumberOfInterruptions(of: userID, value: 6)

        sut.setInitialIndexingTimeEstimated(of: userID, value: true)
        sut.setInitialIndexingEstimationTime(of: userID, value: 7)
        sut.setIndexStartTime(of: userID, value: 1000)
        sut.setIsExternalRefreshed(of: userID, value: true)

        sut.logout(of: userID)

        XCTAssertFalse(sut.isEncryptedSearchOn(of: userID))
        XCTAssertFalse(sut.canDownloadViaMobileData(of: userID))
        XCTAssertFalse(sut.isAppFreshInstalled(of: userID))
        XCTAssertEqual(sut.totalMessages(of: userID), 0)
        XCTAssertNil(sut.lastIndexedMessageID(of: userID))
        XCTAssertEqual(sut.processedMessagesCount(of: userID), 0)
        XCTAssertEqual(sut.previousProcessedMessagesCount(of: userID), 0)
        XCTAssertFalse(sut.indexingPausedByUser(of: userID))
        XCTAssertEqual(sut.numberOfPauses(of: userID), 0)
        XCTAssertEqual(sut.numberOfInterruptions(of: userID), 0)
        XCTAssertTrue(sut.initialIndexingTimeEstimated(of: userID))
        XCTAssertEqual(sut.initialIndexingEstimationTime(of: userID), 0)
        XCTAssertEqual(sut.indexStartTime(of: userID), CFAbsoluteTimeGetCurrent(), accuracy: 0.1)
        XCTAssertFalse(sut.isExternalRefreshed(of: userID))
    }
}
