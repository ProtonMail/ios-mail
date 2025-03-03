// Copyright (c) 2025 Proton Technologies AG
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
import InboxTesting
import XCTest

class NotificationSchedulerSpy: NotificationScheduler {

    private(set) var invokedAdd: [UNNotificationRequest] = []

    // MARK: - NotificationScheduler

    func add(_ request: UNNotificationRequest) async throws {
        invokedAdd.append(request)
    }

}

class BackgroundTransitionTaskSchedulerSpy: BackgroundTransitionTaskScheduler {

    var stubbedBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 10)
    private(set) var invokedBeginBackgroundTask: [(taskName: String?, handler: (@MainActor @Sendable () -> Void)?)] = []
    private(set) var invokedEndBackgroundTask: [UIBackgroundTaskIdentifier] = []

    // MARK: - BackgroundTransitionTaskScheduler

    func beginBackgroundTask(
        withName taskName: String?,
        expirationHandler handler: (@MainActor @Sendable () -> Void)?
    ) -> UIBackgroundTaskIdentifier {
        invokedBeginBackgroundTask.append((taskName, handler))

        return stubbedBackgroundTaskIdentifier
    }
    
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        invokedEndBackgroundTask.append(identifier)
    }

}

import proton_app_uniffi

class ActionQueueStatusProviderSpy: ConnectionStatusProvider, ActiveAccountSendingStatusChecker {

    var connectionStatusStub: ConnectionStatus = .online
    var draftSendResultUnseenResultStub: DraftSendResultUnseenResult = .ok([])

    // MARK: - ConnectionStatusProvider

    func connectionStatus() async -> MailUserSessionConnectionStatusResult {
        .ok(connectionStatusStub)
    }

    // MARK: - ActiveAccountSendingStatusChecker

    func draftSendResultUnseen() async -> DraftSendResultUnseenResult {
        draftSendResultUnseenResultStub
    }

}

class BackgroundTaskExecutorSpy: BackgroundTaskExecutor {

    var backgroundExecutionFinishedWithSuccess = true
    var backgroundExecutionHandleStub = BackgroundExecutionHandleStub()
    var allMessagesWereSent = true
    private(set) var startBackgroundExecutionInvokeCount = 0

    // MARK: - BackgroundTaskExecutor

    func startBackgroundExecution(callback: LiveQueryCallback) -> MailSessionStartBackgroundExecutionResult {
        startBackgroundExecutionInvokeCount += 1

        if backgroundExecutionFinishedWithSuccess {
            callback.onUpdate()
        }

        return .ok(backgroundExecutionHandleStub)
    }
    
    func allMessagesWereSent() async -> Bool {
        allMessagesWereSent
    }

}

class BackgroundTransitionActionsExecutorTests: BaseTestCase {

    var sut: BackgroundTransitionActionsExecutor!
    var notificationSchedulerSpy: NotificationSchedulerSpy!
    var backgroundTransitionTaskSchedulerSpy: BackgroundTransitionTaskSchedulerSpy!
    var backgroundTaskExecutorSpy: BackgroundTaskExecutorSpy!
    var actionQueueStatusProviderSpy: ActionQueueStatusProviderSpy!

    override func setUp() {
        super.setUp()

        notificationSchedulerSpy = .init()
        backgroundTransitionTaskSchedulerSpy = .init()
        backgroundTaskExecutorSpy = .init()
        actionQueueStatusProviderSpy = .init()
        sut = .init(
            backgroundTransitionTaskScheduler: backgroundTransitionTaskSchedulerSpy,
            backgroundTaskExecutorProvider: { self.backgroundTaskExecutorSpy },
            notificationScheduller: notificationSchedulerSpy,
            actionQueueStatusProvider: { self.actionQueueStatusProviderSpy }
        )
    }

    override func tearDown() {
        notificationSchedulerSpy = nil
        backgroundTransitionTaskSchedulerSpy = nil
        backgroundTaskExecutorSpy = nil
        actionQueueStatusProviderSpy = nil
        sut = nil

        super.tearDown()
    }

    func test_WhenUserEntersBackground_ItExecutesBackgroundActionsWithSuccess() throws {
        actionQueueStatusProviderSpy.draftSendResultUnseenResultStub = .ok([.success])
        sut.enterBackgroundService()

        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedBeginBackgroundTask.count, 1)
        XCTAssertEqual(backgroundTaskExecutorSpy.startBackgroundExecutionInvokeCount, 1)
        XCTAssertEqual(notificationSchedulerSpy.invokedAdd.count, 0)
        XCTAssertEqual(
            backgroundTransitionTaskSchedulerSpy.invokedEndBackgroundTask,
            [backgroundTransitionTaskSchedulerSpy.stubbedBackgroundTaskIdentifier]
        )
    }

    func test_WhenUserEntersBackgroundAndMessageFailsToSend_ItDisplaysNotification() throws {
        actionQueueStatusProviderSpy.draftSendResultUnseenResultStub = .ok([.failure])
        sut.enterBackgroundService()

        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedBeginBackgroundTask.count, 1)
        XCTAssertEqual(backgroundTaskExecutorSpy.startBackgroundExecutionInvokeCount, 1)
        XCTAssertEqual(notificationSchedulerSpy.invokedAdd.count, 1)

        let notification = try XCTUnwrap(notificationSchedulerSpy.invokedAdd.first)

        XCTAssertEqual(notification.content.title, "Email not sent")
        XCTAssertEqual(notification.content.body, "Some emails couldn't be sent. Open the app to finish sending.")

        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedEndBackgroundTask.count, 1)
    }

    func test_WhenUserEntersBackgroundAndTimeIsUpAndMessagesAreUnsent_ItDisplaysNotification() {
        backgroundTaskExecutorSpy.allMessagesWereSent = false
        sut.enterBackgroundService()

        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedBeginBackgroundTask.count, 1)
        XCTAssertEqual(backgroundTaskExecutorSpy.startBackgroundExecutionInvokeCount, 1)
        XCTAssertEqual(notificationSchedulerSpy.invokedAdd.count, 1)
        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedEndBackgroundTask.count, 1)
    }

    @MainActor
    func test_WhenUserEntersBackgroundTaskExpiresThereAreNoMessagesToSend_ItFinishesWithSuccess() {
        backgroundTaskExecutorSpy.backgroundExecutionFinishedWithSuccess = false
        sut.enterBackgroundService()
        backgroundTransitionTaskSchedulerSpy.invokedBeginBackgroundTask.first?.handler?()

        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedBeginBackgroundTask.count, 1)
        XCTAssertEqual(backgroundTaskExecutorSpy.startBackgroundExecutionInvokeCount, 1)
        XCTAssertEqual(notificationSchedulerSpy.invokedAdd.count, 0)
        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedEndBackgroundTask.count, 1)
    }

}

extension DraftSendResult {

    static var failure: Self {
        .init(messageId: .random(), timestamp: 0, error: .failure(.other(.network)), origin: .save)
    }

    static var success: Self {
        .init(messageId: .random(), timestamp: 0, error: .success(1), origin: .save)
    }

}
