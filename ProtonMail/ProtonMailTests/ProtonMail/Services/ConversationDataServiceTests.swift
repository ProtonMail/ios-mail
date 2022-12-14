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
import ProtonCore_TestingToolkit

final class ConversationDataServiceTests: XCTestCase {

    var sut: ConversationDataService!
    var userID = UserID("user1")
    var mockApiService: APIServiceMock!
    var mockContextProvider: MockCoreDataContextProvider!
    var mockLastUpdatedStore: MockLastUpdatedStore!
    var mockEventsService: MockEventsService!
    var fakeUndoActionManager: UndoActionManagerProtocol!
    var mockContactCacheStatus: MockContactCacheStatus!

    override func setUp() {
        super.setUp()
        mockApiService = APIServiceMock()
        mockContextProvider = MockCoreDataContextProvider()
        mockLastUpdatedStore = MockLastUpdatedStore()
        mockEventsService = MockEventsService()
        fakeUndoActionManager = UndoActionManager(apiService: mockApiService,
                                                  contextProvider: mockContextProvider,
                                                  getEventFetching: {return nil},
                                                  getUserManager: {return nil})
        mockContactCacheStatus = MockContactCacheStatus()
        sut = ConversationDataService(api: mockApiService,
                                      userID: userID,
                                      contextProvider: mockContextProvider,
                                      lastUpdatedStore: mockLastUpdatedStore,
                                      messageDataService: MockMessageDataService(),
                                      eventsService: mockEventsService,
                                      undoActionManager: fakeUndoActionManager,
                                      contactCacheStatus: mockContactCacheStatus)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockApiService = nil
        mockContextProvider = nil
        mockLastUpdatedStore = nil
        mockEventsService = nil
        fakeUndoActionManager = nil
        mockContactCacheStatus = nil
    }

    func testFilterMessagesDictionary() {
        let input: [[String: Any]] = [
            [
                "ID": "1"
            ],
            [
                "ID": "2"
            ],
            [
                "ID": "3"
            ],
            [
                "ID": "1"
            ]
        ]
        let ids = ["1"]

        let result = sut.messages(among: input, notContaining: ids)

        XCTAssertEqual(result.count, 2)
        result.forEach { item in
            let id = item["ID"] as! String
            XCTAssertFalse(ids.contains(id))
        }
    }

    func testLabelRequest_whenDoesNotExceedConversationIDsLimit_sendsOneRequest() {
        let conversationsIDs = dummyConversationIDs(amount: ConversationLabelRequest.maxNumberOfConversations)

        let expectation = expectation(description: "only one request is sent")
        let response = ConversationLabelResponseTestData.successTestResponse()
        updateMockApiService(with: response, forPath: "/label")

        DispatchQueue.global().async {
            self.sut.label(
                conversationIDs: conversationsIDs,
                as: LabelID(rawValue: "dummy-label-id"),
                isSwipeAction: Bool.random()
            ) { _ in
                XCTAssertTrue(self.mockApiService.requestJSONStub.callCounter == 1)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 2.0)
    }

    func testLabelRequest_whenExceedsConversationIDsLimit_sendsBatchRequest() {
        let conversationsIDs = dummyConversationIDs(amount: ConversationLabelRequest.maxNumberOfConversations + 1)

        let expectation = expectation(description: "more than one request is sent")
        let response = ConversationLabelResponseTestData.successTestResponse()
        updateMockApiService(with: response, forPath: "/label")

        DispatchQueue.global().async {
            self.sut.label(
                conversationIDs: conversationsIDs,
                as: LabelID(rawValue: "dummy-label-id"),
                isSwipeAction: Bool.random()
            ) { _ in
                XCTAssertTrue(self.mockApiService.requestJSONStub.callCounter == 2)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 2.0)
    }

    func testUnlabelRequest_whenDoesNotExceedConversationIDsLimit_sendsOneRequest() {
        let conversationIDs = dummyConversationIDs(amount: ConversationUnlabelRequest.maxNumberOfConversations)

        let expectation = expectation(description: "only one request is sent")
        let response = ConversationUnlabelResponseTestData.successTestResponse()
        updateMockApiService(with: response, forPath: "/unlabel")

        DispatchQueue.global().async {
            self.sut.unlabel(
                conversationIDs: conversationIDs,
                as: LabelID(rawValue: "dummy-label-id"),
                isSwipeAction: Bool.random()
            ) { _ in
                XCTAssertTrue(self.mockApiService.requestJSONStub.callCounter == 1)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 2.0)
    }

    func testUnlabelRequest_whenExceedsConversationIDsLimit_sendsBatchRequest() {
        let conversationIDs = dummyConversationIDs(amount: ConversationUnlabelRequest.maxNumberOfConversations + 1)

        let expectation = expectation(description: "more than one request is sent")
        let response = ConversationUnlabelResponseTestData.successTestResponse()
        updateMockApiService(with: response, forPath: "/unlabel")

        DispatchQueue.global().async {
            self.sut.unlabel(
                conversationIDs: conversationIDs,
                as: LabelID(rawValue: "dummy-label-id"),
                isSwipeAction: Bool.random()
            ) { _ in
                XCTAssertTrue(self.mockApiService.requestJSONStub.callCounter == 2)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 2.0)
    }

    func testSingleConversationRequest_isSatisfiedWithEmptyDictionary() async throws {
        let stubbedConversationID = ConversationID("foo")

        let stubbedResponse: [String: Any] = [
            "Conversation": [:],
            "Messages": []
        ]
        updateMockApiService(with: stubbedResponse, forPath: "conversations/foo")

        let conversation = try await withCheckedThrowingContinuation { continuation in
            self.sut.fetchConversation(with: stubbedConversationID, includeBodyOf: nil, callOrigin: nil) { result in
                continuation.resume(with: result)
            }
        }

        let context = try XCTUnwrap(conversation.managedObjectContext)
        let conversationID = context.performAndWait { conversation.conversationID }
        XCTAssertEqual(conversationID, "")
    }

    // MARK: Private methods

    private func updateMockApiService(with response: [String: Any], forPath expectedPath: String) {
        mockApiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains(expectedPath) {
                completion(nil, .success(response))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.badResponse()))
            }
        }
    }

    private func dummyConversationIDs(amount: Int) -> [ConversationID] {
        return (0...amount - 1)
            .map(String.init)
            .map(ConversationID.init(rawValue:))
	}
}
