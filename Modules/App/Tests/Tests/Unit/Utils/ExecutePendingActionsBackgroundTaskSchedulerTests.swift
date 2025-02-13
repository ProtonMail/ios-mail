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
    var mailUserSessionSpy: MailUserSessionSpy!
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

    func test_flowOfTaskRegistrationSubmissionAndSuccessExecution() throws {
        sut.register()

        let taskRegistration = try XCTUnwrap(invokedRegister.first)
        XCTAssertEqual(invokedRegister.count, 1)
        XCTAssertEqual(taskRegistration.identifier, "ch.protonmail.protonmail.execute_pending_actions")

        sut.submit()

        XCTAssertEqual(backgroundTaskScheduler.invokedSubmit.count, 1)
        let submittedTaskRequest = try XCTUnwrap(backgroundTaskScheduler.invokedSubmit.first)
        let submittedProcessingTaskRequest = try XCTUnwrap(submittedTaskRequest as? BGProcessingTaskRequest)
        XCTAssertFalse(submittedProcessingTaskRequest.requiresExternalPower)
        XCTAssertTrue(submittedProcessingTaskRequest.requiresNetworkConnectivity)

        let backgroundTask = BackgroundTaskSpy()
        taskRegistration.handler(backgroundTask)

        XCTAssertEqual(mailUserSessionSpy.pollEventInvokeCount, 1)
        XCTAssertEqual(mailUserSessionSpy.executePendingActionsInvokeCount, 1)

        XCTAssertEqual(backgroundTaskScheduler.invokedSubmit.count, 2)
        XCTAssertTrue(backgroundTask.didCompleteWithSuccess)
    }

    func test_taskExecutionFailure() throws {
        sut.register()
        sut.submit()

        let taskRegistration = try XCTUnwrap(invokedRegister.first)
        let backgroundTask = BackgroundTaskSpy()
        mailUserSessionSpy.pendingActionsExecutionResultStub = .error(.other(.network))
        mailUserSessionSpy.pollEventsResultStub = .error(.other(.network))
        taskRegistration.handler(backgroundTask)

        XCTAssertFalse(backgroundTask.didCompleteWithSuccess)
    }

}

private class BackgroundTaskSchedulerSpy: BackgroundTaskScheduler {
    private(set) var invokedSubmit: [BGTaskRequest] = []

    func submit(_ taskRequest: BGTaskRequest) throws {
        invokedSubmit.append(taskRequest)
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
