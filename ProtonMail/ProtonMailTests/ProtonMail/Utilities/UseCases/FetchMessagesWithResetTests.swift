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

final class FetchMessagesWithResetTests: XCTestCase {
    var sut: FetchMessagesWithReset!

    var mockFetchLatestEventId: MockFetchLatestEventId!
    var mockFetchMessages: MockFetchMessages!
    var mockLocalMessagesService: MockLocalMessageDataServiceProtocol!
    var mockLastUpdatedStore: MockLastUpdatedStoreProtocol!
    var mockContactProvider: MockContactProvider!
    var mockLabelProvider: MockLabelProviderProtocol!

    private let timeout = 2.0

    override func setUp() {
        super.setUp()
        mockFetchLatestEventId = MockFetchLatestEventId()
        mockFetchMessages = MockFetchMessages()
        mockLocalMessagesService = .init()
        mockLastUpdatedStore = MockLastUpdatedStoreProtocol()
        mockContactProvider = MockContactProvider(coreDataContextProvider: MockCoreDataContextProvider())
        mockLabelProvider = MockLabelProviderProtocol()

        sut = FetchMessagesWithReset(
            userID: "dummy_user_id",
            dependencies: .init(
                fetchLatestEventId: mockFetchLatestEventId,
                fetchMessages: mockFetchMessages,
                localMessageDataService: mockLocalMessagesService,
                lastUpdatedStore: mockLastUpdatedStore,
                contactProvider: mockContactProvider,
                labelProvider: mockLabelProvider))

        mockLabelProvider.fetchV4LabelsStub.bodyIs { _, completion in
            completion?(.success(()))
        }
    }

    override func tearDown() {
        super.tearDown()
        mockFetchLatestEventId = nil
        mockFetchMessages = nil
        mockLocalMessagesService = nil
        mockLastUpdatedStore = nil
        mockContactProvider = nil
        mockLabelProvider = nil
    }

    func testExecute_cleaningContacts_whenAllRequestsSucceed() throws {
        let cleanContact = true
        let expectation = expectation(description: "callback is called")

        let params = makeParams(
            refetchContacts: cleanContact
        )
        sut.execute(params: params) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout)
        try checkMocksForCleaningContacts(cleanContactIs: cleanContact)
    }

    func testExecute_withoutCleaningContacts_whenAllRequestsSucceed() throws {
        let cleanContact = false
        let expectation = expectation(description: "callback is called")

        let params = makeParams(
            refetchContacts: cleanContact
        )
        sut.execute(params: params) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout)
        try checkMocksForCleaningContacts(cleanContactIs: cleanContact)
    }

    func testExecute_cleansButDoesntRemoveDrafts_whenAllRequestsSucceed() throws {
        let expectation = expectation(description: "callback is called")

        let params = makeParams(
            refetchContacts: Bool.random()
        )
        sut.execute(params: params) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout)

        XCTAssertTrue(mockFetchLatestEventId.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertTrue(mockFetchMessages.executeWasCalled)

        let cleanMessageCall = try XCTUnwrap(mockLocalMessagesService.cleanMessageStub.lastArguments)
        XCTAssert(cleanMessageCall.a1 == false)
        XCTAssertFalse(cleanMessageCall.a2)

        XCTAssertTrue(mockLastUpdatedStore.removeUpdateTimeExceptUnreadStub.wasCalledExactlyOnce)
    }

    func testExecute_whenThereIsNoNewEvent() {
        let expectation = expectation(description: "callback is called")

        let emptyEvent = EventLatestIDResponse()
        mockFetchLatestEventId.result = .success(emptyEvent)

        let params = makeParams(
            refetchContacts: Bool.random()
        )
        sut.execute(params: params) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout)

        XCTAssertTrue(mockFetchLatestEventId.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertFalse(mockFetchMessages.executeWasCalled)

        XCTAssertFalse(mockLocalMessagesService.cleanMessageStub.wasCalled)

        XCTAssertFalse(mockContactProvider.wasCleanUpCalled)
        XCTAssertEqual(mockContactProvider.fetchContactsStub.callCounter, 0)

        XCTAssertEqual(mockLabelProvider.fetchV4LabelsStub.callCounter, 0)

        XCTAssertFalse(mockLastUpdatedStore.removeUpdateTimeExceptUnreadStub.wasCalled)
    }

    func testExecute_whenFetchMessagesFails_andRefreshContacts() {
        let expectation = expectation(description: "callback is called")

        mockFetchMessages.result = .failure(NSError.badResponse())

        let params = makeParams(
            refetchContacts: true
        )
        sut.execute(params: params) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout)

        XCTAssertTrue(mockFetchLatestEventId.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertTrue(mockFetchMessages.executeWasCalled)

        XCTAssertFalse(mockLocalMessagesService.cleanMessageStub.wasCalled)

        XCTAssertTrue(mockContactProvider.wasCleanUpCalled)
        XCTAssertEqual(mockContactProvider.fetchContactsStub.callCounter, 1)

        XCTAssertEqual(mockLabelProvider.fetchV4LabelsStub.callCounter, 1)

        XCTAssertFalse(mockLastUpdatedStore.removeUpdateTimeExceptUnreadStub.wasCalled)
    }

    func testExecute_whenFetchMessagesFails_andDoNotRefreshContacts() {
        let expectation = expectation(description: "callback is called")

        mockFetchMessages.result = .failure(NSError.badResponse())

        let params = makeParams(
            refetchContacts: false
        )
        sut.execute(params: params) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout)

        XCTAssertTrue(mockFetchLatestEventId.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertTrue(mockFetchMessages.executeWasCalled)

        XCTAssertFalse(mockLocalMessagesService.cleanMessageStub.wasCalled)

        XCTAssertFalse(mockContactProvider.wasCleanUpCalled)
        XCTAssertEqual(mockContactProvider.fetchContactsStub.callCounter, 0)

        XCTAssertEqual(mockLabelProvider.fetchV4LabelsStub.callCounter, 1)

        XCTAssertFalse(mockLastUpdatedStore.removeUpdateTimeExceptUnreadStub.wasCalled)
    }
}

extension FetchMessagesWithResetTests {
    private func checkMocksForCleaningContacts(cleanContactIs value: Bool) throws {
        XCTAssertTrue(mockFetchLatestEventId.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertTrue(mockFetchMessages.executeWasCalled)

        let cleanMessageCall = try XCTUnwrap(mockLocalMessagesService.cleanMessageStub.lastArguments)
        XCTAssertFalse(cleanMessageCall.a2)

        XCTAssert(mockContactProvider.wasCleanUpCalled == value)
        XCTAssertEqual(mockContactProvider.fetchContactsStub.callCounter, value ? 1 : 0)

        XCTAssertTrue(mockLastUpdatedStore.removeUpdateTimeExceptUnreadStub.wasCalledExactlyOnce)
    }

    private func makeParams(refetchContacts: Bool) -> FetchMessagesWithReset.Params {
        FetchMessagesWithReset.Params(
            labelID: "dummy_label_id",
            fetchOnlyUnreadMessages: Bool.random(),
            refetchContacts: refetchContacts
        )
    }
}
