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

@testable import ProtonMail
import XCTest

class FetchMessagesTests: XCTestCase {
    var sut: FetchMessages!

    var mockMessagesService: MockMessageDataService!
    var mockCacheService: MockCacheService!
    var mockEventsService: MockEventsService!

    override func setUp() {
        super.setUp()
        mockMessagesService = MockMessageDataService()
        mockCacheService = MockCacheService()
        mockEventsService = MockEventsService()

        sut = FetchMessages(
            params: makeParams(),
            dependencies: makeDependencies(
                mockMessageDataService: mockMessagesService,
                mockCacheService: mockCacheService,
                mockEventsService: mockEventsService
            )
        )
    }

    override func tearDown() {
        super.tearDown()
        mockMessagesService = nil
        mockCacheService = nil
        mockEventsService = nil
    }

    func testExecute_whenAllRequestsSucceed() {
        let expectation = expectation(description: "callbacks are correct")
        expectation.expectedFulfillmentCount = 2

        sut.execute(endTime: Int(Date().timeIntervalSince1970), isUnread: false) { _ in
            expectation.fulfill()
        } onMessagesRequestSuccess: {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssert(mockCacheService.wasParseMessagesResponseCalled == true)
        XCTAssert(mockMessagesService.wasFetchMessagesCountCalled == true)
        XCTAssert(mockEventsService.wasProcessEventsCalled == true)
    }

    func testExecute_whenMessagesRequestFails() {
        mockMessagesService.fetchMessagesReturnError = true

        let expectation = expectation(description: "callbacks are called")
        expectation.expectedFulfillmentCount = 1

        sut.execute(endTime: Int(Date().timeIntervalSince1970), isUnread: false) { _ in
            expectation.fulfill()
        } onMessagesRequestSuccess: {
            XCTFail("Should not call this closure since the fetch is set to be failed.")
        }
        waitForExpectations(timeout: 2.0)

        XCTAssert(mockCacheService.wasParseMessagesResponseCalled == false)
        XCTAssert(mockMessagesService.wasFetchMessagesCountCalled == false)
        XCTAssert(mockEventsService.wasProcessEventsCalled == false)
    }

    func testExecute_whenPersistMessagesFails() {
        mockCacheService.returnsError = true

        sut = FetchMessages(
            params: makeParams(),
            dependencies: makeDependencies(mockCacheService: mockCacheService, mockEventsService: mockEventsService)
        )

        let expectation = expectation(description: "callbacks are correct")
        expectation.expectedFulfillmentCount = 2

        sut.execute(endTime: Int(Date().timeIntervalSince1970), isUnread: false) { _ in
            expectation.fulfill()
        } onMessagesRequestSuccess: {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssert(mockCacheService.wasParseMessagesResponseCalled == true)
        XCTAssert(mockMessagesService.wasFetchMessagesCountCalled == false)
        XCTAssert(mockEventsService.wasProcessEventsCalled == false)
    }

    func testExecute_whenMessagesCountRequestReturnsEmpty() {
        mockMessagesService.fetchMessagesCountReturnEmpty = true

        let expectation = expectation(description: "callbacks are called")
        expectation.expectedFulfillmentCount = 2

        sut.execute(endTime: Int(Date().timeIntervalSince1970), isUnread: false) { _ in
            expectation.fulfill()
        } onMessagesRequestSuccess: {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssert(mockCacheService.wasParseMessagesResponseCalled == true)
        XCTAssert(mockMessagesService.wasFetchMessagesCountCalled == true)
        XCTAssert(mockEventsService.wasProcessEventsCalled == false)
    }
}

private func makeParams() -> FetchMessages.Parameters {
    FetchMessages.Parameters(labelID: "dummy_label_id")
}

private func makeDependencies(
    mockMessageDataService: MessageDataServiceProtocol = MockMessageDataService(),
    mockCacheService: CacheServiceProtocol = MockCacheService(),
    mockEventsService: EventsServiceProtocol = MockEventsService()
) -> FetchMessages.Dependencies {
    FetchMessages.Dependencies(
        messageDataService: mockMessageDataService,
        cacheService: mockCacheService,
        eventsService: mockEventsService
    )
}
