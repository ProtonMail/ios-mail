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

    func testShouldSendMetric() {
        XCTAssertFalse(sut.shouldSendMetric(of: userID))
        XCTAssertFalse(sut.shouldSendMetric(of: userID2))

        sut.setShouldSendMetric(of: userID, value: true)
        XCTAssertTrue(sut.shouldSendMetric(of: userID))
        XCTAssertFalse(sut.shouldSendMetric(of: userID2))

        sut.setShouldSendMetric(of: userID2, value: true)
        XCTAssertTrue(sut.shouldSendMetric(of: userID))
        XCTAssertTrue(sut.shouldSendMetric(of: userID2))
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

    func testIndexingTime() {
        XCTAssertEqual(sut.indexingTime(of: userID), 0)
        XCTAssertEqual(sut.indexingTime(of: userID2), 0)

        sut.setIndexingTime(of: userID, value: 5)
        XCTAssertEqual(sut.indexingTime(of: userID), 5)
        XCTAssertEqual(sut.indexingTime(of: userID2), 0)

        sut.setIndexingTime(of: userID2, value: 10)
        XCTAssertEqual(sut.indexingTime(of: userID), 5)
        XCTAssertEqual(sut.indexingTime(of: userID2), 10)
    }

    func testIsFirstSearch() {
        XCTAssertTrue(sut.isFirstSearch(of: userID))
        XCTAssertTrue(sut.isFirstSearch(of: userID2))

        sut.hasSearched(of: userID)
        XCTAssertFalse(sut.isFirstSearch(of: userID))
        XCTAssertTrue(sut.isFirstSearch(of: userID2))

        sut.hasSearched(of: userID2)
        XCTAssertFalse(sut.isFirstSearch(of: userID))
        XCTAssertFalse(sut.isFirstSearch(of: userID2))
    }

    func testStorageLimit() {
        XCTAssertEqual(sut.storageLimit, Constants.EncryptedSearch.defaultStorageLimit)

        let newValue = Measurement<UnitInformationStorage>(value: 1.0, unit: .kilobytes)
        sut.storageLimit = newValue

        XCTAssertEqual(sut.storageLimit.converted(to: .bytes).value, 1000.0)
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
        sut.storageLimit = Measurement<UnitInformationStorage>(value: 100.0, unit: .bytes)
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
        sut.setIndexingPausedByUser(of: userID, value: true)
        sut.setNumberOfPauses(of: userID, value: 4)
        sut.setShouldSendMetric(of: userID, value: true)
        sut.setIsExternalRefreshed(of: userID, value: true)
        sut.setNumberOfInterruptions(of: userID, value: 6)
        sut.setIndexingTime(of: userID, value: 99)

        sut.setInitialIndexingEstimationTime(of: userID, value: 7)
        sut.setIsExternalRefreshed(of: userID, value: true)

        sut.logout(of: userID)

        XCTAssertFalse(sut.isEncryptedSearchOn(of: userID))
        XCTAssertFalse(sut.canDownloadViaMobileData(of: userID))
        XCTAssertFalse(sut.indexingPausedByUser(of: userID))
        XCTAssertFalse(sut.shouldSendMetric(of: userID))
        XCTAssertEqual(sut.indexingTime(of: userID), 0)
        XCTAssertFalse(sut.isExternalRefreshed(of: userID))
        XCTAssertEqual(sut.numberOfPauses(of: userID), 0)
        XCTAssertEqual(sut.numberOfInterruptions(of: userID), 0)
        XCTAssertEqual(sut.initialIndexingEstimationTime(of: userID), 0)
        XCTAssertFalse(sut.isExternalRefreshed(of: userID))
    }
}
