//
//  AppVersion.swift
//  ProtonMail
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
import Keymaker
import Crypto

struct AppVersion: Comparable, Equatable {
    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let maxCount: Int = max(lhs.numbers.count, rhs.numbers.count)
        
        func normalizer(_ input: Array<Int>) -> Array<Int> {
            var norm = input
            let zeros = Array<Int>(repeating: 0, count: maxCount - input.count)
            norm.append(contentsOf: zeros)
            return norm
        }
        
        let pairs = zip(normalizer(lhs.numbers), normalizer(rhs.numbers))
        for (l, r) in pairs {
            if l < r {
                return true
            } else if l > r {
                return false
            }
        }
        return false
    }

    private(set) var string: String
    private var numbers: Array<Int>
    
    static var current: AppVersion {
        return .init(Bundle.main.appVersion)
    }
    
    init(_ string: String) {
        self.string = string
        self.numbers = string.split(separator: ".").compactMap { Int($0) }
    }
}

extension AppVersion {
    
    internal func migration() { // TODO: this logic should depend of pre-migration version and current version
        // Values need to be protected with mainKey
        
        // + Push subscriptions
        if let oldToken = SharedCacheBase.getDefault().string(forKey: PushNotificationService.DeprecatedDeviceKeys.token),
            let oldDeviceUID = SharedCacheBase.getDefault().string(forKey: PushNotificationService.DeprecatedDeviceKeys.UID)
        {
            // FIXME: this should somehow work with new APIs
            //PushNotificationService.shared.unreport(APIService.PushSubscriptionSettings(token: oldToken, deviceID: oldDeviceUID))
        }
        
        if let badToken = SharedCacheBase.getDefault().string(forKey: PushNotificationService.DeprecatedDeviceKeys.badToken),
            let badDeviceUID = SharedCacheBase.getDefault().string(forKey: PushNotificationService.DeprecatedDeviceKeys.badUID)
        {
            // FIXME: this should somehow work with new APIs
            //PushNotificationService.shared.unreport(APIService.PushSubscriptionSettings(token: badToken, deviceID: badDeviceUID))
        }
        
        // + UserInfo
        if let userInfo = SharedCacheBase.getDefault().customObjectForKey(UserDataService.Key.userInfoPreMainKey) as? UserInfo {
            self.inject(userInfo: userInfo, into: sharedUserDataService)
        }
        
        // + mailboxPassword
        if let triviallyProtectedMailboxPassword = sharedKeychain.keychain.string(forKey: UserDataService.Key.mailboxPasswordPreMainKey),
            let cleartextMailboxPassword = try? triviallyProtectedMailboxPassword.decrypt(withPwd: "$Proton$" + UserDataService.Key.mailboxPasswordPreMainKey)
        {
            sharedUserDataService.mailboxPassword = cleartextMailboxPassword
        }
        
        // + AuthCredential
        if let credentialRaw = sharedKeychain.keychain.data(forKey: AuthCredential.Key.keychainStorePreMainKey),
            let credential = NSKeyedUnarchiver.unarchiveObject(with: credentialRaw) as? AuthCredential
        {
            credential.storeInKeychain()
        }
        
        // MainKey should be protected according to user settings
        let appLockMigration = DispatchGroup()
        var appWasLocked = false
        
        // + via touch id
        if userCachedStatus.getShared().bool(forKey: UserCachedStatus.Key.isTouchIDEnabled) {
            appWasLocked = true
            appLockMigration.enter()
            keymaker.activate(BioProtection()) { _ in appLockMigration.leave() }
        }
        
        // + via pin
        if userCachedStatus.getShared().bool(forKey: UserCachedStatus.Key.isPinCodeEnabled),
            let pin = sharedKeychain.keychain.string(forKey: UserCachedStatus.Key.pinCodeCache)
        {
            appWasLocked = true
            appLockMigration.enter()
            keymaker.activate(PinProtection(pin: pin)) { _ in appLockMigration.leave() }
        }
        
        // + and lock the app afterwards
        if appWasLocked {
            appLockMigration.notify(queue: .main) { keymaker.lockTheApp() }
        }
        
        
        // Clear up the old stuff on fresh installs also
        sharedKeychain.keychain.removeItem(forKey: UserDataService.Key.password)
        sharedKeychain.keychain.removeItem(forKey: UserCachedStatus.Key.pinCodeCache)
        sharedKeychain.keychain.removeItem(forKey: UserDataService.Key.mailboxPasswordPreMainKey)
        sharedKeychain.keychain.removeItem(forKey: AuthCredential.Key.keychainStorePreMainKey)
        sharedKeychain.keychain.removeItem(forKey: UserCachedStatus.Key.enterBackgroundTime)
        userCachedStatus.getShared().removeObject(forKey: UserCachedStatus.Key.isTouchIDEnabled)
        userCachedStatus.getShared().removeObject(forKey: UserCachedStatus.Key.isPinCodeEnabled)
        userCachedStatus.getShared().removeObject(forKey: UserCachedStatus.Key.isManuallyLockApp)
        userCachedStatus.getShared().removeObject(forKey: UserCachedStatus.Key.touchIDEmail)
        userCachedStatus.getShared().removeObject(forKey: UserDataService.Key.isRememberUser)
        userCachedStatus.getShared().removeObject(forKey: UserDataService.Key.userInfoPreMainKey)
        userCachedStatus.getShared().removeObject(forKey: UserDataService.Key.isRememberMailboxPassword)
        userCachedStatus.getShared().removeObject(forKey: PushNotificationService.DeprecatedDeviceKeys.token)
        userCachedStatus.getShared().removeObject(forKey: PushNotificationService.DeprecatedDeviceKeys.UID)
        userCachedStatus.getShared().removeObject(forKey: PushNotificationService.DeprecatedDeviceKeys.badToken)
        userCachedStatus.getShared().removeObject(forKey: PushNotificationService.DeprecatedDeviceKeys.badUID)
    }
}

extension PushNotificationService {
    internal struct DeprecatedDeviceKeys { // TODO: move to migrations file
        static let token = "DeviceTokenKey"
        static let UID = "DeviceUID"
        
        static let badToken = "DeviceBadToken"
        static let badUID = "DeviceBadUID"
    }
}
