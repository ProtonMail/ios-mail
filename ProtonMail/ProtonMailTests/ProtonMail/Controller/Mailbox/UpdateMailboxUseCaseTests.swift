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
    private var internetConnectionStatusProvider: MockInternetConnectionStatusProviderProtocol!
    private var testContainer: TestContainer!
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
        self.internetConnectionStatusProvider = MockInternetConnectionStatusProviderProtocol()
        testContainer = .init()
        self.sut = UpdateMailbox(
            dependencies: .init(
                eventService: self.eventService,
                messageDataService: self.messageDataService,
                conversationProvider: self.conversationProvider,
                purgeOldMessages: self.purgeOldMessages,
                fetchMessageWithReset: self.fetchMessageWithReset,
                fetchMessage: self.fetchMessage,
                fetchLatestEventID: self.fetchLatestEventID,
                internetConnectionStatusProvider: internetConnectionStatusProvider, 
                userDefaults: testContainer.userDefaults
            )
        )
        self.sut.setup(source: self.mailboxSource)

        conversationProvider.fetchConversationCountsStub.bodyIs { _, _, completion in
            completion?(.success(()))
        }
    }

    override func tearDownWithError() throws {
        self.eventService = nil
        self.messageDataService = nil
        self.conversationProvider = nil
        self.purgeOldMessages = nil
        self.fetchMessageWithReset = nil
        self.fetchMessage = nil
        self.fetchLatestEventID = nil
        self.internetConnectionStatusProvider = nil
        self.mailboxSource = nil
        testContainer = nil
        self.sut = nil
    }

    func testConversationScheduledFetch_succeed() {
        // Fetch event
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        let fetchMessagesAtTheEnd = false
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false)

        let eventExpected = expectation(description: "Fetch event")
        self.eventService.callFetchEvents.bodyIs { _, _, _, _, completion in
            completion?(.success([:]))
            eventExpected.fulfill()
        }

        let completionExpected = expectation(description: "completion")
        sut.execute(
            params: makeParams(
                showUnreadOnly: unreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: { _ in
                    XCTFail("Shouldn't trigger error handling")
                }
            )
        ) { _ in
            completionExpected.fulfill()
        }

        let exceptions = [eventExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.fetchMessageWithReset.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationScheduledFetch_whenThereAreMoreEvents_itShouldSendMoreEventsRequests() {
        // Fetch event
        // Fetch event
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        let fetchMessagesAtTheEnd = false
        messageDataService.hasValidEventID = isEventIDValid
        mailboxSource.currentViewMode = .conversation
        mailboxSource.locationViewMode = .conversation
        sut.setup(isFetching: false)

        eventService.callFetchEvents.bodyIs { times, _, _, _, completion in
            if times == 1 {
                completion?(.success(["More": 1]))
            } else {
                completion?(.success([:]))
            }
        }

        let completionExpected = expectation(description: "completion")
        sut.execute(
            params: makeParams(
                showUnreadOnly: unreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: { _ in
                    XCTFail("Shouldn't trigger error handling")
                }
            )
        ) { _ in
            completionExpected.fulfill()
        }

        wait(for: [completionExpected], timeout: 2.0)

        XCTAssertFalse(sut.isFetching)
        XCTAssertEqual(eventService.callFetchEvents.callCounter, 2)
        XCTAssertFalse(fetchMessageWithReset.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertNil(messageDataService.pushNotificationMessageID)
    }

    func testConversationScheduledFetch_RefreshEvent() {
        // Fetch event
        // Fetch message with reset
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        let fetchMessagesAtTheEnd = false
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false)

        let eventExpected = expectation(description: "Fetch event")
        self.eventService.callFetchEvents.bodyIs { _, _, _, _, completion in
            completion?(.success(["Refresh": 1]))
            eventExpected.fulfill()
        }

        let conversationExpected = expectation(description: "Fetch conversation")
        self.conversationProvider.fetchConversationsStub.bodyIs { _, _, _, _, shouldReset, completion in
            XCTAssertTrue(shouldReset)
            conversationExpected.fulfill()
            completion?(.success)
        }

        let completionExpected = expectation(description: "completion")
        sut.execute(
            params: makeParams(
                showUnreadOnly: unreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: { _ in
                    XCTFail("Shouldn't trigger error handling")
                }
            )
        ) { _ in
            completionExpected.fulfill()
        }

        let exceptions = [eventExpected, conversationExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.fetchMessageWithReset.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertTrue(self.fetchLatestEventID.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationScheduledFetch_notValidEventID() {
        // Event id is not valid
        // Fetch message with reset
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = false
        let fetchMessagesAtTheEnd = false
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false)

        self.eventService.callFetchEvents.bodyIs { _, _, _, _, completion in
            XCTFail("Event ID is not valid, shouldn't trigger")
        }

        let conversationExpected = expectation(description: "Fetch conversation")
        self.conversationProvider.fetchConversationsStub.bodyIs { _, _, _, _, shouldReset, completion in
            XCTAssertTrue(shouldReset)
            conversationExpected.fulfill()
            completion?(.success)
        }

        let completionExpected = expectation(description: "completion")
        sut.execute(
            params: makeParams(
                showUnreadOnly: unreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: { _ in
                    XCTFail("Shouldn't trigger error handling")
                }
            )
        ) { _ in
            completionExpected.fulfill()
        }

        let exceptions = [conversationExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.fetchMessageWithReset.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationScheduledFetch_eventFailed() {
        // Fetch event > failed > trigger error handling
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        let fetchMessagesAtTheEnd = false
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false)

        let eventExpected = expectation(description: "Fetch event")
        self.eventService.callFetchEvents.bodyIs { _, _, _, _, completion in
            completion?(.failure(NSError(domain: "test.com", code: 999, localizedDescription: "Event API failed")))
            eventExpected.fulfill()
        }

        let completionExpected = expectation(description: "completion")
        let errorExpected = expectation(description: "error happens")
        sut.execute(
            params: makeParams(
                showUnreadOnly: unreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: { error in
                    XCTAssertEqual(error.localizedDescription, "Event API failed")
                    errorExpected.fulfill()
                }
            )
        ) { _ in
            completionExpected.fulfill()
        }

        let exceptions = [eventExpected, errorExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.fetchMessageWithReset.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertFalse(self.fetchLatestEventID.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationScheduledFetch_messageFailed() {
        // Fetch event > failed > trigger error handling
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        let fetchMessagesAtTheEnd = false
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false)

        let eventExpected = expectation(description: "Fetch event")
        self.eventService.callFetchEvents.bodyIs { _, _, _, _, completion in
            completion?(.failure(NSError(domain: "test.com", code: 999, localizedDescription: "conversation failed")))
            eventExpected.fulfill()
        }

        let completionExpected = expectation(description: "completion")
        let errorExpected = expectation(description: "error happens")
        sut.execute(
            params: makeParams(
                showUnreadOnly: unreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: { error in
                    XCTAssertEqual(error.localizedDescription, "conversation failed")
                    errorExpected.fulfill()
                }
            )
        ) { _ in
            completionExpected.fulfill()
        }

        let exceptions = [eventExpected, errorExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.fetchMessageWithReset.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertFalse(self.fetchLatestEventID.callExecutionBlock.wasCalledExactlyOnce)
    }

    func testMessageScheduledFetch_succeed() {
        // Fetch event
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        let fetchMessagesAtTheEnd = false
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .singleMessage
        self.mailboxSource.locationViewMode = .singleMessage
        self.sut.setup(isFetching: false)

        let eventExpected = expectation(description: "Fetch event")
        self.eventService.callFetchEvents.bodyIs { _, _, _, _, completion in
            completion?(.success([:]))
            eventExpected.fulfill()
        }

        let completionExpected = expectation(description: "completion")
        sut.execute(
            params: makeParams(
                showUnreadOnly: unreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: { _ in
                    XCTFail("Shouldn't trigger error handling")
                }
            )
        ) { _ in
            completionExpected.fulfill()
        }

        let exceptions = [eventExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.fetchMessage.executeWasCalled)
        XCTAssertFalse(self.fetchMessageWithReset.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationCleanFetch() {
        // Fetch message with reset
        // Done
        let unreadOnly = false
        let isCleanFetch = true
        let isEventIDValid = true
        let fetchMessagesAtTheEnd = false
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false)

        self.eventService.callFetchEvents.bodyIs { _, _, _, _, completion in
            XCTFail("Event ID is not valid, shouldn't trigger")
        }

        let conversationExpected = expectation(description: "Fetch conversation")
        self.conversationProvider.fetchConversationsStub.bodyIs { _, _, _, _, shouldReset, completion in
            XCTAssertTrue(shouldReset)
            conversationExpected.fulfill()
            completion?(.success)
        }

        let completionExpected = expectation(description: "completion")
        sut.execute(
            params: makeParams(
                showUnreadOnly: unreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: { _ in
                    XCTFail("Shouldn't trigger error handling")
                }
            )
        ) { _ in
            completionExpected.fulfill()
        }

        let exceptions = [conversationExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.fetchMessageWithReset.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertTrue(self.fetchLatestEventID.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }

    func testMessageCleanFetch() {
        // Fetch message with reset
        // Done
        let unreadOnly = false
        let isCleanFetch = true
        let isEventIDValid = true
        let fetchMessagesAtTheEnd = false
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .singleMessage
        self.mailboxSource.locationViewMode = .singleMessage
        self.sut.setup(isFetching: false)

        self.eventService.callFetchEvents.bodyIs { _, _, _, _, completion in
            XCTFail("Event ID is not valid, shouldn't trigger")
        }

        let completionExpected = expectation(description: "completion")
        sut.execute(
            params: makeParams(
                showUnreadOnly: unreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: { _ in
                    XCTFail("Shouldn't trigger error handling")
                }
            )
        ) { _ in
            completionExpected.fulfill()
        }

        let exceptions = [completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertTrue(self.fetchMessageWithReset.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }

    func testIsFetchingCase_cleanFetch() {
        let unreadOnly = false
        let isCleanFetch = true
        let isEventIDValid = true
        let fetchMessagesAtTheEnd = false
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: true)

        self.conversationProvider.fetchConversationsStub.bodyIs { _, _, _, _, shouldReset, completion in
            XCTFail("isFetching, shouldn't trigger")
        }

        let completionExpected = expectation(description: "completion")
        sut.execute(
            params: makeParams(
                showUnreadOnly: unreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: { _ in
                    XCTFail("Shouldn't trigger error handling")
                }
            )
        ) { _ in
            completionExpected.fulfill()
        }
        wait(for: [completionExpected], timeout: 2.0)

        XCTAssertTrue(self.sut.isFetching)
        XCTAssertFalse(self.fetchMessageWithReset.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertFalse(self.fetchLatestEventID.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }

    func testIsFetchingCase_notCleanFetch() {
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        let fetchMessagesAtTheEnd = false
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: true)

        self.conversationProvider.fetchConversationsStub.bodyIs { _, _, _, _, shouldReset, completion in
            XCTFail("isFetching, shouldn't trigger")
        }
        self.eventService.callFetchEvents.bodyIs { _, _, _, _, _ in
            XCTFail("isFetching, shouldn't call event API")
        }

        let completionExpected = expectation(description: "completion")
        sut.execute(
            params: makeParams(
                showUnreadOnly: unreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: { _ in
                    XCTFail("Shouldn't trigger error handling")
                }
            )
        ) { _ in
            completionExpected.fulfill()
        }
        wait(for: [completionExpected], timeout: 2.0)

        XCTAssertTrue(self.sut.isFetching)
        XCTAssertFalse(self.fetchMessageWithReset.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertNotNil(self.messageDataService.pushNotificationMessageID)
    }

    func testConversationScheduledFetch_locationIsEmpty_succeed() {
        // Fetch event
        // Done
        let unreadOnly = false
        let isCleanFetch = false
        let isEventIDValid = true
        let fetchMessagesAtTheEnd = true
        self.messageDataService.hasValidEventID = isEventIDValid
        self.mailboxSource.currentViewMode = .conversation
        self.mailboxSource.locationViewMode = .conversation
        self.sut.setup(isFetching: false)

        let conversationExpected = expectation(description: "Fetch conversation")
        self.conversationProvider.fetchConversationsStub.bodyIs { _, _, _, _, shouldReset, completion in
            XCTAssertFalse(shouldReset)
            conversationExpected.fulfill()
            completion?(.success)
        }


        let eventExpected = expectation(description: "Fetch event")
        self.eventService.callFetchEvents.bodyIs { _, _, _, _, completion in
            completion?(.success([:]))
            eventExpected.fulfill()
        }

        let completionExpected = expectation(description: "completion")
        sut.execute(
            params: makeParams(
                showUnreadOnly: unreadOnly,
                isCleanFetch: isCleanFetch,
                fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
                errorHandler: { _ in
                    XCTFail("Shouldn't trigger error handling")
                }
            )
        ) { _ in
            completionExpected.fulfill()
        }

        let exceptions = [conversationExpected, eventExpected, completionExpected]
        wait(for: exceptions, timeout: 2.0)

        XCTAssertFalse(self.sut.isFetching)
        XCTAssertFalse(self.fetchMessageWithReset.callExecutionBlock.wasCalledExactlyOnce)
        XCTAssertNil(self.messageDataService.pushNotificationMessageID)
    }

    private func makeParams(
        showUnreadOnly: Bool,
        isCleanFetch: Bool,
        fetchMessagesAtTheEnd: Bool,
        errorHandler: @escaping UpdateMailbox.ErrorHandler
    ) -> UpdateMailbox.Parameters {
        .init(
            labelID: LabelID("TestID"),
            showUnreadOnly: showUnreadOnly,
            isCleanFetch: isCleanFetch,
            time: 0,
            fetchMessagesAtTheEnd: fetchMessagesAtTheEnd,
            errorHandler: errorHandler,
            userID: ""
        )
    }
}

fileprivate final class MockUpdateMailboxSource: UpdateMailboxSourceProtocol {
    var currentViewMode: ViewMode = .conversation
    var locationViewMode: ViewMode = .conversation
}
