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

class ExecutePendingActionsBackgroundTaskScheduler {
    private static let identifier = "\(Bundle.defaultIdentifier).execute_pending_actions"
    private let executePendingActions: () async -> VoidSessionResult
    private let backgroundTaskRegistration: BackgroundTaskRegistration
    private let backgroundTaskScheduler: BackgroundTaskScheduler

    init(
        executePendingActions: @escaping () async -> VoidSessionResult,
        backgroundTaskRegistration: BackgroundTaskRegistration,
        backgroundTaskScheduler: BackgroundTaskScheduler
    ) {
        self.executePendingActions = executePendingActions
        self.backgroundTaskRegistration = backgroundTaskRegistration
        self.backgroundTaskScheduler = backgroundTaskScheduler
    }

    func register() {
        let isTaskDefinedInInfoPlist = backgroundTaskRegistration.registerWithIdentifier(
            Self.identifier,
            nil
        ) { [weak self] task in
            BackgroundEventsLogging.log("🎬 Task execution started")
            self?.execute(task: task)
        }
        if !isTaskDefinedInInfoPlist {
            BackgroundEventsLogging.log("📓 Missing background task identifier: <\(Self.identifier)> in the Info.plist file.")
            fatalError("Missing background task identifier: <\(Self.identifier)> in the Info.plist file.")
        }
        BackgroundEventsLogging.log("📓 Task with identifier: <\(Self.identifier)> registered.")
    }

    func submit() {
        let request = BGProcessingTaskRequest(identifier: Self.identifier)
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = DateEnvironment.currentDate().fifteenMinutesAfter
        do {
            try backgroundTaskScheduler.submit(request)
            BackgroundEventsLogging.log("🚀 Task submitted")
        } catch {
            BackgroundEventsLogging.log("👎🏻 Task submission failure: \(error)")
        }
    }

    // MARK: - Private

    private func execute(task: BackgroundTask) {
        let startTime = CFAbsoluteTimeGetCurrent()
        submit()

        task.expirationHandler = {
            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = endTime - startTime
            BackgroundEventsLogging.log("⏰ Expiration handler called, time of execution: \(executionTime) seconds")
            task.setTaskCompleted(success: true)
        }

        Task {
            BackgroundEventsLogging.log("🕺 Execute pending actions called")
            switch await executePendingActions() {
            case .ok:
                let endTime = CFAbsoluteTimeGetCurrent()
                let executionTime = endTime - startTime
                BackgroundEventsLogging.log("✅ Execute pending actions finished with success after: \(executionTime) seconds")
                task.setTaskCompleted(success: true)
            case .error(let error):
                let endTime = CFAbsoluteTimeGetCurrent()
                let executionTime = endTime - startTime
                BackgroundEventsLogging.log("❌ Execute pending actions finished with failure after: \(executionTime) seconds")
                task.setTaskCompleted(success: false)
            }
        }
    }

}

extension Date {
    var fifteenMinutesAfter: Self {
        DateEnvironment.calendar.date(byAdding: .minute, value: 15, to: self).unsafelyUnwrapped
    }
}
