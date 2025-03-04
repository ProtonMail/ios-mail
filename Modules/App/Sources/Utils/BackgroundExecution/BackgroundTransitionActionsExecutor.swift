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
import InboxCore
import UIKit

class BackgroundTransitionActionsExecutor: ApplicationServiceDidEnterBackground, @unchecked Sendable {

    typealias ActionQueueStatusProvider = () -> ConnectionStatusProvider?
    typealias BackgroundTaskExecutorProvider = () -> BackgroundTaskExecutor

    static let taskName = "finish_pending_actions"
    private let backgroundTransitionTaskScheduler: BackgroundTransitionTaskScheduler
    private let backgroundTaskExecutorProvider: BackgroundTaskExecutorProvider
    private let notificationScheduller: NotificationScheduler
    private let actionQueueStatusProvider: ActionQueueStatusProvider
    private let callback: LiveQueryCallbackWrapper = .init()

    private var backgroundExecutionHandle: BackgroundExecutionHandle?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    private var accessToInternetOnStart: Bool?

    init(
        backgroundTransitionTaskScheduler: BackgroundTransitionTaskScheduler,
        backgroundTaskExecutorProvider: @escaping BackgroundTaskExecutorProvider,
        notificationScheduller: NotificationScheduler = UNUserNotificationCenter.current(),
        actionQueueStatusProvider: @escaping ActionQueueStatusProvider
    ) {
        self.backgroundTransitionTaskScheduler = backgroundTransitionTaskScheduler
        self.backgroundTaskExecutorProvider = backgroundTaskExecutorProvider
        self.notificationScheduller = notificationScheduller
        self.actionQueueStatusProvider = actionQueueStatusProvider
    }

    func enterBackgroundService() {
        guard actionQueueStatusProvider() != nil else {
            Self.log("No active session")
            return
        }
        backgroundTaskIdentifier = backgroundTransitionTaskScheduler.beginBackgroundTask(
            withName: Self.taskName,
            expirationHandler: { [weak self] in
                Self.log("Time is up, ending task")
                self?.endBackgroundTask()
            }
        )

        Self.log("Background task started")

        Task {
            accessToInternetOnStart = await isConnected()

            Self.log("Internet connection on start: \(accessToInternetOnStart == true ? "Online" : "Offline")")

            callback.delegate = { [weak self] in
                Self.log("All actions executed, ending task")
                Self.log("Handle present: \(self?.backgroundExecutionHandle != nil)?")
                self?.endBackgroundTask()
            }
            do {
                backgroundExecutionHandle = try backgroundTaskExecutorProvider().startBackgroundExecution(
                    callback: callback
                ).get()
                Self.log("Handle is returned, background actions in progress")
                Self.log("Handle present: \(self.backgroundExecutionHandle != nil)?")
            } catch {
                Self.log("[Broken] Background execution failed to start: \(error.localizedDescription)")
            }
        }
    }

    private func endBackgroundTask() {
        guard let backgroundTaskIdentifier else {
            Self.log("[Broken] Missing backgroundTaskIdentifier? - \(backgroundTaskIdentifier == nil)")
            Self.log("[Broken] Handle present: \(self.backgroundExecutionHandle != nil)?")
            return
        }
        Task {
            Self.log("Handle present: \(backgroundExecutionHandle != nil)?")
            let accessToInternetOnEnd = await isConnected()

            Self.log("[Broken] Handle present: \(backgroundExecutionHandle != nil)?")
            await backgroundExecutionHandle?.abort()
            Self.log("Abort called")

            let allMessagesWereSent = await allMessagesWereSent()
            Self.log("All messages were sent - \(allMessagesWereSent)")

            let offline = !accessToInternetOnEnd && accessToInternetOnStart == false
            Self.log("Background task executed in offline mode? - \(offline)")

            if !allMessagesWereSent && !offline {
                await scheduleLocalNotification()
            }

            Self.log("Ending background task")
            backgroundTransitionTaskScheduler.endBackgroundTask(backgroundTaskIdentifier)
        }
    }

    private func scheduleLocalNotification() async {
        Self.log("Schedulling local notification")
        let content = UNMutableNotificationContent()
        content.title = L10n.Notification.EmailNotSent.title.string
        content.body = L10n.Notification.EmailNotSent.body.string
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: Self.taskName, content: content, trigger: trigger)
        do {
            try await notificationScheduller.add(request)
        } catch {
            Self.log("[Broken] Local notification schedulling failed error: \(error)")
        }
    }

    private func isConnected() async -> Bool {
        guard let actionQueueStatusProvider = actionQueueStatusProvider() else {
            return true
        }
        switch await actionQueueStatusProvider.connectionStatus() {
        case .ok(let status):
            return status == .online
        case .error(let error):
            Self.log("[Broken] func isConnected error: \(error)")
            return false
        }
    }

    private func allMessagesWereSent() async -> Bool {
        switch await backgroundTaskExecutorProvider().allMessagesWereSent() {
        case .ok(let result):
            Self.log("func allMessagesWereSent result: \(result)")
            return result
        case .error(let error):
            Self.log("[Broken] func areAnyMessagesUnsent error result: \(error)")
            return false
        }
    }

    private static func log(_ message: String) {
        Task {
            let message = "\(message), time left: \(await UIApplication.shared.backgroundTimeRemaining)"
            AppLogger.log(message: message, category: .thritySecondsBackgroundTask)
        }
    }

}
