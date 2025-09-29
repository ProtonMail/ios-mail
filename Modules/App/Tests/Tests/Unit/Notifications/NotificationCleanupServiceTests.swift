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

import InboxTesting
import proton_app_uniffi
import Testing
import UserNotifications

@testable import ProtonMail

@MainActor
final class NotificationCleanupServiceTests {
    private let mailSession = MailSessionSpy()
    private let userNotificationCenter = UserNotificationCenterSpy()
    private var messagesReadByEachUser: [String: Set<RemoteId>] = [:]

    private lazy var sut = NotificationCleanupService(
        mailSession: { [unowned self] in mailSession },
        messageUnreadStates: { [unowned self] userSession, remoteIDs in
            let sessionID = try! userSession.sessionId().get()
            let idsOfReadMessages = await messagesReadByEachUser[sessionID]!
            let unreadStates = remoteIDs.map { !idsOfReadMessages.contains($0) }
            return .ok(unreadStates)
        },
        userNotificationCenter: { [unowned self] in userNotificationCenter }
    )

    @Test
    func removesNotificationsForReadMessages() async {
        userNotificationCenter.stubbedDeliveredNotifications = [
            makeNotification(notificationID: "n-1", sessionID: "user-1", remoteMessageID: "m-1"),
            makeNotification(notificationID: "n-2", sessionID: "user-1", remoteMessageID: "m-2"),
            makeNotification(notificationID: "n-3", sessionID: "user-1", remoteMessageID: "m-3"),
            makeNotification(notificationID: "n-4", sessionID: "user-2", remoteMessageID: "m-4"),
            makeNotification(notificationID: "n-5", sessionID: "user-2", remoteMessageID: "m-5"),
            makeNotification(notificationID: "n-6", sessionID: "user-2", remoteMessageID: "m-6"),
        ]

        mailSession.storedSessions = [
            .init(id: "user-1", state: .authenticated),
            .init(id: "user-2", state: .authenticated),
        ]

        mailSession.userSessions = [
            MailUserSessionSpy(id: "user-1"),
            MailUserSessionSpy(id: "user-2"),
        ]

        messagesReadByEachUser = [
            "user-1": ["m-1", "m-2"],
            "user-2": ["m-4", "m-5"],
        ]

        await sut.removeNotificationsForReadMessages()

        #expect(userNotificationCenter.deliveredNotifications().map(\.request.identifier) == ["n-3", "n-6"])
    }

    private func makeNotification(notificationID: String, sessionID: String, remoteMessageID: RemoteId) -> UNNotification {
        let content = UNMutableNotificationContent()
        content.userInfo = ["UID": sessionID, "messageId": remoteMessageID.value]
        return UNNotificationResponseStubFactory.makeNotification(identifier: notificationID, content: content)
    }
}

extension RemoteId: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(value: value)
    }
}
