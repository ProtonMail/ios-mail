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

final class SettingsEncryptedSearchViewModelTests: XCTestCase {
    private var sut: SettingsEncryptedSearchViewModel!
    private var mockRouter: MockSettingsEncryptedSearchRouterProtocol!
    private var mockUserCache: MockEncryptedSearchUserCache!
    private var mockEncryptedSearchService: MockEncryptedSearchServiceProtocol!
    private var mockUIDelegate: MockSettingsEncryptedSearchUIProtocol!
    private let dummyLocale = Locale.enUS
    private let dummyTimeZone = TimeZone.init(secondsFromGMT: 0)!

    private let dummyUserID: UserID = UserID(rawValue: UUID().uuidString)

    override func setUp() {
        super.setUp()
        mockRouter = MockSettingsEncryptedSearchRouterProtocol()
        mockUserCache = MockEncryptedSearchUserCache()
        mockEncryptedSearchService = MockEncryptedSearchServiceProtocol()
        mockUIDelegate = MockSettingsEncryptedSearchUIProtocol()
        sut = SettingsEncryptedSearchViewModel(
            router: mockRouter,
            dependencies: .init(
                userID: dummyUserID,
                esUserCache: mockUserCache,
                esService: mockEncryptedSearchService,
                locale: dummyLocale,
                timeZone: dummyTimeZone
            )
        )
        sut.setUIDelegate(mockUIDelegate)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockRouter = nil
        mockUserCache = nil
        mockEncryptedSearchService = nil
        mockUIDelegate = nil
    }

    func testInput_viewWillAppear() {
        sut.input.viewWillAppear()
        XCTAssertEqual(mockEncryptedSearchService.setBuildSearchIndexDelegateStub.callCounter, 1)
        XCTAssertEqual(mockUIDelegate.reloadDataStub.callCounter, 1)
    }

    func testInput_didChangeEncryptedSearchValue_whenEncryptedSearchIsEnabled_andDownloadIsInProgress() {
        let isESEnabled = true
        mockUserCache.isEncryptedSearchOnStub.bodyIs { _, _ in
            isESEnabled
        }
        mockEncryptedSearchService.indexBuildingStateStub.bodyIs { _, _ in
            [EncryptedSearchIndexState.downloadingNewMessage, EncryptedSearchIndexState.creatingIndex].randomElement()!
        }

        sut.input.didChangeEncryptedSearchValue(isNewStatusEnabled: isESEnabled)
        XCTAssert(sut.output.sections == [.encryptedSearchFeature, .downloadViaMobileData, .downloadProgress])
        XCTAssertEqual(mockEncryptedSearchService.startBuildingIndexStub.callCounter, 1)
        XCTAssertEqual(mockUIDelegate.reloadDataStub.callCounter, 1)
    }

    func testInput_didChangeEncryptedSearchValue_whenEncryptedSearchIsEnabled_andDownloadIsNotInProgress() {
        let isESEnabled = true
        mockUserCache.isEncryptedSearchOnStub.bodyIs { _, _ in
            isESEnabled
        }
        mockEncryptedSearchService.indexBuildingStateStub.bodyIs { _, _ in
            EncryptedSearchIndexState.complete
        }

        sut.input.didChangeEncryptedSearchValue(isNewStatusEnabled: isESEnabled)
        XCTAssert(sut.output.sections == [.encryptedSearchFeature, .downloadViaMobileData, .downloadedMessages])
        XCTAssertEqual(mockEncryptedSearchService.startBuildingIndexStub.callCounter, 1)
        XCTAssertEqual(mockUIDelegate.reloadDataStub.callCounter, 1)
    }

    func testInput_didChangeEncryptedSearchValue_whenEncryptedSearchIsDisabled() {
        let isESEnabled = false
        mockUserCache.isEncryptedSearchOnStub.bodyIs { _, _ in
            isESEnabled
        }
        mockEncryptedSearchService.indexBuildingStateStub.bodyIs { _, _ in
            EncryptedSearchIndexState.allCases.randomElement()!
        }

        sut.input.didChangeEncryptedSearchValue(isNewStatusEnabled: isESEnabled)
        XCTAssert(sut.output.sections == [.encryptedSearchFeature])
        XCTAssertEqual(mockEncryptedSearchService.stopBuildingIndexStub.callCounter, 1)
        XCTAssertEqual(mockUIDelegate.reloadDataStub.callCounter, 1)
    }

    func testInput_didChangeUseMobileDataValue_whenMobileDataIsEnabled() {
        sut.input.didChangeUseMobileDataValue(isNewStatusEnabled: true)
        XCTAssertEqual(mockUserCache.setCanDownloadViaMobileDataStub.callCounter, 1)
        XCTAssertTrue(mockUserCache.setCanDownloadViaMobileDataStub.lastArguments?.second == true)
        XCTAssertEqual(mockEncryptedSearchService.didChangeDownloadViaMobileDataStub.callCounter, 1)
    }

    func testInput_didChangeUseMobileDataValue_whenMobileDataIsDisabled() {
        sut.input.didChangeUseMobileDataValue(isNewStatusEnabled: false)
        XCTAssertEqual(mockUserCache.setCanDownloadViaMobileDataStub.callCounter, 1)
        XCTAssertTrue(mockUserCache.setCanDownloadViaMobileDataStub.lastArguments?.second == false)
        XCTAssertEqual(mockEncryptedSearchService.didChangeDownloadViaMobileDataStub.callCounter, 1)
    }

    func testInput_didTapDownloadedMessages() {
        mockEncryptedSearchService.indexBuildingStateStub.bodyIs { _, _ in
            [EncryptedSearchIndexState.complete, .creatingIndex, .downloadingNewMessage].randomElement()!
        }
        sut.input.didTapDownloadedMessages()
        XCTAssertEqual(mockRouter.navigateToDownloadedMessagesStub.callCounter, 1)
    }

    func testInput_didTapPauseMessagesDownload() {
        sut.input.didTapPauseMessagesDownload()
        XCTAssertEqual(mockEncryptedSearchService.pauseBuildingIndexStub.callCounter, 1)
    }

    func testInput_didTapResumeMessagesDownload() {
        sut.input.didTapResumeMessagesDownload()
        XCTAssertEqual(mockEncryptedSearchService.resumeBuildingIndexStub.callCounter, 1)
    }

    func testOutput_searchIndexState() {
        let dummyState = EncryptedSearchIndexState.allCases.randomElement()!
        mockEncryptedSearchService.indexBuildingStateStub.bodyIs { _, _ in
            dummyState
        }
        XCTAssert(sut.output.searchIndexState == dummyState)
    }

    func testOutput_isEncryptedSearchEnabled() {
        let dummyValue = Bool.random()
        mockUserCache.isEncryptedSearchOnStub.bodyIs { _, _ in
            dummyValue
        }
        XCTAssert(sut.output.isEncryptedSearchEnabled == dummyValue)
    }

    func testOutput_isUseMobileDataEnabled() {
        let dummyValue = Bool.random()
        mockUserCache.canDownloadViaMobileDataStub.bodyIs { _, _ in
            dummyValue
        }
        XCTAssert(sut.output.isUseMobileDataEnabled == dummyValue)
    }

    func testOutput_downloadMessageInfo_itParsesTheDataCorrectly() {
        mockEncryptedSearchService.oldesMessageTimeStub.bodyIs { _, _ in
            1644858210
        }
        mockEncryptedSearchService.indexSizeStub.bodyIs { _, _ in
            Measurement<UnitInformationStorage>(value: 3080192.0, unit: .bytes) 
        }
        let result = sut.downloadedMessagesInfo
        let expectedSizeResult = String(format: "3%@1 MB", Locale.current.decimalSeparator!)
        XCTAssertEqual(result.indexSize, expectedSizeResult)
        XCTAssertEqual(result.oldesMessageTime, "Feb 14, 2022")
    }
}
