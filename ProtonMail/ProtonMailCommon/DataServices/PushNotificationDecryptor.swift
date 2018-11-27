//
//  PushNotificationDecryptor.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 06/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

// Since push notificaitons are not stored in iOS internals for long, we do not care about these properties safety. They are used for encryption of data-in-the-air and are changed at least per session. On the other hand, they should be available to all of our extensions even when the app is locked.
class PushNotificationDecryptor {
    struct EncryptionKit: Codable, Equatable {
        var passphrase, privateKey, publicKey: String
    }
    enum Key {
        static let encyptionKit = "pushNotificationEncryptionKit"
        static let outdatedSettings = "pushNotificationOutdatedSubscriptions"
        static let deviceToken = "latestDeviceToken"
    }
    
    static var saver = KeychainSaver<PushSubscriptionSettings>(key: Key.encyptionKit)
    static var outdater = KeychainSaver<Set<PushSubscriptionSettings>>(key: Key.outdatedSettings, cachingInMemory: false)
    static var deviceTokenSaver = KeychainSaver<String>(key: Key.deviceToken, cachingInMemory: false)
    
    static func encryptionKit(forSession uid: String) -> EncryptionKit? {
        guard let settings = self.saver.get(),
            uid == settings.UID else
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
}
