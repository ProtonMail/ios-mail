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
import UserNotifications

enum RemoteNotificationType {
    case newMessage(sessionId: String, remoteId: RemoteId)
    case urlToOpen(String)
}

@MainActor
final class UserNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate, ApplicationServiceSetUp {
    private let sessionStatePublisher: AnyPublisher<SessionState, Never>
    private let urlOpener: URLOpener
    private let userNotificationCenter: UserNotificationCenter
    private let getMailSession: @Sendable () -> MailSessionProtocol

    init(
        sessionStatePublisher: AnyPublisher<SessionState, Never>,
        urlOpener: URLOpener,
        userNotificationCenter: UserNotificationCenter = UNUserNotificationCenter.current(),
        getMailSession: @escaping @Sendable () -> MailSessionProtocol = { AppContext.shared.mailSession }
    ) {
        self.getMailSession = getMailSession
        self.sessionStatePublisher = sessionStatePublisher
        self.urlOpener = urlOpener
        self.userNotificationCenter = userNotificationCenter
    }

    func setUpService() {
        userNotificationCenter.delegate = self
        registerActions()
    }

    private func registerActions() {
        let categories: Set<UNNotificationCategory> = [
            .init(
                identifier: NotificationQuickAction.applePushNotificationServiceCategory,
                actions: NotificationQuickAction.allCases.map { $0.registrableAction() },
                intentIdentifiers: []
            )
        ]

        userNotificationCenter.setNotificationCategories(categories)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let notificationContent = response.notification.request.content
        let actionIdentifier = response.actionIdentifier

        guard let notificationType = detectNotificationType(userInfo: notificationContent.userInfo) else {
            AppLogger.log(message: "Unrecognized notification type", category: .notifications, isError: true)
            return
        }

        AppLogger.log(
            message: "Received notification \(notificationType), performing \(actionIdentifier)",
            category: .notifications
        )

        switch notificationType {
        case .newMessage(let sessionId, let remoteId):
            await handleNewMessage(
                remoteId: remoteId,
                action: actionIdentifier,
                sessionId: sessionId,
                subject: notificationContent.body
            )
        case .urlToOpen(let urlString):
            if let url = URL(string: urlString) {
                await urlOpener.open(url, options: [:])
            }
        }

        AppLogger.log(message: "Finished handling notification", category: .notifications)
    }

    private func detectNotificationType(userInfo: [AnyHashable: Any]) -> RemoteNotificationType? {
        if let sessionId = userInfo["UID"] as? String, let messageId = userInfo["messageId"] as? String {
            return .newMessage(sessionId: sessionId, remoteId: .init(value: messageId))
        } else if let url = userInfo["url"] as? String {
            return .urlToOpen(url)
        } else {
            return nil
        }
    }

    private func handleNewMessage(
        remoteId: RemoteId,
        action actionIdentifier: String,
        sessionId: String,
        subject: String
    ) async {
        do {
            guard let storedSession = try await findNotificationRecipientSession(sessionId: sessionId) else {
                AppLogger.log(message: "Session \(sessionId) not found", category: .notifications, isError: true)
                return
            }

            if let action = NotificationQuickAction(rawValue: actionIdentifier) {
                try await execute(action: action, onMessageWith: remoteId, in: storedSession)
            } else {
                try await navigateToMessage(remoteId: remoteId, session: storedSession, subject: subject)
            }
        } catch {
            AppLogger.log(error: error, category: .notifications)
        }
    }

    private func findNotificationRecipientSession(sessionId: String) async throws -> StoredSession? {
        try await getMailSession().getSession(sessionId: sessionId).get()
    }

    private func execute(action: NotificationQuickAction, onMessageWith remoteId: RemoteId, in session: StoredSession) async throws {
        let mailUserSession = try await getMailSession()
            .userContextFromSession(session: session)
            .get()

        let executableAction = action.executableAction(remoteId: remoteId)
        try await mailUserSession.executeNotificationQuickAction(action: executableAction).get()
    }

    private func navigateToMessage(remoteId: RemoteId, session: StoredSession, subject: String) async throws {
        try await switchPrimaryAccount(to: session)

        guard let deepLink = makeDeepLink(basedOn: remoteId, subject: subject) else {
            AppLogger.log(message: "Failed to navigate to message \(remoteId) (\(subject))")
            return
        }

        await urlOpener.open(deepLink, options: [:])
    }

    private func switchPrimaryAccount(to notificationRecipientSession: StoredSession) async throws {
        let mailSession = getMailSession()
        try await mailSession.setPrimaryAccount(userId: notificationRecipientSession.userId()).get()
        await waitUntilSessionBecomesActive(sessionId: notificationRecipientSession.sessionId())
    }

    private func waitUntilSessionBecomesActive(sessionId: String) async {
        var activeSessionPublisher = sessionStatePublisher
            .first(where: { (try? $0.userSession?.sessionId().get()) == sessionId })
            .values
            .makeAsyncIterator()

        _ = await activeSessionPublisher.next()
    }

    private func makeDeepLink(basedOn remoteId: RemoteId, subject: String) -> URL? {
        let route = Route.mailboxOpenMessage(seed: .init(remoteId: remoteId, subject: subject))
        return DeepLinkRouteCoder.encode(route: route)
    }
}
