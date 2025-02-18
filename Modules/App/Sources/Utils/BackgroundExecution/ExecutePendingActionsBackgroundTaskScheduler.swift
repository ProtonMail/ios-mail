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

class ExecutePendingActionsBackgroundTaskScheduler: @unchecked Sendable {
    private static let identifier = "\(Bundle.defaultIdentifier).execute_pending_actions"
    private let userSession: () -> MailUserSessionProtocol?
    private let backgroundTaskRegistration: BackgroundTaskRegistration
    private let backgroundTaskScheduler: BackgroundTaskScheduler

    convenience init(userSession: @escaping () -> MailUserSessionProtocol?) {
        self.init(
            userSession: userSession,
            backgroundTaskRegistration: .init(registerWithIdentifier: BGTaskScheduler.shared.register),
            backgroundTaskScheduler: BGTaskScheduler.shared
        )
    }

    init(
        userSession: @escaping () -> MailUserSessionProtocol?,
        backgroundTaskRegistration: BackgroundTaskRegistration,
        backgroundTaskScheduler: BackgroundTaskScheduler
    ) {
        self.userSession = userSession
        self.backgroundTaskRegistration = backgroundTaskRegistration
        self.backgroundTaskScheduler = backgroundTaskScheduler
    }

    func register() {
        let isTaskDefinedInInfoPlist = backgroundTaskRegistration.registerWithIdentifier(
            Self.identifier,
            nil
        ) { [weak self] task in
            self?.execute(task: task)
        }
        if !isTaskDefinedInInfoPlist {
            fatalError("Missing background task identifier: <\(Self.identifier)> in the Info.plist file.")
        }
    }

    func submit() {
        Task {
            let allTaskRequests = await backgroundTaskScheduler.pendingTaskRequests()
            let isTaskSchedulled = allTaskRequests
                .contains(where: { request in request.identifier == Self.identifier })
            guard !isTaskSchedulled else {
                return
            }

            do {
                try backgroundTaskScheduler.submit(taskRequest)
            } catch {
                AppLogger.log(error: error)
            }
        }
    }

    func cancel() {
        backgroundTaskScheduler.cancel(taskRequestWithIdentifier: Self.identifier)
    }

    // MARK: - Private

    private func execute(task: BackgroundTask) {
        guard let userSession = userSession() else {
            task.setTaskCompleted(success: false)
            return
        }

        submit()

        task.expirationHandler = {
            task.setTaskCompleted(success: true)
        }

        Task {
            switch (await userSession.executePendingActions(), await userSession.pollEvents()) {
            case (.ok, .ok):
                task.setTaskCompleted(success: true)
            default:
                task.setTaskCompleted(success: false)
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

}

extension Date {
    var thirthyMinutesAfter: Self {
        DateEnvironment.calendar.date(byAdding: .minute, value: 30, to: self).unsafelyUnwrapped
    }
}
