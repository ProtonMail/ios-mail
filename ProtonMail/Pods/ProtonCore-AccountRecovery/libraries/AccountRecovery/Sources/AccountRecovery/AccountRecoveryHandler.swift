//
//  Created on 16/6/23.
//
//  Copyright (c) 2023 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import NotificationCenter
import UserNotifications

#if canImport(ProtonCorePushNotifications)
import ProtonCorePushNotifications

public enum AccountRecoveryHandlingError: Error {
    case notificationTypeNotRecognized
    case couldNotOpenAccountRecoveryURL
}

/// Push Notifications handler for Account Recovery-related notifications
public class AccountRecoveryHandler: NotificationHandler {
    /// Invoke this method to have the handler process an incoming notification
    /// - Parameter notification: The content of the notification to be processed
    public func handle(notification: UNNotificationContent) {
        // Each client app has a different mechanism for navigating to views, so this needs to be filled in
        guard let message = notification.userInfo["unencryptedMessage"] as? [String: Any], let type = message["type"] as? String,
              NotificationType.allAccountRecoveryTypes.contains(type)
        else { return }

        _ = handler?(notification)
    }

    /// Closure to call to navigate to the respective client settings screen
    public var handler: ((UNNotificationContent) -> Result<Void, AccountRecoveryHandlingError>)?

    public init() {}
}

extension NotificationType {
    /// Signals the start of the Account Recovery process
    public static let accountRecoveryInitiated = "account_recovery_initiated"
    /// Sent every 24h during the Account Recovery grace period
    public static let accountRecoveryReminder = "account_recovery_reminder"
    /// Signals the end of the grace period and that the passwod can be freely reset
    public static let accountRecoveryFinished = "account_recovery_finished"
    /// Signals that the Account Recovery process was cancelled by user action
    public static let accountRecoveryCancelled = "account_recovery_cancelled"
    /// Signals that the Insecure period was finished without the user changing the password
    public static let accountRecoveryExpired = "account_recovery_expired"
    public static let allAccountRecoveryTypes = Set<String>([NotificationType.accountRecoveryInitiated,
                                                             NotificationType.accountRecoveryReminder,
                                                             NotificationType.accountRecoveryFinished,
                                                             NotificationType.accountRecoveryCancelled,
                                                             NotificationType.accountRecoveryExpired
                                                            ])
}
#endif
