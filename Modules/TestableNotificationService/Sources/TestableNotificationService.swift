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
import proton_app_uniffi
import UserNotifications

public struct TestableNotificationService {
    typealias DecryptRemoteNotification = (EncryptedPushNotification) async throws -> DecryptedPushNotification

    private let decryptRemoteNotification: DecryptRemoteNotification

    public init() {
        self.init {
            let mailSession = try ProcessWideMailSessionCache.prepareMailSession()

            switch await decryptPushNotification(session: mailSession, encrypted: $0) {
            case .ok(let value):
                return value
            case .error(let error):
                throw error
            }
        }
    }

    init(decryptRemoteNotification: @escaping DecryptRemoteNotification) {
        self.decryptRemoteNotification = decryptRemoteNotification
    }

    public func transform(originalContent: UNNotificationContent) async -> UNNotificationContent {
        guard let mutableContent = (originalContent.mutableCopy() as? UNMutableNotificationContent) else {
            AppLogger.log(message: "Notification content cannot be mutated", category: .notifications, isError: true)
            return originalContent
        }

        // this is a temporary "marker" body to see if the extension has been launched by the OS, which is known to not be the case sometimes
        mutableContent.body = "You received a new message!"

        if let encryptedPushNotification = parseDecryptablePayload(from: originalContent.userInfo) {
            await replaceTitleAndBody(of: mutableContent, byDecrypting: encryptedPushNotification)
        }

        return mutableContent
    }

    private func parseDecryptablePayload(from userInfo: [AnyHashable: Any]) -> EncryptedPushNotification? {
        guard
            let encryptedMessage = userInfo["encryptedMessage"] as? String,
            let sessionId = userInfo["UID"] as? String
        else {
            AppLogger.log(message: "Missing required fields in the payload", category: .notifications, isError: true)
            return nil
        }

        return .init(authId: sessionId, encryptedMessage: encryptedMessage)
    }

    private func replaceTitleAndBody(
        of mutableContent: UNMutableNotificationContent,
        byDecrypting encryptedPushNotification: EncryptedPushNotification
    ) async {
        do {
            let notificationData = try await decryptRemoteNotification(encryptedPushNotification)
            mutableContent.title = notificationData.sender.displayableName
            mutableContent.body = notificationData.body
        } catch {
            AppLogger.log(error: error, category: .notifications)
        }
    }
}

private extension DecryptedPushNotification {
    var body: String {
        switch self {
        case .email(let payload):
            payload.subject
        case .openUrl(let payload):
            payload.content
        }
    }

    var sender: NotificationSender {
        switch self {
        case .email(let payload):
            payload.sender
        case .openUrl(let payload):
            payload.sender
        }
    }
}

private extension NotificationSender {
    var displayableName: String {
        name.isEmpty ? address : name
    }
}

extension ActionError: Error {}
