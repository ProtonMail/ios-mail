//
//  PushNotificationDecryptor.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 06/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


// Since push notificaitons are not stored in iOS internals for long, we do not care about these properties safety. They are used for encryption of data-in-the-air and are changed at least per session. On the other hand, they should be available to all of our extensions even when the app is locked.
public class PushNotificationDecryptor {
    struct EncryptionKit: Codable {
        var passphrase, privateKey, publicKey: String
    }
    
    private static let keychainKey = String(describing: PushNotificationDecryptor.self)
    
    // this is uselsess after reinstall cuz app will not be subscribed to APNS iOS service
    internal static var encryptionKit: EncryptionKit? {
        get {
            guard let raw = SharedCacheBase.getDefault()?.data(forKey: self.keychainKey),
                let kit = try? PropertyListDecoder().decode(EncryptionKit.self, from: raw) else
            {
                return nil
            }
            return kit
        }

        set {
            guard let kit = newValue,
                let raw = try? PropertyListEncoder().encode(kit) else
            {
                SharedCacheBase.getDefault()?.removeObject(forKey: self.keychainKey)
                return
            }
            SharedCacheBase.getDefault()?.setValue(raw, forKey: self.keychainKey)
        }
    }
}
