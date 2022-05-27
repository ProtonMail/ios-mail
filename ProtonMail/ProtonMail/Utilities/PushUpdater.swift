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

import Foundation
import UIKit

protocol NotificationCenterProtocol {
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: NotificationCenterProtocol {}

protocol UIApplicationBadgeProtocol {
    func setBadge(badge: Int)
}

extension UIApplicationBadgeProtocol {
    func setBadge(badge: Int) {
        UIApplication.setBadge(badge: badge)
    }
}

struct UIApplicationBadge {}
extension UIApplicationBadge: UIApplicationBadgeProtocol {}

protocol UserSessionProvider {
    var primaryUserSessionId: String? { get set }
}

extension UserCachedStatus: UserSessionProvider {}

struct PushUpdater {
    private let collapseId = "collapseID"
    private let uid = "UID"
    private let viewMode = "viewMode"
    static private let unreadConversations = "unreadConversations"
    static private let unreadMessages = "unreadMessages"

    private let notificationCenter: NotificationCenterProtocol
    private let application: UIApplicationBadgeProtocol
    private let userStatus: UserSessionProvider
    private let pingBackSession: URLSessionProtocol

    private enum ViewMode: Int {
        case conversations = 0
        case messages = 1

        var userInfoKey: String {
            switch self {
            case .conversations:
                return PushUpdater.unreadConversations
            case .messages:
                return PushUpdater.unreadMessages
            }
        }
    }

    init(notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current(),
         application: UIApplicationBadgeProtocol = UIApplicationBadge(),
         userStatus: UserSessionProvider = userCachedStatus,
         pingBackSession: URLSessionProtocol = URLSession.shared) {
        self.notificationCenter = notificationCenter
        self.application = application
        self.userStatus = userStatus
        self.pingBackSession = pingBackSession
    }

    func update(with userInfo: [AnyHashable: Any], completion: @escaping () -> Void) {
        guard let notificationId = userInfo[collapseId] as? String else {
            sendPushPingBack(notificationId: "unknown", completion: completion)
            return
        }

        remove(notificationIdentifiers: [notificationId])
        guard let uid = userInfo[uid] as? String,
              userStatus.primaryUserSessionId == uid,
              let viewModeValue = userInfo[viewMode] as? Int,
              let viewMode = ViewMode(rawValue: viewModeValue),
              let unread = userInfo[viewMode.userInfoKey] as? Int else {
                  sendPushPingBack(notificationId: notificationId, completion: completion)
                  return
        }

        application.setBadge(badge: unread)
        sendPushPingBack(notificationId: notificationId, completion: completion)
    }

    func remove(notificationIdentifiers: [String?]?) {
        guard let notificationIdentifiers = notificationIdentifiers?.compactMap({ $0 }),
              !notificationIdentifiers.isEmpty else {
            return
        }
        notificationCenter.removeDeliveredNotifications(withIdentifiers: notificationIdentifiers)
    }

    func sendPushPingBack(notificationId: String,
                          completion: @escaping (() -> Void)) {
        let deviceToken = PushNotificationDecryptor.deviceTokenSaver.get() ?? "unknown"
        let pingBackBody = NotificationPingBackBody(notificationId: "\(notificationId)-background",
                                                    deviceToken: deviceToken,
                                                    decrypted: true)
        guard let request = try? NotificationPingBack.request(with: pingBackBody) else {
            completion()
            return
        }
        pingBackSession.dataTask(with: request) { _, _, _ in
            completion()
        }.resume()
    }
}
