// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import UserNotifications

protocol EncryptionKitProvider {
    func encryptionKit(forSession uid: String) -> EncryptionKit?
    func markForUnsubscribing(uid: String)
}

extension PushNotificationDecryptor: EncryptionKitProvider {}

final class PushNotificationHandler {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestContent: UNMutableNotificationContent?
    var pingBody: NotificationPingBackBody?

    func handle(session: URLSessionProtocol = URLSession.shared,
                request: UNNotificationRequest,
                encryptionKitProvider: EncryptionKitProvider = PushNotificationDecryptor(),
                contentHandler: @escaping (UNNotificationContent) -> Void) {
        (bestContent, pingBody) = prepareForHandling(session: session, request: request, contentHandler: contentHandler)
        guard let bestContent = bestContent else { return }

        guard let UID = bestContent.userInfo["UID"] as? String else {
            #if Enterprise
            bestContent.body = "without UID"
            #endif
            sendPushPingBack(with: session, body: pingBody) { contentHandler(bestContent) }
            return
        }

        bestContent.threadIdentifier = UID

        userCachedStatus.hasMessageFromNotification = true

        guard let encryptionKit = encryptionKitProvider.encryptionKit(forSession: UID) else {
            encryptionKitProvider.markForUnsubscribing(uid: UID)
            #if Enterprise
            bestContent.body = "no encryption kit for UID"
            #endif
            sendPushPingBack(with: session, body: pingBody) { contentHandler(bestContent) }
            return
        }

        guard let encrypted = bestContent.userInfo["encryptedMessage"] as? String else {
            #if Enterprise
            bestContent.body = "no encrypted message in push"
            #endif
            sendPushPingBack(with: session, body: pingBody) { contentHandler(bestContent) }
            return
        }

        do {
            let plaintext = try Crypto().decrypt(encrypted: encrypted,
                                                 privateKey: encryptionKit.privateKey,
                                                 passphrase: encryptionKit.passphrase)
            guard let push = PushData.parse(with: plaintext) else {
                #if Enterprise
                bestContent.body = "failed to decrypt"
                #endif
                sendPushPingBack(with: session, body: pingBody) { contentHandler(bestContent) }
                return
            }
            pingBody?.decrypted = true
            populateNotification(content: bestContent, pushData: push, userId: UID)
        } catch {
            #if Enterprise
            bestContent.body = "error: \(error.localizedDescription)"
            #endif
        }
        sendPushPingBack(with: session, body: pingBody) { contentHandler(bestContent) }
    }

    func willTerminate(session: URLSessionProtocol = URLSession.shared) {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content
        // otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestContent = bestContent {
            sendPushPingBack(with: session, body: pingBody) { contentHandler(bestContent) }
        }
    }

    private func prepareForHandling(session: URLSessionProtocol,
                                    request: UNNotificationRequest,
                                    contentHandler: @escaping (UNNotificationContent) -> Void)
    -> (UNMutableNotificationContent?, NotificationPingBackBody) {
        let deviceToken = PushNotificationDecryptor.deviceTokenSaver.get() ?? "unknown"
        let pingBackBody = NotificationPingBackBody(notificationId: request.identifier,
                                                    deviceToken: deviceToken,
                                                    decrypted: false)
        self.contentHandler = contentHandler
        guard let mutableContent = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            sendPushPingBack(with: session, body: pingBackBody) { contentHandler(request.content) }
            return (nil, pingBackBody)
        }
        mutableContent.body = "You received a new message!"
        mutableContent.sound = UNNotificationSound.default
        #if Enterprise
        mutableContent.title = "You received a new message!"
        #endif
        return (mutableContent, pingBackBody)
    }

    private func populateNotification(content: UNMutableNotificationContent, pushData: PushData, userId UID: String) {
        content.title = pushData.sender.name.isEmpty ? pushData.sender.address : pushData.sender.name
        content.body = pushData.body

        if userCachedStatus.primaryUserSessionId == UID {
            if content.userInfo["viewMode"] as? Int == 0,
               let unread = content.userInfo["unreadConversations"] as? Int { // conversation
                content.badge = NSNumber(value: unread)
            } else if content.userInfo["viewMode"] as? Int == 1,
                      let unread = content.userInfo["unreadMessages"] as? Int { // single message
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
