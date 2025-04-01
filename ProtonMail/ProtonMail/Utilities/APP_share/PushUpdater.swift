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

// sourcery: mock
protocol UserNotificationCenterProtocol {
    func authorizationStatus() async -> UNAuthorizationStatus
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }
}

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

struct PushUpdater {
    private let collapseId = "collapseID"
    private let uid = "UID"
    private let viewMode = "viewMode"
    static private let unreadConversations = "unreadConversations"
    static private let unreadMessages = "unreadMessages"

    private let notificationCenter: UserNotificationCenterProtocol
    private let application: UIApplicationBadgeProtocol
    private let userDefaults: UserDefaults

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

    init(
        notificationCenter: UserNotificationCenterProtocol = UNUserNotificationCenter.current(),
        application: UIApplicationBadgeProtocol = UIApplicationBadge(),
        userDefaults: UserDefaults
    ) {
        self.notificationCenter = notificationCenter
        self.application = application
        self.userDefaults = userDefaults
    }

    func update(with userInfo: [AnyHashable: Any]) {
        guard let notificationId = userInfo[collapseId] as? String else {
            return
        }

        remove(notificationIdentifiers: [notificationId])
        guard let uid = userInfo[uid] as? String,
              userDefaults[.primaryUserSessionId] == uid,
              let viewModeValue = userInfo[viewMode] as? Int,
              let viewMode = ViewMode(rawValue: viewModeValue),
              let unread = userInfo[viewMode.userInfoKey] as? Int else {
                  return
        }

        application.setBadge(badge: unread)
    }

    func remove(notificationIdentifiers: [String?]?) {
        guard let notificationIdentifiers = notificationIdentifiers?.compactMap({ $0 }),
              !notificationIdentifiers.isEmpty else {
            return
        }
        notificationCenter.removeDeliveredNotifications(withIdentifiers: notificationIdentifiers)
    }
}
