//
//  Protocols.swift
//  proton-push-notifications - Created on 9/6/23.
//
//  Copyright (c) 2023 Proton AG
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import UserNotifications

public protocol PushNotificationServiceProtocol: AnyObject {
    /// Notifies the Push Notification Service about successful registration
    /// - Parameters:
    ///     - token: The device token used to send notifications to this device
    func didRegisterForRemoteNotifications(withDeviceToken token: Data)

    /// Notifies the Push Notification Service about unsuccessful registration
    /// - Parameter error: The error that prevented the registration
    func didFailToRegisterForRemoteNotifications(withError error: Error)

    /// Registers a handler for a notification category
    func registerHandler(_ handler: NotificationHandler, forType type: String)

    func setup()

    func didLoginWithUID(_ uid: String)
    /// Delegate to pass unhandled notifications to
    var fallbackDelegate: UNUserNotificationCenterDelegate? { get set }
}

public struct NotificationType {
    public static let unknown = ""
}

public protocol NotificationHandler {
    /// hand over the notification details for the handler to process
    func handle(notification: UNNotificationContent) // for now, decoded type later
}

public protocol PushNotificationServiceFactory {
    func makePushNotificationService() -> PushNotificationServiceProtocol
}
