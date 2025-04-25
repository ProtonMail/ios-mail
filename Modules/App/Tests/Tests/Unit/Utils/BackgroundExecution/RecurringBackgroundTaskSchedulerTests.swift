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
import BackgroundTasks
import Combine
import InboxCore
import InboxTesting
import XCTest
import proton_app_uniffi

class RecurringBackgroundTaskSchedulerTests: BaseTestCase {

    var sut: RecurringBackgroundTaskScheduler!
    var invokedRegister: [(identifier: String, handler: (BackgroundTask) -> Void)]!
    var invokedTimerFactoryWithInterval: [TimeInterval] = []
    var timerSubject: PassthroughSubject<Void, Never>!
    var sessionStateSubject: CurrentValueSubject<SessionState, Never>!
    private var backgroundTaskExecutorSpy: BackgroundTaskExecutorSpy!
    private var backgroundTaskSchedulerSpy: BackgroundTaskSchedulerSpy!

    override func setUp() {
        super.setUp()

        invokedRegister = []
        backgroundTaskSchedulerSpy = .init()
        backgroundTaskExecutorSpy = .init()
        timerSubject = .init()
        sessionStateSubject = .init(.noSession)
        sut = .init(
            sessionState: sessionStateSubject.eraseToAnyPublisher(),
            timerFactory: { timeInterval in
                self.invokedTimerFactoryWithInterval.append(timeInterval)
                return self.timerSubject.eraseToAnyPublisher()
            },
            backgroundTaskRegistration: .init(registerWithIdentifier: { identifier, _, handler in
                self.invokedRegister.append((identifier, handler))
                return true
            }),
            backgroundTaskScheduler: backgroundTaskSchedulerSpy,
            backgroundTaskExecutorProvider: { self.backgroundTaskExecutorSpy }
        )
    }

    override func tearDown() {
        sut = nil
        backgroundTaskSchedulerSpy = nil
        invokedRegister = nil
        backgroundTaskExecutorSpy = nil

        super.tearDown()
    }

    func test_WhenTaskIsRegisteredAndExecuted_WhenActionsFinishWithSuccess_ItCompletesWithSuccess() async throws {
        sut.register()
        backgroundTaskExecutorSpy.backgroundExecutionFinishedWithSuccess = true
        backgroundTaskExecutorSpy.executionCompletedWithStatus = .executed

        let taskRegistration = try XCTUnwrap(invokedRegister.first)
        XCTAssertEqual(invokedRegister.count, 1)
        XCTAssertEqual(taskRegistration.identifier, "ch.protonmail.protonmail.execute_pending_actions")

        await submitTask()

        XCTAssertEqual(backgroundTaskSchedulerSpy.invokedSubmit.count, 1)
        let submittedTaskRequest = try XCTUnwrap(backgroundTaskSchedulerSpy.invokedSubmit.first)
        let submittedProcessingTaskRequest = try XCTUnwrap(submittedTaskRequest as? BGProcessingTaskRequest)
        XCTAssertFalse(submittedProcessingTaskRequest.requiresExternalPower)
        XCTAssertTrue(submittedProcessingTaskRequest.requiresNetworkConnectivity)

        let backgroundTask = BackgroundTaskSpy()
        try execute(task: backgroundTask)

        XCTAssertEqual(backgroundTaskExecutorSpy.startBackgroundExecutionInvokeCount, 1)

        XCTAssertEqual(backgroundTaskSchedulerSpy.invokedSubmit.count, 2)
        XCTAssertTrue(backgroundTask.didCompleteWithSuccess)
    }

    func test_WhenTaskIsRegisteredAndExecuted_WhenAbortIsCalled_ItCompletesWithSuccess() async throws {
        sut.register()
        backgroundTaskExecutorSpy.backgroundExecutionFinishedWithSuccess = false
        backgroundTaskExecutorSpy.executionCompletedWithStatus = .abortedInBackground

        await submitTask()

        let backgroundTask = BackgroundTaskSpy()
        try execute(task: backgroundTask)
        backgroundTask.expirationHandler?()

        XCTAssertEqual(backgroundTaskExecutorSpy.backgroundExecutionHandleStub.abortCalls, [false])
        XCTAssertEqual(backgroundTaskExecutorSpy.startBackgroundExecutionInvokeCount, 1)
        XCTAssertTrue(backgroundTask.didCompleteWithSuccess)
    }

    func test_WhenTaskFinishesImmidiatelyWithSkippedNoActiveContextsResult_ItWaitsForSessionToConfigure() async throws {
        sut.register()
        backgroundTaskExecutorSpy.backgroundExecutionFinishedWithSuccess = false
        backgroundTaskExecutorSpy.executionCompletedWithStatus = .skippedNoActiveContexts

        await submitTask()

        let backgroundTask = BackgroundTaskSpy()
        try execute(task: backgroundTask)

        XCTAssertEqual(invokedTimerFactoryWithInterval, [0.5])
        XCTAssertFalse(backgroundTask.didCompleteWithSuccess)

        timerSubject.send()

        XCTAssertFalse(backgroundTask.didCompleteWithSuccess)

        sessionStateSubject.send(.activeSession(session: .dummy))

        XCTAssertTrue(backgroundTask.didCompleteWithSuccess)
    }

    func test_WhenTaskFinishesWithSkippedNoActiveContextsResult_WhenTaskExpiredWhenWaiting_ItFinishesTask() async throws {
        sut.register()
        backgroundTaskExecutorSpy.backgroundExecutionFinishedWithSuccess = false
        backgroundTaskExecutorSpy.executionCompletedWithStatus = .skippedNoActiveContexts

        await submitTask()

        let backgroundTask = BackgroundTaskSpy()
        try execute(task: backgroundTask)

        XCTAssertEqual(invokedTimerFactoryWithInterval, [0.5])
        XCTAssertFalse(backgroundTask.didCompleteWithSuccess)

        timerSubject.send()

        XCTAssertFalse(backgroundTask.didCompleteWithSuccess)

        backgroundTask.expirationHandler?()

        XCTAssertTrue(backgroundTask.didCompleteWithSuccess)
    }

    func test_WhenTwoTasksAreSubmitted_ItSchedulesOnlyOne() async {
        sut.register()
        await submitTask()
        await submitTask()

        XCTAssertEqual(backgroundTaskSchedulerSpy.invokedSubmit.count, 1)
    }

    func test_WhenCancelIsCalled_ItCancelsTask() async {
        sut.register()
        await submitTask()
        sut.cancel()

        XCTAssertEqual(backgroundTaskSchedulerSpy.invokedCancel, ["ch.protonmail.protonmail.execute_pending_actions"])
    }

    // MARK: - Private

    private func submitTask() async {
        await sut.submit()
        backgroundTaskSchedulerSpy.pendingTaskRequestsStub = [backgroundTaskSchedulerSpy.invokedSubmit.last].compactMap { $0 }
    }

    private func execute(task: BackgroundTask) throws {
        let taskRegistration = try XCTUnwrap(invokedRegister.first)
        backgroundTaskSchedulerSpy.pendingTaskRequestsStub = []
        taskRegistration.handler(task)
    }

}

private class BackgroundTaskSchedulerSpy: BackgroundTaskScheduler {

    var pendingTaskRequestsStub: [BGTaskRequest] = []
    private(set) var invokedCancel: [String] = []
    private(set) var invokedSubmit: [BGTaskRequest] = []

    // MARK: - BackgroundTaskScheduler

    func submit(_ taskRequest: BGTaskRequest) throws {
        invokedSubmit.append(taskRequest)
    }

    func pendingTaskRequests() async -> [BGTaskRequest] {
        pendingTaskRequestsStub
    }

    func cancel(taskRequestWithIdentifier identifier: String) {
        invokedCancel.append(identifier)
    }
}

private class BackgroundTaskSpy: BackgroundTask {

    var didCompleteWithSuccess: Bool = false

    // MARK: - BackgroundTask

    var expirationHandler: (() -> Void)?

    func setTaskCompleted(success: Bool) {
        didCompleteWithSuccess = success
    }

}

class BackgroundExecutionHandleStub: BackgroundExecutionHandle, @unchecked Sendable {

    private(set) var abortCalls: [Bool] = []

    init() {
        super.init(noPointer: .init())
    }
    
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    // MARK: - BackgroundExecutionHandle

    override func abort(inForeground: Bool) async {
        abortCalls.append(inForeground)
    }

}
