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

import InboxCore
import UIKit
import proton_app_uniffi

actor BackgroundTransitionActionsExecutor: ApplicationServiceDidEnterBackground, ApplicationServiceWillEnterForeground {
    typealias ActionQueueStatusProvider = @Sendable () -> ConnectionStatusProvider?
    typealias BackgroundTaskExecutorProvider = @Sendable () -> BackgroundTaskExecutor

    static let taskName = "finish_pending_actions"
    private let backgroundTransitionTaskScheduler: BackgroundTransitionTaskScheduler
    private let backgroundTaskExecutorProvider: BackgroundTaskExecutorProvider
    private let notificationScheduller: NotificationScheduler
    private let actionQueueStatusProvider: ActionQueueStatusProvider

    // Note: This callback is automatically executed when abort() is called on the background execution handle.
    private lazy var callback = BackgroundExecutionCallbackWrapper { [weak self] result in
        Task {
            Self.log("All actions executed, with result: \(result.status)")
            if result.status.shouldCheckSendingStatus && result.hasUnsentMessages {
                await self?.displayUnsentMessagesNotificationIfOnline()
            }
            await self?.endBackgroundTask()
        }
    }

    private var backgroundExecutionHandle: BackgroundExecutionHandle?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    private var hasAccessToInternetOnStart: Bool?

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

    // MARK: - ApplicationServiceWillEnterForeground

    nonisolated func willEnterForeground() {
        Task {
            await handleWillEnterForeground()
        }
    }

    // MARK: - ApplicationServiceDidEnterBackground

    nonisolated func didEnterBackground() {
        Task {
            await handleDidEnterBackground()
        }
    }

    // MARK: - Private

    private func handleWillEnterForeground() async {
        guard backgroundTaskIdentifier != .invalid else {
            Self.log("backgroundTaskIdentifier is invalid - no ongoing task")
            return
        }
        await abortBackgroundTask(afterEnteredForeground: true)
    }

    private func handleDidEnterBackground() async {
        guard actionQueueStatusProvider() != nil else {
            Self.log("No active session")
            return
        }
        backgroundTaskIdentifier = backgroundTransitionTaskScheduler.beginBackgroundTask(
            withName: Self.taskName,
            expirationHandler: { [weak self] in
                Task {
                    Self.log("Time is up, aborting task")
                    await self?.abortBackgroundTask(afterEnteredForeground: false)
                }
            }
        )

        guard backgroundTaskIdentifier != .invalid else {
            Self.log("Background task cannot be started")
            return
        }

        Self.log("Background task started")

        hasAccessToInternetOnStart = await isConnected()

        Self.log("Internet connection on start: \(hasAccessToInternetOnStart == true ? "Online" : "Offline")")

        do {
            backgroundExecutionHandle = try backgroundTaskExecutorProvider()
                .startBackgroundExecution(
                    callback: callback
                )
                .get()
            Self.log("Handle is returned, background actions in progress")
            Self.log("Handle present: \(self.backgroundExecutionHandle != nil)?")
        } catch {
            Self.log("[Broken] Background execution failed to start: \(error.localizedDescription)")
            endBackgroundTask()
        }
    }

    private func abortBackgroundTask(afterEnteredForeground: Bool) async {
        // Note: The `callback` is automatically executed when abort() is called.
        await backgroundExecutionHandle?.abort(inForeground: afterEnteredForeground)
        Self.log("Abort called, handle present: \(backgroundExecutionHandle != nil)")
    }

    private func displayUnsentMessagesNotificationIfOnline() async {
        Self.log("Handle present: \(backgroundExecutionHandle != nil)?")

        guard backgroundTaskIdentifier != .invalid else {
            Self.log("Invalid backgroundTaskIdentifier")
            return
        }

        let hasAccessToInternetOnEnd = await isConnected()

        let offline = !hasAccessToInternetOnEnd && hasAccessToInternetOnStart == false
        Self.log("Background task executed in offline mode? - \(offline)")

        if !offline {
            await scheduleLocalNotification()
        }
    }

    private func endBackgroundTask() {
        guard backgroundTaskIdentifier != .invalid else {
            Self.log("backgroundTaskIdentifier is invalid")
            return
        }
        Self.log("Ending background task")
        backgroundTransitionTaskScheduler.endBackgroundTask(backgroundTaskIdentifier)
        backgroundTaskIdentifier = .invalid
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

    private static func log(_ message: String) {
        Task {
            let message = "\(message), time left: \(await UIApplication.shared.backgroundTimeRemaining)"
            AppLogger.log(message: message, category: .thirtySecondsBackgroundTask)
        }
    }
}

private extension BackgroundExecutionStatus {
    var shouldCheckSendingStatus: Bool {
        switch self {
        case .abortedInBackground, .timedOut, .failed:
            true
        case .skippedNoActiveContexts, .executed, .abortedInForeground:
            false
        }
    }
}
