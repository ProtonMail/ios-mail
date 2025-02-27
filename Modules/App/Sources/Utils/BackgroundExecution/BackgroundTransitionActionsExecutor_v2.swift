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

import proton_app_uniffi
import UIKit

protocol NotificationScheduller {
    func add(_ request: UNNotificationRequest) async throws
}

// Mail Session

class StartBackgroundExecutionHandler {
    func abort() {}
}

protocol BackgroundTaskExecutor {
    func startExecuteInBackground() async -> StartBackgroundExecutionHandler
    func areSendingActionsInActionQueue() async -> [ID]
}

extension MailSession: BackgroundTaskExecutor {
    func startExecuteInBackground() async -> StartBackgroundExecutionHandler { .init() }
    func areSendingActionsInActionQueue() async -> [ID] { [] }
}

// Mail User Session

protocol ActiveAccountSendingStatusChecker {
    func draftSendResultUnseen() async -> DraftSendResultUnseenResult
}

protocol ConnectionStatusProvider {
    func connectionStatus() async -> MailUserSessionConnectionStatusResult
}

extension MailUserSession: ActiveAccountSendingStatusChecker {
    func draftSendResultUnseen() async -> DraftSendResultUnseenResult {
        await proton_app_uniffi.draftSendResultUnseen(session: self)
    }
}

extension UNUserNotificationCenter: NotificationScheduller {}
extension MailUserSession: ConnectionStatusProvider {}

class BackgroundTransitionActionsExecutor_v2: ApplicationServiceDidEnterBackground, @unchecked Sendable {

    typealias ActionQueueStatusProvider = () -> ConnectionStatusProvider & ActiveAccountSendingStatusChecker

    static let taskName = "finish_pending_actions"
    private let backgroundTransitionTaskScheduler: BackgroundTransitionTaskScheduler
    private let backgroundTaskExecutor: BackgroundTaskExecutor
    private let actionQueueStatusProvider: ActionQueueStatusProvider

    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    private var accessToInternetOnStart: Bool?
    private var backgroundExecutionHandler: StartBackgroundExecutionHandler?

    init(
        backgroundTransitionTaskScheduler: BackgroundTransitionTaskScheduler,
        backgroundTaskExecutor: BackgroundTaskExecutor,
        actionQueueStatusProvider: @escaping ActionQueueStatusProvider
    ) {
        self.backgroundTransitionTaskScheduler = backgroundTransitionTaskScheduler
        self.backgroundTaskExecutor = backgroundTaskExecutor
        self.actionQueueStatusProvider = actionQueueStatusProvider
    }

    func enterBackgroundService() {
        backgroundTaskIdentifier = backgroundTransitionTaskScheduler.beginBackgroundTask(
            withName: Self.taskName,
            expirationHandler: { [weak self] in
                self?.endBackgroundTask()
            }
        )

        Task {
            let actionQueueStatusProvider = actionQueueStatusProvider()
            accessToInternetOnStart = await actionQueueStatusProvider.connectionStatus().isConnected
            backgroundExecutionHandler = await backgroundTaskExecutor.startExecuteInBackground()
            endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        guard let backgroundTaskIdentifier, let backgroundExecutionHandler else { return }
        Task {
            let accessToInternetOnEnd = await actionQueueStatusProvider().connectionStatus().isConnected
            backgroundExecutionHandler.abort()
            let areSendingActionsInActionQueue = await !backgroundTaskExecutor.areSendingActionsInActionQueue().isEmpty
            let anyActiveAccountMessageFailedToSend = await hasAnyMessageFailedToSend()

            let offline = !accessToInternetOnEnd && accessToInternetOnStart == false

            if anyActiveAccountMessageFailedToSend && !offline {
                scheduleLocalNotification()
            } else if areSendingActionsInActionQueue && !offline {
                scheduleLocalNotification()
            }

            backgroundTransitionTaskScheduler.endBackgroundTask(backgroundTaskIdentifier)
        }
    }

    private func scheduleLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Email sending error".notLocalized
        content.body = "We were not able to send your message, enter foreground to continue".notLocalized
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "sending_failure", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func hasAnyMessageFailedToSend() async -> Bool {
        switch await actionQueueStatusProvider().draftSendResultUnseen() {
        case .ok(let results):
            results.first(where: { $0.failedToSend }) != nil
        case .error:
            false
        }
    }

}

private extension MailUserSessionConnectionStatusResult {

    var isConnected: Bool {
        switch self {
        case .ok(let connectionStatus):
            connectionStatus == .online
        case .error:
            false
        }
    }

}

private extension DraftSendResult {

    var failedToSend: Bool {
        switch error {
        case .success:
            false
        case .failure:
            true
        }
    }

}
