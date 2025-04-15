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

import Combine
import InboxCore
import proton_app_uniffi
import UIKit
import UserNotifications

enum RemoteNotificationType {
    case newMessage(sessionId: String, remoteId: String)
    case urlToOpen(String)
}

final class UserNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate, ApplicationServiceSetUp {
    private let sessionStatePublisher: AnyPublisher<SessionState, Never>
    private let urlOpener: URLOpener
    private let userNotificationCenter: UserNotificationCenter
    private let getMailSession: () -> MailSessionProtocol

    init(
        sessionStatePublisher: AnyPublisher<SessionState, Never>,
        urlOpener: URLOpener,
        userNotificationCenter: UserNotificationCenter = UNUserNotificationCenter.current(),
        getMailSession: @escaping () -> MailSessionProtocol = { AppContext.shared.mailSession }
    ) {
        self.getMailSession = getMailSession
        self.sessionStatePublisher = sessionStatePublisher
        self.urlOpener = urlOpener
        self.userNotificationCenter = userNotificationCenter
    }

    func setUpService() {
        userNotificationCenter.delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let notificationContent = response.notification.request.content
        let notificationType = detectNotificationType(userInfo: notificationContent.userInfo)

        if let notificationType {
            AppLogger.log(message: "Did receive notification: \(notificationType)", category: .notifications)
        }

        switch notificationType {
        case .newMessage(let sessionId, let remoteId):
            if
                await switchPrimaryAccount(sessionId: sessionId),
                let deepLink = makeDeepLink(basedOn: remoteId, subject: notificationContent.body)
            {
                await urlOpener.open(deepLink, options: [:])
            }
        case .urlToOpen(let urlString):
            if let url = URL(string: urlString) {
                await urlOpener.open(url, options: [:])
            }
        case .none:
            AppLogger.log(message: "Unrecognized notification type", category: .notifications, isError: true)
        }
    }

    private func detectNotificationType(userInfo: [AnyHashable: Any]) -> RemoteNotificationType? {
        if let sessionId = userInfo["UID"] as? String, let messageId = userInfo["messageId"] as? String {
            return .newMessage(sessionId: sessionId, remoteId: messageId)
        } else if let url = userInfo["url"] as? String {
            return .urlToOpen(url)
        } else {
            return nil
        }
    }

    private func switchPrimaryAccount(sessionId: String) async -> Bool {
        let mailSession = getMailSession()

        do {
            guard let notificationRecipientSession = try await mailSession.getSession(sessionId: sessionId).get() else {
                AppLogger.log(message: "Session \(sessionId) not found", category: .notifications, isError: true)
                return false
            }

            try await mailSession.setPrimaryAccount(userId: notificationRecipientSession.userId()).get()
            await waitUntilSessionBecomesActive(sessionId: sessionId)

            return true
        } catch {
            AppLogger.log(error: error, category: .notifications)
            return false
        }
    }

    private func waitUntilSessionBecomesActive(sessionId: String) async {
        var activeSessionPublisher = sessionStatePublisher
            .first(where: { (try? $0.userSession?.sessionId().get()) == sessionId })
            .values
            .makeAsyncIterator()

        _ = await activeSessionPublisher.next()
    }

    private func makeDeepLink(basedOn rawRemoteMessageId: String, subject: String) -> URL? {
        let remoteId = RemoteId(value: rawRemoteMessageId)
        let route = Route.mailboxOpenMessage(seed: .init(remoteId: remoteId, subject: subject))
        return DeepLinkRouteCoder.encode(route: route)
    }
}
