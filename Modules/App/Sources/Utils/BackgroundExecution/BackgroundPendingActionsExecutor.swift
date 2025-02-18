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

class BackgroundPendingActionsExecutor: ApplicationServiceDidEnterBackground {

    private let userSession: () -> MailUserSessionProtocol?
    private let taskName = "finish_pending_actions"

    init(userSession: @escaping () -> MailUserSessionProtocol?) {
        self.userSession = userSession
    }

    func enterBackgroundService() {
        guard let session = userSession() else {
            log("💨 [Enter Background Task] No session.")
            return
        }
        log("💨 [Enter Background Task] User enters background, request additional background time.")
        // Check if there is anything to execute in the queue, DO NOT trigger it each time a user enters background
        let backgroundTask = UIApplication.shared.beginBackgroundTask(withName: taskName) {
            log("💨 [Enter Background Task] Expiration handler called showing notification.")
            sendLocalNotification(title: "Error", body: "Not enough time to execute all pending actions in background")
            // FIXME: - Expiration handler
        }
        log("💨 [Enter Background Task] Allocated time: \(backgroundTimeRemaining()) seconds.")

        Task {
            log("💨 [Enter Background Task] Execute pending actions started.")
            _ = await session.executePendingActions()
            log("💨 [Enter Background Task] Time remaining after execute pending actions: \(backgroundTimeRemaining()) seconds.")
            log("💨 [Enter Background Task] Execute pending actions finished.")
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }
    }

    func backgroundTimeRemaining() -> String {
        let remainingTime = UIApplication.shared.backgroundTimeRemaining
        if remainingTime == .greatestFiniteMagnitude {
            return "♾ Unlimited background time (app is in foreground)"
        } else {
            return "⏳ Background time remaining: \(remainingTime) seconds"
        }
    }

}

private func log(_ message: String) {
    BackgroundEventsLogging.log(message, taskType: .enterBackground)
}

private func sendLocalNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            log("❌ Error scheduling notification: \(error.localizedDescription)")
        } else {
            log("✅ Notification scheduled successfully!")
        }
    }
}
