// Copyright (c) 2022 Proton Technologies AG
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

final class UpdateMailboxUseCaseTests: XCTestCase {
    private var eventService: EventsServiceMock!
    private var messageDataService: MockMessageDataService!
    private var conversationProvider: MockConversationProvider!
    private var purgeOldMessages: MockPurgeOldMessages!
    private var fetchMessageWithReset: MockFetchMessagesWithReset!
    private var fetchMessage: MockFetchMessages!
    private var fetchLatestEventID: MockFetchLatestEventId!
    private var mailboxSource: MockUpdateMailboxSource!
    private var messageInfoCache: MessageInfoCacheMock!
    private var sut: UpdateMailbox!

    override func setUpWithError() throws {
        self.eventService = EventsServiceMock()
        self.messageDataService = MockMessageDataService()
        self.conversationProvider = MockConversationProvider()
        self.purgeOldMessages = MockPurgeOldMessages()
        self.fetchMessageWithReset = MockFetchMessagesWithReset()
        self.fetchMessage = MockFetchMessages()
        self.fetchLatestEventID = MockFetchLatestEventId()
        self.mailboxSource = MockUpdateMailboxSource()
        self.messageInfoCache = MessageInfoCacheMock()
        self.sut = UpdateMailbox(
            dependencies: .init(messageInfoCache: self.messageInfoCache, eventService: self.eventService, messageDataService: self.messageDataService, conversationProvider: self.conversationProvider, purgeOldMessages: self.purgeOldMessages, fetchMessageWithReset: self.fetchMessageWithReset, fetchMessage: self.fetchMessage, fetchLatestEventID: self.fetchLatestEventID), parameters: .init(labelID: LabelID("TestID")))
        self.sut.setup(source: self.mailboxSource)
    }

    override func tearDownWithError() throws {
        self.eventService = nil
        self.messageDataService = nil
        self.conversationProvider = nil
        self.purgeOldMessages = nil
        self.fetchMessageWithReset = nil
        self.fetchMessage = nil
        self.fetchLatestEventID = nil
        self.mailboxSource = nil
        self.messageInfoCache = nil
        self.sut = nil
    }

    func testConversationFirstFetchCase_succeed() {
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation

        let countExpected = expectation(description: "Fetch conversation count")
        self.conversationProvider.callFetchConversationCounts.bodyIs { _, _, completion in
            countExpected.fulfill()
            completion?(.success(Void()))
        }

        self.eventService.callFetchEvents.bodyIs { _, _, _, _ in
            XCTFail("First fetch case shouldn't call event API")
        }

        let conversationExpected = expectation(description: "Fetch conversation")
        self.conversationProvider.callFetchConversations.bodyIs { _, _, _, _, shouldReset, completion in
            XCTAssertFalse(shouldReset)
            conversationExpected.fulfill()
            completion?(.success)
        }

        let completionExpected = expectation(description: "completion")
        self.sut.exec(showUnreadOnly: unreadOnly, isCleanFetch: isCleanFetch) { error in
            XCTFail("Shouldn't trigger error handling")
        } completion: {
            completionExpected.fulfill()
        }

        let exceptions = [countExpected, conversationExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.sut.isFirstFetch)
        XCTAssertFalse(self.fetchMessageWithReset.executeWasCalled)
        XCTAssertFalse(self.fetchLatestEventID.executeWasCalled)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationScheduledFetch_succeed() {
        // Fetch event
        // Fetch message
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false, isFirstFetch: false)

        let eventExpected = expectation(description: "Fetch event")
        self.eventService.callFetchEvents.bodyIs { _, _, _, completion in
            completion?(nil, [:], nil)
            eventExpected.fulfill()
        }

        let conversationExpected = expectation(description: "Fetch conversation")
        self.conversationProvider.callFetchConversations.bodyIs { _, _, _, _, shouldReset, completion in
            XCTAssertFalse(shouldReset)
            conversationExpected.fulfill()
            completion?(.success)
        }

        let completionExpected = expectation(description: "completion")
        self.sut.exec(showUnreadOnly: unreadOnly, isCleanFetch: isCleanFetch) { error in
            XCTFail("Shouldn't trigger error handling")
        } completion: {
            completionExpected.fulfill()
        }

        let exceptions = [eventExpected, conversationExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.sut.isFirstFetch)
        XCTAssertFalse(self.fetchMessageWithReset.executeWasCalled)
        XCTAssertNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationScheduledFetch_oneMoreEvent() {
        // Fetch event
        // Fetch event
        // Fetch messages
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false, isFirstFetch: false)

        let eventExpected = expectation(description: "Fetch event")
        eventExpected.expectedFulfillmentCount = 2
        self.eventService.callFetchEvents.bodyIs { times, _, _, completion in
            if times == 1 {
                completion?(nil, ["More": 1], nil)
            } else {
                completion?(nil, [:], nil)
            }

            eventExpected.fulfill()
        }

        let conversationExpected = expectation(description: "Fetch conversation")
        self.conversationProvider.callFetchConversations.bodyIs { _, _, _, _, shouldReset, completion in
            XCTAssertFalse(shouldReset)
            conversationExpected.fulfill()
            completion?(.success)
        }

        let completionExpected = expectation(description: "completion")
        self.sut.exec(showUnreadOnly: unreadOnly, isCleanFetch: isCleanFetch) { error in
            XCTFail("Shouldn't trigger error handling")
        } completion: {
            completionExpected.fulfill()
        }

        let exceptions = [eventExpected, conversationExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.sut.isFirstFetch)
        XCTAssertFalse(self.fetchMessageWithReset.executeWasCalled)
        XCTAssertNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationScheduledFetch_RefreshEvent() {
        // Fetch event
        // Fetch message with reset
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false, isFirstFetch: false)

        let eventExpected = expectation(description: "Fetch event")
        self.eventService.callFetchEvents.bodyIs { _, _, _, completion in
            completion?(nil, ["Refresh": 1], nil)
            eventExpected.fulfill()
        }

        let conversationExpected = expectation(description: "Fetch conversation")
        self.conversationProvider.callFetchConversations.bodyIs { _, _, _, _, shouldReset, completion in
            XCTAssertTrue(shouldReset)
            conversationExpected.fulfill()
            completion?(.success)
        }

        let completionExpected = expectation(description: "completion")
        self.sut.exec(showUnreadOnly: unreadOnly, isCleanFetch: isCleanFetch) { error in
            XCTFail("Shouldn't trigger error handling")
        } completion: {
            completionExpected.fulfill()
        }

        let exceptions = [eventExpected, conversationExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.sut.isFirstFetch)
        XCTAssertFalse(self.fetchMessageWithReset.executeWasCalled)
        XCTAssertTrue(self.fetchLatestEventID.executeWasCalled)
        XCTAssertNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationScheduledFetch_notValidEventID() {
        // Event id is not valid
        // Fetch message with reset
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = false
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false, isFirstFetch: false)

        self.eventService.callFetchEvents.bodyIs { _, _, _, completion in
            XCTFail("Event ID is not valid, shouldn't trigger")
        }

        let conversationExpected = expectation(description: "Fetch conversation")
        self.conversationProvider.callFetchConversations.bodyIs { _, _, _, _, shouldReset, completion in
            XCTAssertTrue(shouldReset)
            conversationExpected.fulfill()
            completion?(.success)
        }

        let completionExpected = expectation(description: "completion")
        self.sut.exec(showUnreadOnly: unreadOnly, isCleanFetch: isCleanFetch) { error in
            XCTFail("Shouldn't trigger error handling")
        } completion: {
            completionExpected.fulfill()
        }

        let exceptions = [conversationExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.sut.isFirstFetch)
        XCTAssertFalse(self.fetchMessageWithReset.executeWasCalled)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationScheduledFetch_eventFailed() {
        // Fetch event > failed > trigger error handling
        // Fetch message
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false, isFirstFetch: false)

        let eventExpected = expectation(description: "Fetch event")
        self.eventService.callFetchEvents.bodyIs { _, _, _, completion in
            completion?(nil, nil, NSError(domain: "test.com", code: 999, localizedDescription: "Event API failed"))
            eventExpected.fulfill()
        }

        let conversationExpected = expectation(description: "Fetch conversation")
        self.conversationProvider.callFetchConversations.bodyIs { _, _, _, _, shouldReset, completion in
            XCTAssertFalse(shouldReset)
            conversationExpected.fulfill()
            completion?(.success)
        }

        let completionExpected = expectation(description: "completion")
        let errorExpected = expectation(description: "error happens")
        self.sut.exec(showUnreadOnly: unreadOnly, isCleanFetch: isCleanFetch) { error in
            XCTAssertEqual(error.localizedDescription, "Event API failed")
            errorExpected.fulfill()
        } completion: {
            completionExpected.fulfill()
        }

        let exceptions = [eventExpected, conversationExpected, errorExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.sut.isFirstFetch)
        XCTAssertFalse(self.fetchMessageWithReset.executeWasCalled)
        XCTAssertFalse(self.fetchLatestEventID.executeWasCalled)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationScheduledFetch_messageFailed() {
        // Fetch event > failed > trigger error handling
        // Fetch message
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false, isFirstFetch: false)

        let eventExpected = expectation(description: "Fetch event")
        self.eventService.callFetchEvents.bodyIs { _, _, _, completion in
            completion?(nil, [:], nil)
            eventExpected.fulfill()
        }

        let conversationExpected = expectation(description: "Fetch conversation")
        self.conversationProvider.callFetchConversations.bodyIs { _, _, _, _, shouldReset, completion in
            XCTAssertFalse(shouldReset)
            conversationExpected.fulfill()
            completion?(.failure(NSError(domain: "test.com", code: 999, localizedDescription: "conversation failed")))
        }

        let completionExpected = expectation(description: "completion")
        let errorExpected = expectation(description: "error happens")
        self.sut.exec(showUnreadOnly: unreadOnly, isCleanFetch: isCleanFetch) { error in
            XCTAssertEqual(error.localizedDescription, "conversation failed")
            errorExpected.fulfill()
        } completion: {
            completionExpected.fulfill()
        }

        let exceptions = [eventExpected, conversationExpected, errorExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.sut.isFirstFetch)
        XCTAssertFalse(self.fetchMessageWithReset.executeWasCalled)
        XCTAssertFalse(self.fetchLatestEventID.executeWasCalled)
        XCTAssertNil(self.messageDataService.pushNotificationMessageID)
    }

    func testMessageScheduledFetch_succeed() {
        // Fetch event
        // Fetch message
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .singleMessage
        self.mailboxSource.locationViewMode = .singleMessage
        self.sut.setup(isFetching: false, isFirstFetch: false)

        let eventExpected = expectation(description: "Fetch event")
        self.eventService.callFetchEvents.bodyIs { _, _, _, completion in
            completion?(nil, [:], nil)
            eventExpected.fulfill()
        }

        let completionExpected = expectation(description: "completion")
        self.sut.exec(showUnreadOnly: unreadOnly, isCleanFetch: isCleanFetch) { error in
            XCTFail("Shouldn't trigger error handling")
        } completion: {
            completionExpected.fulfill()
        }

        let exceptions = [eventExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.sut.isFirstFetch)
        XCTAssertTrue(self.fetchMessage.executeWasCalled)
        XCTAssertFalse(self.fetchMessageWithReset.executeWasCalled)
        XCTAssertNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationCleanFetch() {
        // Fetch message with reset
        // Done
        let unreadOnly = false
        let isCleanFetch = true
        let isEventIDValid = true
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false, isFirstFetch: false)

        self.eventService.callFetchEvents.bodyIs { _, _, _, completion in
            XCTFail("Event ID is not valid, shouldn't trigger")
        }

        let conversationExpected = expectation(description: "Fetch conversation")
        self.conversationProvider.callFetchConversations.bodyIs { _, _, _, _, shouldReset, completion in
            XCTAssertTrue(shouldReset)
            conversationExpected.fulfill()
            completion?(.success)
        }

        let completionExpected = expectation(description: "completion")
        self.sut.exec(showUnreadOnly: unreadOnly, isCleanFetch: isCleanFetch) { error in
            XCTFail("Shouldn't trigger error handling")
        } completion: {
            completionExpected.fulfill()
        }

        let exceptions = [conversationExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.sut.isFirstFetch)
        XCTAssertFalse(self.fetchMessageWithReset.executeWasCalled)
        XCTAssertTrue(self.fetchLatestEventID.executeWasCalled)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }

    func testMessageCleanFetch() {
        // Fetch message with reset
        // Done
        let unreadOnly = false
        let isCleanFetch = true
        let isEventIDValid = true
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .singleMessage
        self.mailboxSource.locationViewMode = .singleMessage
        self.sut.setup(isFetching: false, isFirstFetch: false)

        self.eventService.callFetchEvents.bodyIs { _, _, _, completion in
            XCTFail("Event ID is not valid, shouldn't trigger")
        }

        let completionExpected = expectation(description: "completion")
        self.sut.exec(showUnreadOnly: unreadOnly, isCleanFetch: isCleanFetch) { error in
            XCTFail("Shouldn't trigger error handling")
        } completion: {
            completionExpected.fulfill()
        }

        let exceptions = [completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.sut.isFirstFetch)
        XCTAssertTrue(self.fetchMessageWithReset.executeWasCalled)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }

    func testIsFetchingCase_cleanFetch() {
        let unreadOnly = false
        let isCleanFetch = true
        let isEventIDValid = true
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: true, isFirstFetch: true)

        self.conversationProvider.callFetchConversations.bodyIs { _, _, _, _, shouldReset, completion in
            XCTFail("isFetching, shouldn't trigger")
        }

        let completionExpected = expectation(description: "completion")
        self.sut.exec(showUnreadOnly: unreadOnly, isCleanFetch: isCleanFetch) { error in
            XCTFail("Shouldn't trigger error handling")
        } completion: {
            completionExpected.fulfill()
        }
        wait(for: [completionExpected], timeout: 2.0)

        XCTAssertTrue(self.sut.isFetching)
        XCTAssertFalse(self.fetchMessageWithReset.executeWasCalled)
        XCTAssertFalse(self.fetchLatestEventID.executeWasCalled)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }

    func testIsFetchingCase_notCleanFetch() {
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: true, isFirstFetch: true)

        self.conversationProvider.callFetchConversations.bodyIs { _, _, _, _, shouldReset, completion in
            XCTFail("isFetching, shouldn't trigger")
        }
        self.eventService.callFetchEvents.bodyIs { _, _, _, _ in
            XCTFail("isFetching, shouldn't call event API")
        }

        let completionExpected = expectation(description: "completion")
        self.sut.exec(showUnreadOnly: unreadOnly, isCleanFetch: isCleanFetch) { error in
            XCTFail("Shouldn't trigger error handling")
        } completion: {
            completionExpected.fulfill()
        }
        wait(for: [completionExpected], timeout: 2.0)

        XCTAssertTrue(self.sut.isFetching)
        XCTAssertFalse(self.fetchMessageWithReset.executeWasCalled)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }
}

fileprivate final class MockUpdateMailboxSource: UpdateMailboxSourceProtocol {
    var currentViewMode: ViewMode = .conversation
    var locationViewMode: ViewMode = .conversation
}
