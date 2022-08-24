// Copyright (c) 2021 Proton AG
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

import ProtonCore_Crypto
import UserNotifications

protocol EncryptionKitProvider {
    func encryptionKit(forSession uid: String) -> EncryptionKit?
}

extension PushNotificationDecryptor: EncryptionKitProvider {}

final class PushNotificationHandler {

    private enum PushManagementUnexpected: Error {
        case error(description: String, sensitiveInfo: String?)
    }

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestContent: UNMutableNotificationContent?
    private var pingBody: NotificationPingBackBody?

    private let dependencies: Dependencies

    init(dependencies: Dependencies = Dependencies()) {
        self.dependencies = dependencies
    }

    func handle(request: UNNotificationRequest, contentHandler: @escaping (UNNotificationContent) -> Void) {
        SystemLogger.log(message: #function, category: .pushNotification)

        (bestContent, pingBody) = prepareForHandling(request: request, contentHandler: contentHandler)
        guard let bestContent = bestContent else { return }

        do {
            let payload = try pushNotificationPayload(userInfo: bestContent.userInfo)
            let uid = try uid(in: payload)
            bestContent.threadIdentifier = uid
            userCachedStatus.hasMessageFromNotification = true

            let encryptionKit = try encryptionKit(for: uid)
            let decryptedMessage = try decryptMessage(in: payload, encryptionKit: encryptionKit)
            let pushContent = try parseContent(with: decryptedMessage)
            pingBody?.decrypted = true

            populateNotification(content: bestContent, pushContent: pushContent)
            updateBadge(content: bestContent, payload: payload, pushData: pushContent.data, userId: uid)

        } catch let PushManagementUnexpected.error(message, redacted) {
            logPushNotificationError(message: message, redactedInfo: redacted)

        } catch {
            logPushNotificationError(message: "unknown error handling push")

        }
        sendPushPingBack(with: dependencies.urlSession, body: pingBody) { contentHandler(bestContent) }
    }

    func willTerminate(session: URLSessionProtocol = URLSession.shared) {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content
        // otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestContent = bestContent {
            sendPushPingBack(with: session, body: pingBody) { contentHandler(bestContent) }
        }
    }
}

// MARK: Private

private extension PushNotificationHandler {

    private func pushNotificationPayload(userInfo: [AnyHashable: Any]) throws -> PushNotificationPayload {
        do {
            return try PushNotificationPayload(userInfo: userInfo)
        } catch {
            let redactedInfo = String(describing: error)
            throw PushManagementUnexpected.error(description: "Fail parsing push payload.", sensitiveInfo: redactedInfo)
        }
    }

    private func uid(in payload: PushNotificationPayload) throws -> String {
        guard let uid = payload.uid else {
            throw PushManagementUnexpected.error(description: "uid not found in payload", sensitiveInfo: nil)
        }
        return uid
    }

    private func encryptionKit(for uid: String) throws -> EncryptionKit {
        guard let encryptionKit = dependencies.encryptionKitProvider.encryptionKit(forSession: uid) else {
            // encryptionKitProvider.markForUnsubscribing(uid: UID) // Uncomment when decryption bug fixed MAILIOS-2230
            SharedUserDefaults().setNeedsToRegisterAgain(for: uid)
            throw PushManagementUnexpected.error(description: "no encryption kit for uid", sensitiveInfo: "uid \(uid)")
        }
        return encryptionKit
    }

    private func decryptMessage(in payload: PushNotificationPayload, encryptionKit: EncryptionKit) throws -> String {
        guard let encryptedMessage = payload.encryptedMessage else {
            throw PushManagementUnexpected.error(description: "no encrypted message in payload", sensitiveInfo: nil)
        }
        do {
            return try Crypto().decrypt(
                encrypted: encryptedMessage,
                privateKey: encryptionKit.privateKey,
                passphrase: encryptionKit.passphrase
            )
        } catch {
            let sensitiveInfo = "error: \(error.localizedDescription)"
            throw PushManagementUnexpected.error(description: "fail decrypting data", sensitiveInfo: sensitiveInfo)
        }
    }

    private func parseContent(with decryptedText: String) throws -> PushContent {
        do {
            return try PushContent(json: decryptedText)
        } catch {
            let redactedInfo = String(describing: error)
            throw PushManagementUnexpected.error(description: "fail parsing push content", sensitiveInfo: redactedInfo)
        }
    }

    private func prepareForHandling(
        request: UNNotificationRequest,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> (UNMutableNotificationContent?, NotificationPingBackBody) {
        let deviceToken = PushNotificationDecryptor.deviceTokenSaver.get() ?? "unknown"
        let pingBackBody = NotificationPingBackBody(notificationId: request.identifier,
                                                    deviceToken: deviceToken,
                                                    decrypted: false)
        self.contentHandler = contentHandler
        guard let mutableContent = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            sendPushPingBack(with: dependencies.urlSession, body: pingBackBody) { contentHandler(request.content) }
            return (nil, pingBackBody)
        }
        mutableContent.body = "You received a new message!"
        mutableContent.sound = UNNotificationSound.default
        #if Enterprise
        mutableContent.title = "You received a new message!"
        #endif
        return (mutableContent, pingBackBody)
    }

    private func populateNotification(content: UNMutableNotificationContent, pushContent: PushContent) {
        let pushData = pushContent.data
        content.title = pushData.sender.name.isEmpty ? pushData.sender.address : pushData.sender.name
        content.body = pushData.body
    }

    private func updateBadge(
        content: UNMutableNotificationContent,
        payload: PushNotificationPayload,
        pushData: PushData,
        userId: String
    ) {
        if userCachedStatus.primaryUserSessionId == userId {
            if payload.viewMode == 0, let unread = payload.unreadConversations { // conversation
                content.badge = NSNumber(value: unread)
            } else if payload.viewMode == 1, let unread = payload.unreadMessages { // single message
                content.badge = NSNumber(value: unread)
            } else if pushData.badge > 0 {
                content.badge = NSNumber(value: pushData.badge)
            } else {
                content.badge = nil
            }
        } else {
            content.badge = nil
        }
    }

    private func sendPushPingBack(with session: URLSessionProtocol,
                                  body: NotificationPingBackBody?,
                                  completion: @escaping () -> Void) {
        guard let body = body, let request = try? NotificationPingBack.request(with: body) else {
            completion()
            return
        }
        session.dataTask(with: request) { _, _, _ in
            completion()
        }.resume()
    }

    private func logPushNotificationError(message: String, redactedInfo: String? = nil) {
        SystemLogger.log(message: message, redactedInfo: redactedInfo, category: .pushNotification, isError: true)
    }
}

extension PushNotificationHandler {
    struct Dependencies {
        let urlSession: URLSessionProtocol
        let encryptionKitProvider: EncryptionKitProvider

        init(
            urlSession: URLSessionProtocol = URLSession.shared,
            encryptionKitProvider: EncryptionKitProvider = PushNotificationDecryptor()
        ) {
            self.urlSession = urlSession
            self.encryptionKitProvider = encryptionKitProvider
        }
    }
}

enum NotificationPingBackError: Error {
    case malformedURL
}

enum NotificationPingBack {
    static let method = "POST"
    static var endpoint: String? {
        DoHMail().getCurrentlyUsedHostUrl() + "/core/v4/pushes/ack"
    }

    static func request(with body: NotificationPingBackBody) throws -> URLRequest {
        guard let endpoint = Self.endpoint, let url = URL(string: endpoint) else {
            throw NotificationPingBackError.malformedURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = Self.method
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("iOS_\(Bundle.main.majorVersion)", forHTTPHeaderField: "x-pm-appversion")
        request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        return request
    }
}

struct NotificationPingBackBody: Codable {
    let notificationId: String
    let deviceToken: String
    var decrypted: Bool

    enum CodingKeys: String, CodingKey {
        case notificationId = "NotificationID"
        case deviceToken = "DeviceToken"
        case decrypted = "Decrypted"
    }
}

protocol URLSessionProtocol {
    @discardableResult
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void ) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {}
