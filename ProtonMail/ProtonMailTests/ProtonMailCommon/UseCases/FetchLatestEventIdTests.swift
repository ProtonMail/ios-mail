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

class FetchLatestEventIdTests: XCTestCase {
    var sut: FetchLatestEventId!

    var mockEventsService: MockEventsService!
    var mockLastUpdatedStore: MockLastUpdatedStore!

    override func setUp() {
        super.setUp()
        mockEventsService = MockEventsService()
        mockLastUpdatedStore = MockLastUpdatedStore()

        sut = FetchLatestEventId(
            params: makeParams(),
            dependencies: makeDependencies(
                mockEventsService: mockEventsService,
                mockLastUpdatedStore: mockLastUpdatedStore
            )
        )
    }

    override func tearDown() {
        super.tearDown()
        mockEventsService = nil
        mockLastUpdatedStore = nil
    }

    func testExecute_whenEventsService_returnsAnEvent() {
        let eventId = "dummy_event_id"
        mockEventsService.fetchLatestEventIDResult.eventID = eventId

        let expectation = expectation(description: "callback is called")
        sut.execute { result in
            XCTAssert(try! result.get().eventID == eventId)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssert(mockEventsService.wasFetchLatestEventIDCalled == true)
        XCTAssert(mockLastUpdatedStore.clearWasCalled == true)
        XCTAssert(mockLastUpdatedStore.updateEventIDWasCalled == true)
    }

    func testExecute_whenEventsService_doesNotReturnAnEvent() {
        let expectation = expectation(description: "callback is called")
        sut.execute { result in
            XCTAssert(try! result.get().eventID.isEmpty == true)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssert(mockEventsService.wasFetchLatestEventIDCalled == true)
        XCTAssert(mockLastUpdatedStore.clearWasCalled == false)
        XCTAssert(mockLastUpdatedStore.updateEventIDWasCalled == false)
    }

}

private func makeParams() -> FetchLatestEventId.Parameters {
    FetchLatestEventId.Parameters(userId: "dummy_user_id")
}

private func makeDependencies(
    mockEventsService: EventsServiceProtocol,
    mockLastUpdatedStore: MockLastUpdatedStore
) -> FetchLatestEventId.Dependencies {

    FetchLatestEventId.Dependencies(
        eventsService: mockEventsService,
        lastUpdatedStore: mockLastUpdatedStore
    )
}
