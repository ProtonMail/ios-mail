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

    private let dummyUserID: UserID = UserID(rawValue: UUID().uuidString)

    override func setUp() {
        super.setUp()
        mockRouter = MockSettingsEncryptedSearchRouterProtocol()
        mockUserCache = MockEncryptedSearchUserCache()
        mockEncryptedSearchService = MockEncryptedSearchServiceProtocol()
        mockUIDelegate = MockSettingsEncryptedSearchUIProtocol()
        sut = SettingsEncryptedSearchViewModel(
            router: mockRouter,
            dependencies: .init(userID: dummyUserID, esUserCache: mockUserCache, esService: mockEncryptedSearchService)
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
        let dummyState = EncryptedSearchIndexState.allCases.randomElement()!
        mockEncryptedSearchService.indexBuildingStateStub.bodyIs { _, _ in
            dummyState
        }

        sut.input.viewWillAppear()
        XCTAssertEqual(mockEncryptedSearchService.setBuildSearchIndexDelegateStub.callCounter, 1)
        XCTAssertEqual(mockUIDelegate.updateDownloadStateStub.callCounter, 1)
        XCTAssert(mockUIDelegate.updateDownloadStateStub.lastArguments?.value == dummyState)
    }

    func testInput_didChangeEncryptedSearchValue_whenEncryptedSearchIsEnabled_andDownloadIsInProgress() {
        let isESEnabled = true
        mockUserCache.isEncryptedSearchOnStub.bodyIs { _, _ in
            isESEnabled
        }
        mockEncryptedSearchService.isIndexBuildingInProgressStub.bodyIs { _, _ in
            true
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
        mockEncryptedSearchService.isIndexBuildingInProgressStub.bodyIs { _, _ in
            false
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
        mockEncryptedSearchService.isIndexBuildingInProgressStub.bodyIs { _, _ in
            Bool.random()
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

    func testOutput_isDownloadInProgress() {
        let dummyValue = Bool.random()
        mockEncryptedSearchService.isIndexBuildingInProgressStub.bodyIs { _, _ in
            dummyValue
        }
        XCTAssert(sut.output.isDownloadInProgress == dummyValue)
    }
}
