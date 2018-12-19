//
//  PushNotificationDecryptor.swift
//  ProtonMail - Created on 06/11/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
    
    static func wipeEncryptionKit() {
        self.saver.set(newValue: nil)
    }
}
