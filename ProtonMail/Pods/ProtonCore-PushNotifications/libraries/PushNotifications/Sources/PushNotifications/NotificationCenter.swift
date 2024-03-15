//
//  NotificationCenter.swift
//  ProtonCore-PushNotifications - Created on 26/7/23.
//
//  Copyright (c) 2023 Proton AG
//
//  This file is part of ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import UserNotifications

// UNUserNotificationCenter is not instantiable without an application host.
// In order to run the test as plain unit tests, we need to put a façade in front

public protocol NotificationCenterProtocol {
    var delegate: UNUserNotificationCenterDelegate? { get set }
    func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping (Bool, Error?) -> Void
    )
}

public struct NotificationCenterFactory {
    static var theCurrent: NotificationCenterProtocol?

    public static var current: NotificationCenterProtocol {
        get {
            theCurrent ?? UNUserNotificationCenter.current()
        }
        set {
            theCurrent = newValue
        }
    }
}

extension UNUserNotificationCenter: NotificationCenterProtocol {
    public static func currentOne() -> NotificationCenterProtocol {
        current() as NotificationCenterProtocol
    }
}
