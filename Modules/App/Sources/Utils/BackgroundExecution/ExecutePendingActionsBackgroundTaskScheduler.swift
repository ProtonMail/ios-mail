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

import BackgroundTasks
import InboxCore
import proton_app_uniffi

// FIXME: - Rename
class ExecutePendingActionsBackgroundTaskScheduler: @unchecked Sendable {
    typealias BackgroundTaskExecutorProvider = () -> BackgroundTaskExecutor
    private static let identifier = "\(Bundle.defaultIdentifier).execute_pending_actions"
    private let backgroundTaskRegistration: BackgroundTaskRegistration
    private let backgroundTaskScheduler: BackgroundTaskScheduler
    private let backgroundTaskExecutorProvider: BackgroundTaskExecutorProvider
    private let callback = LiveQueryCallbackWrapper()

    convenience init(backgroundTaskExecutorProvider: @escaping BackgroundTaskExecutorProvider) {
        self.init(
            backgroundTaskRegistration: .init(registerWithIdentifier: BGTaskScheduler.shared.register),
            backgroundTaskScheduler: BGTaskScheduler.shared,
            backgroundTaskExecutorProvider: backgroundTaskExecutorProvider
        )
    }

    init(
        backgroundTaskRegistration: BackgroundTaskRegistration,
        backgroundTaskScheduler: BackgroundTaskScheduler,
        backgroundTaskExecutorProvider: @escaping BackgroundTaskExecutorProvider
    ) {
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
                Self.log("Background task execution started")
                await self?.execute(task: task)
            }
        }
        if !isTaskDefinedInInfoPlist {
            fatalError("Missing background task identifier: <\(Self.identifier)> in the Info.plist file.")
        }
        Self.log("Background task registered")
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
            Self.log("Background task submitted")
        } catch {
            Self.log("Background task failed to submit, because of error: \(error.localizedDescription)")
        }
    }

    func cancel() {
        backgroundTaskScheduler.cancel(taskRequestWithIdentifier: Self.identifier)
    }

    // MARK: - Private

    private func execute(task: BackgroundTask) async {
        await submit()

        callback.delegate = {
            Self.log("Background task finished with success")
            task.setTaskCompleted(success: true)
        }

        let handler = await backgroundTaskExecutorProvider().startExecuteInBackground(callback: callback)

        task.expirationHandler = { [handler] in
            Task {
                Self.log("Background task expiration handler called")
                await handler.abort()
                task.setTaskCompleted(success: true)
            }
        }
    }

    private var taskRequest: BGProcessingTaskRequest {
        let request = BGProcessingTaskRequest(identifier: Self.identifier)
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = DateEnvironment.currentDate().thirthyMinutesAfter
        return request
    }

    private static func log(_ message: String) {
        AppLogger.log(message: message, category: .recurringBackgroundTask)
    }

}

extension Date {
    var thirthyMinutesAfter: Self {
        DateEnvironment.calendar.date(byAdding: .minute, value: 30, to: self).unsafelyUnwrapped
    }
}
