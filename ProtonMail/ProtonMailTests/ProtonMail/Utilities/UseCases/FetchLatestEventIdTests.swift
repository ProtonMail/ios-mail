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

import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

class FetchLatestEventIdTests: XCTestCase {
    var sut: FetchLatestEventId!

    var mockLastUpdatedStore: MockLastUpdatedStoreProtocol!
    var mockApiService: APIServiceMock!

    override func setUp() {
        super.setUp()
        mockLastUpdatedStore = MockLastUpdatedStoreProtocol()
        mockApiService = .init()

        sut = FetchLatestEventId(
            userId: "dummy_user_id",
            dependencies: makeDependencies(
                mockApiService: mockApiService,
                mockLastUpdatedStore: mockLastUpdatedStore
            )
        )
    }

    override func tearDown() {
        super.tearDown()
        mockLastUpdatedStore = nil
    }

    func testExecute_whenEventsService_returnsAnEvent() {
        let eventId = "dummy_event_id"
        mockApiService.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(["EventID": eventId]))
        }

        let expectation = expectation(description: "callback is called")
        sut.execute(params: ()) { result in
            XCTAssert(try! result.get().eventID == eventId)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssert(mockLastUpdatedStore.updateEventIDStub.wasCalledExactlyOnce == true)
    }

    func testExecute_whenEventsService_doesNotReturnAnEvent() {
        mockApiService.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success([:]))
        }
        let expectation = expectation(description: "callback is called")
        sut.execute(params: ()) { result in
            XCTAssert(try! result.get().eventID.isEmpty == true)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssert(mockLastUpdatedStore.updateEventIDStub.wasCalled == false)
    }

}

private func makeDependencies(
    mockApiService: APIServiceMock,
    mockLastUpdatedStore: MockLastUpdatedStoreProtocol
) -> FetchLatestEventId.Dependencies {

    FetchLatestEventId.Dependencies(
        apiService: mockApiService,
        lastUpdatedStore: mockLastUpdatedStore
    )
}
