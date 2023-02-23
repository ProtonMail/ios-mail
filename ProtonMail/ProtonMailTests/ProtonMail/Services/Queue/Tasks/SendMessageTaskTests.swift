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

import Foundation
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class SendMessageTaskTests: XCTestCase {
    private var sut: SendMessageTask!

    private var mockApiService: APIServiceMock!
    private var isUserAuthenticatedResult: Bool!
    private var mockIsUserAuthenticted: ((UserID) -> Bool)!
    private var mockFetchMessageDetail: MockFetchMessageDetail!
    private var mockMessageDataService: MockMessageDataService!
    private var mockSendMessageUseCase: MockSendMessageUseCase!
    private var mockEventsService: EventsServiceMock!
    private var mockNotificationHandler: MockNotificationHandler!
    private var mockLocalNotificationService: LocalNotificationService!
    private var mockUndoActionManager: MockUndoActionManager!
    private var mockNotificationCenter: NotificationCenter!
    private var mockQueueManager: QueueManager!
    private let mockCoreDataService = MockCoreDataContextProvider()

    private var mockMessagesQueue: PMPersistentQueue!
    private var mockMiscQueue: PMPersistentQueue!

    private let dummyID = "dummyID"
    private let dummyMessageURI = "dummyURI"

    private lazy var dummyMessageSendingData: MessageSendingData = {
        .init(
            message: MessageEntity(Message(context: mockCoreDataService.mainContext)),
            cachedUserInfo: nil,
            cachedAuthCredential: nil,
            cachedSenderAddress: nil,
            defaultSenderAddress: nil
        )
    }()
    private let nsError = NSError(domain: "", code: -15)
    private let waitTimeout = 2.0

    override func setUp() {
        super.tearDown()
        // Initialisations
        isUserAuthenticatedResult = true
        mockIsUserAuthenticted = { [unowned self] _ in isUserAuthenticatedResult }
        mockApiService = APIServiceMock()
        mockFetchMessageDetail = MockFetchMessageDetail(stubbedResult: .success(dummyMessageSendingData.message))
        mockSendMessageUseCase = MockSendMessageUseCase()
        mockEventsService = EventsServiceMock()
        mockMessageDataService = MockMessageDataService()
        mockNotificationHandler = MockNotificationHandler()
        mockLocalNotificationService = LocalNotificationService(
            userID: UserID.init(rawValue: dummyID),
            notificationHandler: mockNotificationHandler
        )
        mockUndoActionManager = MockUndoActionManager()
        mockMessagesQueue = PMPersistentQueue(queueName: "")
        mockMiscQueue = PMPersistentQueue(queueName: "")
        mockQueueManager = QueueManager(messageQueue: mockMessagesQueue, miscQueue: mockMiscQueue)
        mockNotificationCenter = NotificationCenter()

        // Configurations
        mockMessageDataService.messageSendingDataResult = dummyMessageSendingData

        sut = makeSUT()
    }

    override func tearDown() {
        super.tearDown()
        mockApiService = nil
        mockFetchMessageDetail = nil
        mockSendMessageUseCase = nil
        mockEventsService = nil
        mockMessageDataService = nil
        mockNotificationHandler = nil
        mockLocalNotificationService = nil
        mockUndoActionManager = nil
        mockMessagesQueue = nil
        mockMiscQueue = nil
        mockQueueManager = nil
        mockNotificationCenter = nil
        sut = nil
    }

    func testRun_whenSendingSucceeds_noErrorReturned() {
        let expect = expectation(description: "")
        sut.run(params: makeDummyParams()) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    // MARK: Send success tests

    func testRun_whenSendingSucceeds_successNotificationIsSent() {
        let expect = expectation(description: "")
        mockNotificationCenter.addObserver(forName: .sendMessageTaskSuccess, object: nil, queue: nil) { _ in
            expect.fulfill()
        }
        sut.run(params: makeDummyParams()) { _ in }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenSendingSucceeds_localNotificationIsUnscheduled() {
        let expect = expectation(description: "")
        sut.run(params: makeDummyParams()) { [unowned self] error in
            XCTAssertNil(error)
            XCTAssertTrue(mockNotificationHandler.callRemovePendingNoti.wasCalledExactlyOnce)
            expect.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenSendingSucceeds_UndoBannerIsShown() {
        let expect = expectation(description: "")
        sut.run(params: makeDummyParams()) { [unowned self] error in
            XCTAssertNil(error)
            XCTAssertTrue(mockUndoActionManager.callShowUndoSendBanner.wasCalledExactlyOnce)
            expect.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenScheduledSendingSucceeds_scheduledFolderDataIsFetched() {
        let expect = expectation(description: "")
        let params = makeDummyParams(deliveryTime: Date.distantFuture)
        sut.run(params: params) { [unowned self] error in
            XCTAssertNil(error)
            XCTAssertTrue(mockEventsService.callFetchEvents.wasCalledExactlyOnce)
            expect.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    // MARK: Send fails tests

    func testRun_whenUserIsNotAuthenticated_returnsError() {
        let expect = expectation(description: "")
        isUserAuthenticatedResult = false
        sut.run(params: makeDummyParams()) { error in
            XCTAssert(error as? NSError == NSError.userLoggedOut())
            expect.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenNoMessageFoundForURI_returnsError() {
        let expect = expectation(description: "")
        mockMessageDataService.messageSendingDataResult = nil
        sut.run(params: makeDummyParams()) { error in
            XCTAssert(error as? SendMessageTaskError == .noMessageFoundForURI)
            expect.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenSendRequestFails_returnsError() {
        let expect = expectation(description: "")
        mockSendMessageUseCase.result = .failure(nsError)
        sut.run(params: makeDummyParams()) { [unowned self] error in
            XCTAssert(error as? NSError == self.nsError)
            expect.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenSendRequestFails_failNotificationIsSent() {
        let expect = expectation(description: "")
        mockNotificationCenter.addObserver(forName: .sendMessageTaskFail, object: nil, queue: nil) { _ in
            expect.fulfill()
        }
        mockSendMessageUseCase.result = .failure(nsError)
        sut.run(params: makeDummyParams()) { _ in }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenSendRequestFails_localNotificationIsScheduled() {
        let expect = expectation(description: "")
        mockSendMessageUseCase.result = .failure(nsError)
        sut.run(params: makeDummyParams()) { [unowned self] error in
            XCTAssertNotNil(error)
            XCTAssertTrue(mockNotificationHandler.callAdd.wasCalledExactlyOnce)
            expect.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenSendRequestFails_forHumanVerification_queueManagerIsFlagged() {
        let expect = expectation(description: "")
        mockSendMessageUseCase.result = .failure(makeAPIError(with: APIErrorCode.humanVerificationRequired))
        sut.run(params: makeDummyParams()) { [unowned self] error in
            XCTAssert(self.mockQueueManager.isRequiredHumanCheck == true)
            XCTAssertNotNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenSendRequestFails_forHumanVerification_failNotificationIsSent() {
        let expect = expectation(description: "")
        mockNotificationCenter.addObserver(forName: .sendMessageTaskFail, object: nil, queue: nil) { _ in
            expect.fulfill()
        }
        mockSendMessageUseCase.result = .failure(makeAPIError(with: APIErrorCode.humanVerificationRequired))
        sut.run(params: makeDummyParams()) { _ in }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenSendRequestFails_withAlreadyExistsError_noErrorIsReturned() {
        let expect = expectation(description: "")
        mockSendMessageUseCase.result = .failure(makeAPIError(with: APIErrorCode.alreadyExist))
        sut.run(params: makeDummyParams()) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenSendRequestFails_withAlreadyExistsError_noFailNotificationIsSent() {
        let expect = expectation(description: "")
        expect.isInverted = true
        mockNotificationCenter.addObserver(forName: .sendMessageTaskFail, object: nil, queue: nil) { _ in
            expect.fulfill()
        }
        mockSendMessageUseCase.result = .failure(makeAPIError(with: APIErrorCode.alreadyExist))
        sut.run(params: makeDummyParams()) { _ in  }
        waitForExpectations(timeout: 0.5)
    }

    func testRun_whenSendRequestFails_withInvalidRequirementsError_noErrorIsReturned() {
        let expect = expectation(description: "")
        mockSendMessageUseCase.result = .failure(makeAPIError(with: APIErrorCode.invalidRequirements))
        sut.run(params: makeDummyParams()) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenSendRequestFails_withInvalidRequirementsError_localNotificationUnscheduled() {
        let expect = expectation(description: "")
        mockSendMessageUseCase.result = .failure(makeAPIError(with: APIErrorCode.invalidRequirements))
        sut.run(params: makeDummyParams()) { [unowned self] error in
            XCTAssertNil(error)
            XCTAssertTrue(mockNotificationHandler.callRemovePendingNoti.wasCalledExactlyOnce)
            expect.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenSendRequestFails_withInvalidRequirementsError_failNotificationIsSent() {
        let expect = expectation(description: "")
        mockNotificationCenter.addObserver(forName: .showScheduleSendUnavailable, object: nil, queue: nil) { _ in
            expect.fulfill()
        }
        mockSendMessageUseCase.result = .failure(makeAPIError(with: APIErrorCode.invalidRequirements))
        sut.run(params: makeDummyParams()) { _ in }
        waitForExpectations(timeout: waitTimeout)
    }

    func testRun_whenSendRequestFails_withEmailAddressFailedValidationError_failNotificationIsSent() {
        let expect1 = expectation(description: "")
        mockNotificationCenter.addObserver(forName: .sendMessageTaskFail, object: nil, queue: nil) { _ in
            expect1.fulfill()
        }
        let expect2 = expectation(description: "")
        mockNotificationCenter.addObserver(
            forName: .messageSendFailAddressValidationIncorrect,
            object: nil,
            queue: nil) { _ in
                expect2.fulfill()
        }

        let error = makeAPIError(with: PGPTypeErrorCode.emailAddressFailedValidation.rawValue)
        mockSendMessageUseCase.result = .failure(error)
        sut.run(params: makeDummyParams()) { _ in }
        waitForExpectations(timeout: waitTimeout)
    }
}

extension SendMessageTaskTests {

    private func makeSUT() -> SendMessageTask {
        let taskDependencies: SendMessageTask.Dependencies = .init(
            isUserAuthenticated: mockIsUserAuthenticted,
            messageDataService: mockMessageDataService,
            fetchMessageDetail: mockFetchMessageDetail,
            sendMessage: mockSendMessageUseCase,
            localNotificationService: mockLocalNotificationService,
            eventsFetching: mockEventsService,
            undoActionManager: mockUndoActionManager,
            queueManager: mockQueueManager,
            notificationCenter: mockNotificationCenter
        )
        return SendMessageTask(dependencies: taskDependencies)
    }

    private func makeDummyParams(deliveryTime: Date? = nil) -> SendMessageTask.Params {
        return SendMessageTask.Params(
            messageURI: dummyMessageURI,
            deliveryTime: deliveryTime,
            undoSendDelay: 5,
            userID: UserID.init(rawValue: dummyID)
        )
    }

    private func makeAPIError(with bodyErrorCode: Int) -> ResponseError {
        return ResponseError(httpCode: 400, responseCode: bodyErrorCode, userFacingMessage: nil, underlyingError: nil)
    }
}
