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
import InboxCore
import InboxTesting
import XCTest
import proton_app_uniffi

class ExecutePendingActionsBackgroundTaskSchedulerTests: BaseTestCase {

    var sut: ExecutePendingActionsBackgroundTaskScheduler!
    var invokedRegister: [(identifier: String, handler: (BackgroundTask) -> Void)]!
    private var mailUserSessionSpy: MailUserSessionSpy!
    private var backgroundTaskScheduler: BackgroundTaskSchedulerSpy!

    override func setUp() {
        super.setUp()

        invokedRegister = []
        backgroundTaskScheduler = .init()
        mailUserSessionSpy = .init()
        sut = .init(
            userSession: { self.mailUserSessionSpy },
            backgroundTaskRegistration: .init(registerWithIdentifier: { identifier, _, handler in
                self.invokedRegister.append((identifier, handler))
                return true
            }),
            backgroundTaskScheduler: backgroundTaskScheduler
        )
    }

    override func tearDown() {
        sut = nil
        backgroundTaskScheduler = nil
        invokedRegister = nil
        mailUserSessionSpy = nil

        super.tearDown()
    }

    func test_WhenTaskIsRegistered_WhenTaskIsExecuted_WhenActionsFinishWithSuccess_ItCompletesWithSuccess() throws {
        sut.register()

        let taskRegistration = try XCTUnwrap(invokedRegister.first)
        XCTAssertEqual(invokedRegister.count, 1)
        XCTAssertEqual(taskRegistration.identifier, "ch.protonmail.protonmail.execute_pending_actions")

        submitTask()

        XCTAssertEqual(backgroundTaskScheduler.invokedSubmit.count, 1)
        let submittedTaskRequest = try XCTUnwrap(backgroundTaskScheduler.invokedSubmit.first)
        let submittedProcessingTaskRequest = try XCTUnwrap(submittedTaskRequest as? BGProcessingTaskRequest)
        XCTAssertFalse(submittedProcessingTaskRequest.requiresExternalPower)
        XCTAssertTrue(submittedProcessingTaskRequest.requiresNetworkConnectivity)

        let backgroundTask = BackgroundTaskSpy()
        try execute(task: backgroundTask)

        XCTAssertEqual(mailUserSessionSpy.pollEventInvokeCount, 1)
        XCTAssertEqual(mailUserSessionSpy.executePendingActionsInvokeCount, 1)

        XCTAssertEqual(backgroundTaskScheduler.invokedSubmit.count, 2)
        XCTAssertTrue(backgroundTask.didCompleteWithSuccess)
    }

    func test_WhenActionsFinishWithFailure_ItCompletesWithFailure() throws {
        sut.register()
        submitTask()

        let taskRegistration = try XCTUnwrap(invokedRegister.first)
        let backgroundTask = BackgroundTaskSpy()
        mailUserSessionSpy.pendingActionsExecutionResultStub = .error(.other(.network))
        mailUserSessionSpy.pollEventsResultStub = .error(.other(.network))
        try execute(task: backgroundTask)

        XCTAssertFalse(backgroundTask.didCompleteWithSuccess)
    }

    func test_WhenTwoTasksAreSubmitted_ItSchedulesOnlyOne() {
        sut.register()
        submitTask()
        submitTask()

        XCTAssertEqual(backgroundTaskScheduler.invokedSubmit.count, 1)
    }

    func test_WhenCancelIsCalled_ItCancelsTask() {
        sut.register()
        submitTask()
        sut.cancel()

        XCTAssertEqual(backgroundTaskScheduler.invokedCancel, ["ch.protonmail.protonmail.execute_pending_actions"])
    }

    // MARK: - Private

    private func submitTask() {
        sut.submit()
        backgroundTaskScheduler.pendingTaskRequestsStub = [backgroundTaskScheduler.invokedSubmit.last].compactMap { $0 }
    }

    private func execute(task: BackgroundTask) throws {
        let taskRegistration = try XCTUnwrap(invokedRegister.first)
        backgroundTaskScheduler.pendingTaskRequestsStub = []
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

private class MailUserSessionSpy: MailUserSessionProtocol {

    var pendingActionsExecutionResultStub = VoidSessionResult.ok
    var pollEventsResultStub = VoidEventResult.ok

    private(set) var pollEventInvokeCount = 0
    private(set) var executePendingActionsInvokeCount = 0

    // MARK: - MailUserSessionProtocol

    func pollEvents() async -> VoidEventResult {
        pollEventInvokeCount += 1

        return pollEventsResultStub
    }

    func executePendingActions() async -> VoidSessionResult {
        executePendingActionsInvokeCount += 1

        return pendingActionsExecutionResultStub
    }

    func accountDetails() async -> MailUserSessionAccountDetailsResult {
        fatalError()
    }

    func applicableLabels() async -> MailUserSessionApplicableLabelsResult {
        fatalError()
    }

    func connectionStatus() async -> MailUserSessionConnectionStatusResult {
        fatalError()
    }

    func executePendingAction() async -> VoidSessionResult {
        fatalError()
    }

    func fork() async -> MailUserSessionForkResult {
        fatalError()
    }

    func getAttachment(localAttachmentId: Id) async -> MailUserSessionGetAttachmentResult {
        fatalError()
    }

    func imageForSender(
        address: String,
        bimiSelector: String?,
        displaySenderImage: Bool,
        size: UInt32?,
        mode: String?,
        format: String?
    ) async -> MailUserSessionImageForSenderResult {
        fatalError()
    }

    func initialize(cb: any MailUserSessionInitializationCallback) async -> VoidSessionResult {
        fatalError()
    }

    func logout() async -> VoidSessionResult {
        fatalError()
    }

    func movableFolders() async -> MailUserSessionMovableFoldersResult {
        fatalError()
    }

    func observeEventLoopErrors(callback: any EventLoopErrorObserver) -> EventLoopErrorObserverHandle {
        fatalError()
    }

    func sessionId() -> String {
        fatalError()
    }

    func user() async -> MailUserSessionUserResult {
        fatalError()
    }

    func userId() -> String {
        fatalError()
    }

}
