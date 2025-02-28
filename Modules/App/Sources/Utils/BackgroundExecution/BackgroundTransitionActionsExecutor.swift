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

protocol NotificationScheduller {
    func add(_ request: UNNotificationRequest) async throws
}

// Mail Session

class StartBackgroundExecutionHandler {
    func abort() async {}
}

protocol BackgroundTaskExecutor {
    func startExecuteInBackground(callback: LiveQueryCallback) async -> StartBackgroundExecutionHandler
    func areSendingActionsInActionQueue() async -> [ID]
}

extension MailSession: BackgroundTaskExecutor {
    func startExecuteInBackground(callback: LiveQueryCallback) async -> StartBackgroundExecutionHandler {
        .init()
    }
    
    func areSendingActionsInActionQueue() async -> [ID] {
        []
    }
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

class BackgroundTransitionActionsExecutor: ApplicationServiceDidEnterBackground, @unchecked Sendable {

    typealias ActionQueueStatusProvider = () -> ConnectionStatusProvider & ActiveAccountSendingStatusChecker

    static let taskName = "finish_pending_actions"
    private let backgroundTransitionTaskScheduler: BackgroundTransitionTaskScheduler
    private let backgroundTaskExecutor: BackgroundTaskExecutor
    private let notificationScheduller: NotificationScheduller
    private let actionQueueStatusProvider: ActionQueueStatusProvider
    private let callback: LiveQueryCallbackWrapper = .init()

    private var backgroundExecutionHandler: StartBackgroundExecutionHandler?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    private var accessToInternetOnStart: Bool?

    init(
        backgroundTransitionTaskScheduler: BackgroundTransitionTaskScheduler,
        backgroundTaskExecutor: BackgroundTaskExecutor,
        notificationScheduller: NotificationScheduller,
        actionQueueStatusProvider: @escaping ActionQueueStatusProvider
    ) {
        self.backgroundTransitionTaskScheduler = backgroundTransitionTaskScheduler
        self.backgroundTaskExecutor = backgroundTaskExecutor
        self.notificationScheduller = notificationScheduller
        self.actionQueueStatusProvider = actionQueueStatusProvider
    }

    func enterBackgroundService() {
        backgroundTaskIdentifier = backgroundTransitionTaskScheduler.beginBackgroundTask(
            withName: Self.taskName,
            expirationHandler: { [weak self] in
                Self.log("Time is up, ending task")
                self?.endBackgroundTask()
            }
        )

        Self.log("Background task started")

        Task {
            let actionQueueStatusProvider = actionQueueStatusProvider()
            accessToInternetOnStart = await actionQueueStatusProvider.connectionStatus().isConnected
            Self.log("Internet connection on start: \(accessToInternetOnStart == true ? "Online" : "Offline")")
            callback.delegate = { [weak self] in
                Self.log("All actions executed, ending task")
                self?.endBackgroundTask()
            }
            backgroundExecutionHandler = await backgroundTaskExecutor.startExecuteInBackground(callback: callback)
            Self.log("Handler is returned, background actions in progress")
        }
    }

    private func endBackgroundTask() {
        guard let backgroundTaskIdentifier, let backgroundExecutionHandler else {
            Self.log("Missing backgroundTaskIdentifier? - \(backgroundTaskIdentifier == nil), backgroundExecutionHandler? - \(backgroundExecutionHandler == nil)")
            return
        }
        Task {
            let accessToInternetOnEnd = await actionQueueStatusProvider().connectionStatus().isConnected
            await backgroundExecutionHandler.abort()
            Self.log("Abort called")
            let areSendingActionsInActionQueue = await !backgroundTaskExecutor.areSendingActionsInActionQueue().isEmpty
            Self.log("Any sending actions left? - \(areSendingActionsInActionQueue)")
            let anyActiveAccountMessageFailedToSend = await hasAnyMessageFailedToSend()
            Self.log("Any message of primary account failed to send? - \(anyActiveAccountMessageFailedToSend)")

            let offline = !accessToInternetOnEnd && accessToInternetOnStart == false
            Self.log("Background task executed in offline mode? - \(offline)")

            if anyActiveAccountMessageFailedToSend && !offline {
                await scheduleLocalNotification()
            } else if areSendingActionsInActionQueue && !offline {
                await scheduleLocalNotification()
            }

            Self.log("Ending background task")
            backgroundTransitionTaskScheduler.endBackgroundTask(backgroundTaskIdentifier)
        }
    }

    private func scheduleLocalNotification() async {
        Self.log("Schedulling local notification")
        let content = UNMutableNotificationContent()
        content.title = "Email sending error".notLocalized
        content.body = "We were not able to send your message, enter foreground to continue".notLocalized
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "sending_failure", content: content, trigger: trigger)
        do {
            try await notificationScheduller.add(request)
        } catch {
            Self.log("Local notification schedulling failed")
        }
    }

    private func hasAnyMessageFailedToSend() async -> Bool {
        switch await actionQueueStatusProvider().draftSendResultUnseen() {
        case .ok(let results):
            results.first(where: { $0.failedToSend }) != nil
        case .error:
            false
        }
    }

    private static func log(_ message: String) {
        AppLogger.log(message: message, category: .thritySecondsBackgroundTask)
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
