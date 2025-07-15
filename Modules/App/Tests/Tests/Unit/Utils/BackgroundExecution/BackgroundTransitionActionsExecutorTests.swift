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
import proton_app_uniffi
import InboxTesting
import XCTest

class BackgroundTransitionActionsExecutorTests: BaseTestCase {

    var sut: BackgroundTransitionActionsExecutor!
    var backgroundTransitionTaskSchedulerSpy: BackgroundTransitionTaskSchedulerSpy!
    var backgroundTaskExecutorSpy: BackgroundTaskExecutorSpy!
    var actionQueueStatusProviderSpy: ActionQueueStatusProviderSpy!
    private var notificationSchedulerSpy: NotificationSchedulerSpy!

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

    func test_WhenUserEntersBackgroundAndEntersForeground_ItEndsBackgroundTask() {
        backgroundTaskExecutorSpy.backgroundExecutionFinishedWithSuccess = false
        backgroundTaskExecutorSpy.executionCompletedWithResult = BackgroundExecutionResult(status: .abortedInForeground, hasUnsentMessages: false)

        sut.didEnterBackground()
        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedBeginBackgroundTask.count, 1)

        sut.willEnterForeground()
        XCTAssertEqual(backgroundTaskExecutorSpy.backgroundExecutionHandleStub.abortCalls, [true])
        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedEndBackgroundTask.count, 1)
        XCTAssertEqual(notificationSchedulerSpy.invokedAdd.count, 0)
    }

    func test_WhenUserEntersBackground_ItExecutesBackgroundActionsWithSuccess() throws {
        actionQueueStatusProviderSpy.draftSendResultUnseenResultStub = .ok([.success])
        backgroundTaskExecutorSpy.executionCompletedWithResult = BackgroundExecutionResult(status: .abortedInForeground, hasUnsentMessages: false)
        sut.didEnterBackground()

        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedBeginBackgroundTask.count, 1)
        XCTAssertEqual(backgroundTaskExecutorSpy.startBackgroundExecutionInvokeCount, 1)
        XCTAssertEqual(notificationSchedulerSpy.invokedAdd.count, 0)
        XCTAssertEqual(
            backgroundTransitionTaskSchedulerSpy.invokedEndBackgroundTask,
            [backgroundTransitionTaskSchedulerSpy.stubbedBackgroundTaskIdentifier]
        )
    }

    func test_WhenUserEntersBackgroundAndTimeIsUpAndMessagesAreUnsent_ItDisplaysNotification() {
        backgroundTaskExecutorSpy.executionCompletedWithResult = BackgroundExecutionResult(status: .abortedInBackground, hasUnsentMessages: true)

        sut.didEnterBackground()

        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedBeginBackgroundTask.count, 1)
        XCTAssertEqual(backgroundTaskExecutorSpy.startBackgroundExecutionInvokeCount, 1)

        XCTAssertEqual(notificationSchedulerSpy.invokedAdd.count, 1)
        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedEndBackgroundTask.count, 1)
    }

    @MainActor
    func test_WhenUserEntersBackgroundTaskExpiresThereAreNoMessagesToSend_ItFinishesWithSuccess() {
        backgroundTaskExecutorSpy.backgroundExecutionFinishedWithSuccess = false
        backgroundTaskExecutorSpy.executionCompletedWithResult = BackgroundExecutionResult(status: .abortedInBackground, hasUnsentMessages: false)

        sut.didEnterBackground()
        backgroundTransitionTaskSchedulerSpy.invokedBeginBackgroundTask.first?.handler?()

        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedBeginBackgroundTask.count, 1)
        XCTAssertEqual(backgroundTaskExecutorSpy.startBackgroundExecutionInvokeCount, 1)
        XCTAssertEqual(notificationSchedulerSpy.invokedAdd.count, 0)
        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedEndBackgroundTask.count, 1)
    }

}

private extension DraftSendResult {

    static var success: Self {
        .init(
            messageId: .random(),
            timestamp: 0,
            error: .success(secondsUntilCancel: 1, deliveryTime: UInt64(Date().timeIntervalSince1970) + 3600),
            origin: .save
        )
    }

}

private class NotificationSchedulerSpy: NotificationScheduler {

    private(set) var invokedAdd: [UNNotificationRequest] = []

    // MARK: - NotificationScheduler

    func add(_ request: UNNotificationRequest) async throws {
        invokedAdd.append(request)
    }

}
