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
import InboxKeychain
import proton_app_uniffi
import UserNotifications

public struct TestableNotificationService {
    typealias DecryptRemoteNotification = (OsKeyChain, EncryptedPushNotification) async -> DecryptPushNotificationResult

    private let decryptRemoteNotification: DecryptRemoteNotification
    private let keychain = KeychainSDKWrapper()

    public init() {
        self.init(decryptRemoteNotification: decryptPushNotification)
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
        switch await decryptRemoteNotification(keychain, encryptedPushNotification) {
        case .ok(let notificationData):
            mutableContent.title = notificationData.sender.displayableName
            mutableContent.body = notificationData.body

            switch notificationData {
            case .email(let payload):
                mutableContent.userInfo["messageId"] = payload.messageId.value
            case .openUrl(let payload):
                mutableContent.userInfo["url"] = payload.url
            }
        case .error(let error):
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
