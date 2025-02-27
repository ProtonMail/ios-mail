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

protocol BackgroundTaskExecutor {
    func startExecuteInBackground() async
    func endExecuteInBackground() async
}

extension MailSession: BackgroundTaskExecutor {
    func startExecuteInBackground() async {}
    func endExecuteInBackground() async {}
}

protocol ConnectionStatusProvider {
    func isNetworkConnected() -> Bool
}

protocol ActionQueueManager {
    func areSendingActionsInActionQueue() async -> Bool
}

protocol NotificationScheduller {
    func add(_ request: UNNotificationRequest) async throws
}

extension UNUserNotificationCenter: NotificationScheduller {}

extension MailSession: ConnectionStatusProvider {}

class BackgroundTransitionActionsExecutor_v2: ApplicationServiceDidEnterBackground, @unchecked Sendable {

    static let taskName = "finish_pending_actions"
    private let backgroundTransitionTaskScheduler: BackgroundTransitionTaskScheduler
    private let backgroundTaskExecutor: BackgroundTaskExecutor
    private let connectionStatusProvider: ConnectionStatusProvider
    private let actionQueueManager: ActionQueueManager

    // Store the task identifier as an instance property.
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?

    init(
        backgroundTransitionTaskScheduler: BackgroundTransitionTaskScheduler,
        backgroundTaskExecutor: BackgroundTaskExecutor,
        connectionStatusProvider: ConnectionStatusProvider,
        actionQueueManager: ActionQueueManager
    ) {
        self.backgroundTransitionTaskScheduler = backgroundTransitionTaskScheduler
        self.backgroundTaskExecutor = backgroundTaskExecutor
        self.connectionStatusProvider = connectionStatusProvider
        self.actionQueueManager = actionQueueManager
    }

    func enterBackgroundService() {
        Task {
            let accessToInternetOnStart = connectionStatusProvider.isNetworkConnected()
            backgroundTaskIdentifier = backgroundTransitionTaskScheduler.beginBackgroundTask(
                withName: Self.taskName,
                expirationHandler: { [weak self] in
                    self?.endBackgroundTask(accessToInternetOnStart: accessToInternetOnStart)
                }
            )

            await backgroundTaskExecutor.startExecuteInBackground()

            endBackgroundTask(accessToInternetOnStart: accessToInternetOnStart)
        }
    }

    private func endBackgroundTask(accessToInternetOnStart: Bool) {
        guard let backgroundTaskIdentifier else { return }
        Task {
            let accessToInternetOnEnd = connectionStatusProvider.isNetworkConnected()
            let offline = !accessToInternetOnEnd && !accessToInternetOnStart
            await backgroundTaskExecutor.endExecuteInBackground()
            let areSendingActionsInActionQueue = await actionQueueManager.areSendingActionsInActionQueue()

//            let checkIfEmailFailedToSend

            if areSendingActionsInActionQueue && !offline {
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

}
