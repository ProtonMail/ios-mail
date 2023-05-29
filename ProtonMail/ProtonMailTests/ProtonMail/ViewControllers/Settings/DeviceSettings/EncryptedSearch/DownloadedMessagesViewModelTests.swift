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

import XCTest
@testable import ProtonMail
import ProtonCore_TestingToolkit

final class DownloadedMessagesViewModelTests: XCTestCase {
    private var sut: DownloadedMessagesViewModel!
    private var mockRouter: MockDownloadedMessagesRouterProtocol!
    private var mockSearchDeviceCache: MockEncryptedSearchDeviceCache!
    private var mockUserCache: MockEncryptedSearchUserCache!
    private var mockEncryptedSearchService: MockEncryptedSearchServiceProtocol!
    private var mockUIDelegate: MockDownloadedMessagesUIProtocol!
    private let dummyUserID: UserID = UserID(rawValue: UUID().uuidString)

    override func setUp() {
        super.setUp()
        mockRouter = .init()
        mockSearchDeviceCache = .init()
        mockUserCache = .init()
        mockEncryptedSearchService = .init()
        mockUIDelegate = .init()
        let dependencies = DownloadedMessagesViewModel.Dependencies(
            userID: dummyUserID,
            esDeviceCache: mockSearchDeviceCache,
            esUserCache: mockUserCache,
            esService: mockEncryptedSearchService
        )
        sut = DownloadedMessagesViewModel(
            router: mockRouter,
            searchIndexState: .complete,
            dependencies: dependencies
        )
        sut.setUIDelegate(mockUIDelegate)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockRouter = nil
        mockUIDelegate = nil
    }

    func testInput_didChangeStorageLimitValue_whenValueIsPositive_itStoresTheValue() {
        let newValue = Measurement<UnitInformationStorage>.randomBytesPositiveValue
        sut.input.didChangeStorageLimitValue(newValue: newValue)
        XCTAssertEqual(mockSearchDeviceCache.storageLimitStub.setLastArguments?.value, newValue)
    }

    func testInput_didChangeStorageLimitValue_whenValueIsNegative_itDoesNotStoreTheNewValue() {
        let newValue = Measurement<UnitInformationStorage>.randomBytesNegativeValue
        sut.input.didChangeStorageLimitValue(newValue: newValue)
        XCTAssertEqual(mockSearchDeviceCache.storageLimitStub.setCallCounter, 0)
    }

    func testInput_didTapClearStorageUsed() {
        sut.input.didTapClearStorageUsed()

        XCTAssertEqual(mockUserCache.setIsEncryptedSearchOnStub.lastArguments?.a1.rawValue, dummyUserID.rawValue)
        XCTAssertEqual(mockUserCache.setIsEncryptedSearchOnStub.lastArguments?.a2, false)
        XCTAssertEqual(mockEncryptedSearchService.stopBuildingIndexStub.callCounter, 1)
        XCTAssertEqual(mockRouter.closeViewStub.callCounter, 1)
    }

    func testOutput_storageLimitSelected() {
        let value = Measurement<UnitInformationStorage>.randomBytesPositiveValue
        mockSearchDeviceCache.storageLimitStub.fixture = value
        XCTAssertEqual(sut.output.storageLimitSelected, value)
    }

    func testOutput_localStorageUsed() {
        let value = Measurement<UnitInformationStorage>.randomBytesPositiveValue
        mockEncryptedSearchService.indexSizeStub.bodyIs { _, _ in
            value
        }
        XCTAssertEqual(sut.output.localStorageUsed, value)
    }

}
