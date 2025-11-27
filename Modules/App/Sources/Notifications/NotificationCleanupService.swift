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
@preconcurrency import UserNotifications
import proton_app_uniffi

final class NotificationCleanupService: ApplicationServiceWillResignActive {
    private struct RemovalCandidate {
        let remoteMessageID: RemoteId
        let notificationID: String
    }

    typealias GetMailSession = () -> MailSessionProtocol
    typealias GetUserNotificationCenter = () -> UserNotificationCenter
    typealias MessageUnreadStates = (MailUserSession, [RemoteId]) async -> BulkMessageUnreadStatusResult

    private let mailSession: GetMailSession
    private let messageUnreadStates: MessageUnreadStates
    private let userNotificationCenter: GetUserNotificationCenter

    init(
        mailSession: @escaping GetMailSession,
        messageUnreadStates: @escaping MessageUnreadStates,
        userNotificationCenter: @escaping GetUserNotificationCenter
    ) {
        self.mailSession = mailSession
        self.messageUnreadStates = messageUnreadStates
        self.userNotificationCenter = userNotificationCenter
    }

    convenience init() {
        self.init(
            mailSession: { AppContext.shared.mailSession },
            messageUnreadStates: bulkMessageUnreadStatus,
            userNotificationCenter: UNUserNotificationCenter.current
        )
    }

    func removeNotificationsForReadMessages() async {
        let notifications = await userNotificationCenter().deliveredNotifications()
        AppLogger.log(message: "Found \(notifications.count) delivered notifications", category: .notifications)

        let candidatesForRemoval = candidatesForRemovalGroupedBySessionID(parsedFrom: notifications)

        await withDiscardingTaskGroup { group in
            for (sessionID, candidates) in candidatesForRemoval {
                group.addTask {
                    await self.removeNotificationsForReadMessages(sessionID: sessionID, candidates: candidates)
                }
            }
        }
    }

    private func candidatesForRemovalGroupedBySessionID(parsedFrom notifications: [UNNotification]) -> [String: [RemovalCandidate]] {
        notifications.reduce(into: [:]) { partialResult, notification in
            let userInfo = notification.request.content.userInfo

            guard
                case .newMessage(let sessionID, let remoteMessageID) = RemoteNotificationType(userInfo: userInfo)
            else {
                return
            }

            let newCandidate = RemovalCandidate(
                remoteMessageID: remoteMessageID,
                notificationID: notification.request.identifier
            )

            partialResult[sessionID, default: []].append(newCandidate)
        }
    }

    private func removeNotificationsForReadMessages(sessionID: String, candidates: [RemovalCandidate]) async {
        AppLogger.log(message: "\(candidates.count) notifications belong to session \(sessionID)")

        do {
            guard let userSession = try await mailSession().userSession(sessionID: sessionID) else {
                return
            }

            let unreadStates = try await messageUnreadStates(userSession, candidates.map(\.remoteMessageID)).get()

            let notificationIDsToRemove = zip(candidates, unreadStates)
                .filter { (_, unread) in !unread }
                .map { (removalCandidate, _) in removalCandidate.notificationID }

            AppLogger.log(message: "Will remove \(notificationIDsToRemove.count) notifications belonging to session \(sessionID)")
            userNotificationCenter().removeDeliveredNotifications(withIdentifiers: notificationIDsToRemove)
        } catch {
            AppLogger.log(error: error, category: .notifications)
        }
    }

    // MARK: ApplicationServiceWillResignActive

    func willResignActive() {
        Task {
            await removeNotificationsForReadMessages()
        }
    }
}

private extension MailSessionProtocol {
    func userSession(sessionID: String) async throws -> MailUserSession? {
        if let storedSession = try await getSession(sessionId: sessionID).get() {
            return try await initializedUserSessionFromStoredSession(session: storedSession).get()
        } else {
            return nil
        }
    }
}
