//
//  PushNotificationDecryptor.swift
//  ProtonMail - Created on 06/11/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

/// Since push notificaitons are not stored in iOS internals for long, we do not care about these properties safety.
/// They are used for encryption of data-in-the-air and are changed at least per session.
/// On the other hand, they should be available to all of our extensions even when the app is locked.
class PushNotificationDecryptor {

    enum Key {
        static let encyptionKit     = "pushNotificationEncryptionKit"
        static let outdatedSettings = "pushNotificationOutdatedSubscriptions"
        static let deviceToken      = "latestDeviceToken"
    }
    
    static var saver = KeychainSaver<Set<PushSubscriptionSettings>>(key: Key.encyptionKit, cachingInMemory: false)
    static var outdater = KeychainSaver<Set<PushSubscriptionSettings>>(key: Key.outdatedSettings, cachingInMemory: false)
    static var deviceTokenSaver = KeychainSaver<String>(key: Key.deviceToken, cachingInMemory: false)
    
    static func encryptionKit(forSession uid: String) -> EncryptionKit? {
        guard let allSettings = self.saver.get(),
            let settings = allSettings.first(where: { $0.UID == uid}) else
        {
            return nil
        }
        
        return settings.encryptionKit
    }
    
    static func markForUnsubscribing(uid: String) {
        guard let deviceToken = self.deviceTokenSaver.get() else { return }
        let settings = PushSubscriptionSettings(token: deviceToken, UID: uid)
        
        var outdated = self.outdater.get() ?? []
        outdated.insert(settings)
        self.outdater.set(newValue: outdated)
    }
    
    static func wipeEncryptionKit() {
        self.saver.set(newValue: nil)
    }
}
