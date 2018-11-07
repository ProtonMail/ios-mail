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
    
    static var saver = UserDefaultsSaver<EncryptionKit>.init(key: "pushNotificationEncryptionKit")
    
    // this is uselsess after reinstall cuz app will not be subscribed to APNS iOS service
    internal static var encryptionKit: EncryptionKit? {
        return self.saver.get()
    }
}
