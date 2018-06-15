//
//  UserCachedStatus+NotificationSnoozerCore.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 15/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

extension UserCachedStatus {
    var snoozeConfiguration: Array<NotificationsSnoozerCore.Configuration>? {
        get {
            guard let rawConfig = getShared().data(forKey: Key.snoozeConfiguration) else {
                return nil
            }
            return try? PropertyListDecoder().decode(Array<NotificationsSnoozerCore.Configuration>.self, from: rawConfig)
        }
        set {
            let rawConfig = try? PropertyListEncoder().encode(newValue)
            getShared().set(rawConfig, forKey: Key.snoozeConfiguration)
        }
    }
    
}

