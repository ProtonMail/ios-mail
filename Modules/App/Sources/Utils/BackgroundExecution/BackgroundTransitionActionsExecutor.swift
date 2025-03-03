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
                self?.endBackgroundTask()
            }
            do {
                backgroundExecutionHandle = try backgroundTaskExecutorProvider().startBackgroundExecution(
                    callback: callback
                ).get()
                Self.log("Handle is returned, background actions in progress")
            } catch {
                Self.log("Background execution failed to start: \(error.localizedDescription)")
            }
        }
    }

    private func endBackgroundTask() {
        guard let backgroundTaskIdentifier else {
            Self.log("Missing backgroundTaskIdentifier? - \(backgroundTaskIdentifier == nil)")
            return
        }
        Task {
            let accessToInternetOnEnd = await isConnected()
            await backgroundExecutionHandle?.abort()
            Self.log("Abort called")

            let areAnyMessagesUnsent = await areAnyMessagesUnsent()
            Self.log("Are any messages unsent - \(areAnyMessagesUnsent)")

            let offline = !accessToInternetOnEnd && accessToInternetOnStart == false
            Self.log("Background task executed in offline mode? - \(offline)")

            if areAnyMessagesUnsent && !offline {
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
            Self.log("Local notification schedulling failed")
        }
    }

    private func isConnected() async -> Bool {
        guard let actionQueueStatusProvider = actionQueueStatusProvider() else {
            return true
        }
        return await actionQueueStatusProvider.connectionStatus().isConnected
    }

    private static func log(_ message: String) {
        AppLogger.log(message: message, category: .thritySecondsBackgroundTask)
    }

    private func areAnyMessagesUnsent() async -> Bool {
        let allMessagesWereSent = (try? await backgroundTaskExecutorProvider().allMessagesWereSent().get()) ?? true
        return !allMessagesWereSent
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
