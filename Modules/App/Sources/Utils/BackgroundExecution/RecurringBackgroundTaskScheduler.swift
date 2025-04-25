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

import Combine
import BackgroundTasks
import InboxCore
import proton_app_uniffi

class RecurringBackgroundTaskScheduler: @unchecked Sendable {
    typealias BackgroundTaskExecutorProvider = () -> BackgroundTaskExecutor
    private static let identifier = "\(Bundle.defaultIdentifier).execute_pending_actions"
    private let sessionState: AnyPublisher<SessionState, Never>
    private let timerFactory: TimerPublisherFactory
    private let backgroundTaskRegistration: BackgroundTaskRegistration
    private let backgroundTaskScheduler: BackgroundTaskScheduler
    private let backgroundTaskExecutorProvider: BackgroundTaskExecutorProvider
    private var callback: BackgroundExecutionCallbackWrapper!
    private let backgroundTaskExpired = PassthroughSubject<Void, Never>()
    private var sessionSetUpCheckCancellable: AnyCancellable?

    convenience init(backgroundTaskExecutorProvider: @escaping BackgroundTaskExecutorProvider) {
        self.init(
            backgroundTaskRegistration: .init(registerWithIdentifier: BGTaskScheduler.shared.register),
            backgroundTaskScheduler: BGTaskScheduler.shared,
            backgroundTaskExecutorProvider: backgroundTaskExecutorProvider
        )
    }

    init(
        sessionState: AnyPublisher<SessionState, Never> = AppContext.shared.$sessionState.eraseToAnyPublisher(),
        timerFactory: @escaping TimerPublisherFactory = TimerFactory.make,
        backgroundTaskRegistration: BackgroundTaskRegistration,
        backgroundTaskScheduler: BackgroundTaskScheduler,
        backgroundTaskExecutorProvider: @escaping BackgroundTaskExecutorProvider
    ) {
        self.sessionState = sessionState
        self.timerFactory = timerFactory
        self.backgroundTaskRegistration = backgroundTaskRegistration
        self.backgroundTaskScheduler = backgroundTaskScheduler
        self.backgroundTaskExecutorProvider = backgroundTaskExecutorProvider
    }

    func register() {
        let isTaskDefinedInInfoPlist = backgroundTaskRegistration.registerWithIdentifier(
            Self.identifier,
            nil
        ) { task in
            Task { [weak self] in
                log("Background task execution started")
                await self?.execute(task: task)
            }
        }
        if !isTaskDefinedInInfoPlist {
            fatalError("Missing background task identifier: <\(Self.identifier)> in the Info.plist file.")
        }
        log("Background task registered")
    }

    func submit() async {
        let allTaskRequests = await backgroundTaskScheduler.pendingTaskRequests()
        let isTaskSchedulled = allTaskRequests
            .contains(where: { request in request.identifier == Self.identifier })
        guard !isTaskSchedulled else {
            return
        }

        do {
            try backgroundTaskScheduler.submit(taskRequest)
            log("Background task submitted")
        } catch {
            log("Background task failed to submit, because of error: \(error.localizedDescription)")
        }
    }

    func cancel() {
        backgroundTaskScheduler.cancel(taskRequestWithIdentifier: Self.identifier)
    }

    // MARK: - Private

    private func execute(task: BackgroundTask) async {
        await submit()

        callback = .init { [weak self] completionStatus in
            self?.backgroundExecutionHasCompleted(completionStatus: completionStatus, task: task)
        }

        do {
            let handle = try backgroundTaskExecutorProvider().startBackgroundExecution(callback: callback).get()
            log("Handle is returned, background actions in progress")

            task.expirationHandler = { [weak self, handle] in
                Task {
                    log("Background task expiration handler called")
                    self?.backgroundTaskExpired.send()
                    await handle.abort(inForeground: false)
                }
            }
        } catch {
            log("Background execution failed to start: \(error.localizedDescription)")
        }
    }

    private var taskRequest: BGProcessingTaskRequest {
        let request = BGProcessingTaskRequest(identifier: Self.identifier)
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = DateEnvironment.currentDate().thirthyMinutesAfter
        return request
    }

    private func backgroundExecutionHasCompleted(completionStatus: BackgroundExecutionStatus, task: BackgroundTask) {
        switch completionStatus {
        case .skippedNoActiveContexts:
            log("Waiting for session to set up. Completion status: \(completionStatus)")
            checkForSessionSetUpToComplete { [task] in
                log("Background task finished after the session set up")
                task.setTaskCompleted(success: true)
            }
        case .timedOut, .failed, .executed, .abortedInForeground, .abortedInBackground:
            log("Background task finished with: \(completionStatus)")
            task.setTaskCompleted(success: true)
        }
    }

    private func checkForSessionSetUpToComplete(completion: @Sendable @escaping () -> Void) {
        sessionSetUpCheckCancellable = Publishers
            .CombineLatest(sessionState, timerFactory(0.5))
            .map { sessionState, _ in sessionState }
            .prefix(untilOutputFrom: backgroundTaskExpired)
            .filter { sessionState in sessionState.isSessionSetUp }
            .first()
            .sink(
                receiveCompletion: { _ in completion() },
                receiveValue: { _ in }
            )
    }

}

private func log(_ message: String) {
    AppLogger.log(message: message, category: .recurringBackgroundTask)
}

extension Date {
    var thirthyMinutesAfter: Self {
        DateEnvironment.calendar.date(byAdding: .minute, value: 30, to: self).unsafelyUnwrapped
    }
}

private extension SessionState {

    var isSessionSetUp: Bool {
        switch self {
        case .noSession:
            false
        case .activeSession, .activeSessionTransition:
            true
        }
    }

}
