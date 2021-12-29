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
    private let userId = "uid"
    private let viewMode = "viewMode"
    static private let unreadConversations = "unreadConversations"
    static private let unreadMessages = "unreadMessages"

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

    func update(with userInfo: [AnyHashable: Any],
                notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current(),
                application: UIApplicationBadgeProtocol = UIApplicationBadge(),
                userStatus: UserSessionProvider = userCachedStatus) {
        if let notificationId = userInfo[collapseId] as? String {
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationId])
        }
        guard let userId = userInfo[userId] as? String,
              userStatus.primaryUserSessionId == userId,
              let viewModeValue = userInfo[viewMode] as? Int,
              let viewMode = ViewMode(rawValue: viewModeValue),
              let unread = userInfo[viewMode.userInfoKey] as? Int else {
            return
        }

        application.setBadge(badge: unread)
    }
}
