// Copyright (c) 2022 Proton Technologies AG
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

final class MockViewModeProvider: ViewModeDataSource {
    var viewModel: ViewMode = .singleMessage
    func getCurrentViewMode() -> ViewMode {
        return viewModel
    }
}

class ScheduleSendLocationStatusObserverTests: XCTestCase {

    var sut: ScheduleSendLocationStatusObserver!
    var contextProviderMock: MockCoreDataContextProvider!
    var userID: UserID = UserID(rawValue: "UserID")
    var viewModeDataSourceMock: MockViewModeProvider!

    override func setUp() {
        super.setUp()
        contextProviderMock = MockCoreDataContextProvider()
        viewModeDataSourceMock = MockViewModeProvider()
        sut = ScheduleSendLocationStatusObserver(contextProvider: contextProviderMock,
                                                 userID: userID,
                                                 viewModelDataSource: viewModeDataSourceMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        contextProviderMock = nil
        viewModeDataSourceMock = nil
    }

    func testObserve_getCountValueFromCoreData() throws {
        generateTestDataInCoreData(total: 100, viewMode: .singleMessage)
        let expectation1 = expectation(description: "Closure should not be called")
        expectation1.isInverted = true

        let result = sut.observe { _ in
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertEqual(result, 100)
    }

    func testObserve_closureBeingCalled_whenTheTotalIsChanged() throws {
        let expectation1 = expectation(description: "Closure is called")

        let result = sut.observe { newValue in
            XCTAssertEqual(newValue, 10)
            expectation1.fulfill()
        }
        XCTAssertEqual(result, 0)
        generateTestDataInCoreData(total: 10, viewMode: .singleMessage)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testObserve_labelCountUpdate_closureGetLatestUpdate() {
        let initialCount: Int32 = 1
        let updateCount = Int32.random(in: Int32.min...Int32.max)
        generateTestDataInCoreData(total: initialCount, viewMode: .singleMessage)
        let expectation1 = expectation(description: "Closure is called")

        let result = sut.observe { newCount in
            XCTAssertEqual(Int32(newCount), max(updateCount, 0))
            expectation1.fulfill()
        }
        XCTAssertEqual(result, Int(initialCount))
        updateTestDataByLabelID(newCount: updateCount, viewMode: .singleMessage)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testObserve_inConversationMode_getCountValueFromCoreData() throws {
        viewModeDataSourceMock.viewModel = .conversation
        generateTestDataInCoreData(total: 100, viewMode: .conversation)
        let expectation1 = expectation(description: "Closure should not be called")
        expectation1.isInverted = true

        let result = sut.observe { _ in
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertEqual(result, 100)
    }

    func testObserve_inConversationMode_closureBeingCalled_whenTheTotalIsChanged() throws {
        viewModeDataSourceMock.viewModel = .conversation
        let expectation1 = expectation(description: "Closure is called")

        let result = sut.observe { newValue in
            XCTAssertEqual(newValue, 10)
            expectation1.fulfill()
        }
        XCTAssertEqual(result, 0)
        generateTestDataInCoreData(total: 10, viewMode: .conversation)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testObserve_conversationCountUpdate_closureGetLatestUpdate() {
        viewModeDataSourceMock.viewModel = .conversation
        let initialCount: Int32 = 1
        let updateCount = Int32.random(in: Int32.min...Int32.max)
        generateTestDataInCoreData(total: initialCount, viewMode: .conversation)
        let expectation1 = expectation(description: "Closure is called")

        let result = sut.observe { newCount in
            XCTAssertEqual(Int32(newCount), max(updateCount, 0))
            expectation1.fulfill()
        }
        XCTAssertEqual(result, Int(initialCount))
        updateTestDataByLabelID(newCount: updateCount, viewMode: .conversation)
        waitForExpectations(timeout: 1, handler: nil)
    }

    private func generateTestDataInCoreData(total: Int32, viewMode: ViewMode) {
        switch viewMode {
        case .conversation:
            let count = ConversationCount.init(context: contextProviderMock.rootSavingContext)
            count.userID = userID.rawValue
            count.total = total
            count.labelID = "12"
        case .singleMessage:
            let labelUpdate = LabelUpdate(context: contextProviderMock.rootSavingContext)
            labelUpdate.userID = userID.rawValue
            labelUpdate.total = total
            labelUpdate.labelID = "12"
        }

        _ = contextProviderMock.rootSavingContext.saveUpstreamIfNeeded()
    }

    private func updateTestDataByLabelID(newCount: Int32, viewMode: ViewMode) {
        switch viewMode {
        case .conversation:
            guard let update = ConversationCount.lastContextUpdate(by: "12", userID: userID.rawValue, inManagedObjectContext: contextProviderMock.rootSavingContext) else {
                XCTFail()
                return
            }
            update.total = newCount
        case .singleMessage:
            guard let update = LabelUpdate.lastUpdate(by: "12",
                                                userID: userID.rawValue,
                                                      inManagedObjectContext: contextProviderMock.rootSavingContext) else {
                XCTFail()
                return
            }
            update.total = newCount
        }
        _ = contextProviderMock.rootSavingContext.saveUpstreamIfNeeded()
    }
}
