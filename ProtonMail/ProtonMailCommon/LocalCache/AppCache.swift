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
import CoreData


///TODO::fixme can be improved more.
class AppCache : Migrate {
    internal var latestVersion: Int
    
    internal var currentVersion: Int {
        get {
            return self.versionSaver.get() ?? 0
        }
        set {
            self.versionSaver.set(newValue: newValue)
        }
    }
    
    internal var supportedVersions: [Int] = [Version.v110.rawValue]
    
    internal var initalRun: Bool {
        get {
            return currentVersion == 0
        }
    }
    /// saver for versioning
    private let versionSaver: Saver<Int>
    
    enum Key {
        static let cacheVersion = "last_cache_version"
    }
    
    enum Version : Int {
        static let CacheVersion : Int = 111 // this is app cache version
        
        case v110 = 110
    }

    init() {
        self.latestVersion = Version.CacheVersion
        self.versionSaver = UserDefaultsSaver<Int>(key: Key.cacheVersion)
    }
    
    
    static func isFirstRun() -> Bool {
        return SharedCacheBase.getDefault().object(forKey: UserDataService.Key.firstRunKey) == nil
    }
    
    func rebuild(reason: RebuildReason) {
        self.cleanLagacy()
        self.currentVersion = self.latestVersion
    }
    
    func cleanLagacy() {
        // Clear up the old stuff on fresh installs also
        sharedKeychain.keychain.removeItem(forKey: DeprecatedKeys.UserDataService.password)
        sharedKeychain.keychain.removeItem(forKey: DeprecatedKeys.UserDataService.mailboxPassword)
        sharedKeychain.keychain.removeItem(forKey: DeprecatedKeys.UserCachedStatus.pinCodeCache)
        sharedKeychain.keychain.removeItem(forKey: DeprecatedKeys.AuthCredential.keychainStore)
        sharedKeychain.keychain.removeItem(forKey: DeprecatedKeys.UserCachedStatus.enterBackgroundTime)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.isTouchIDEnabled)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.isPinCodeEnabled)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.isManuallyLockApp)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.touchIDEmail)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.lastLocalMobileSignature)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserDataService.isRememberUser)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserDataService.userInfo)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserDataService.username)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserDataService.isRememberMailboxPassword)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.PushNotificationService.token)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.PushNotificationService.UID)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.PushNotificationService.badToken)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.PushNotificationService.badUID)
        
        #if !Enterprise
        try? FileManager.default.removeItem(at: FileManager.default.applicationSupportDirectoryURL.appendingPathComponent("com.crashlytics"))
        try? FileManager.default.removeItem(at: FileManager.default.cachesDirectoryURL.appendingPathComponent("com.crashlytics.data"))
        try? FileManager.default.removeItem(at: FileManager.default.cachesDirectoryURL.appendingPathComponent("io.fabric.sdk.ios.data"))
        #endif
    }
    
    func logout() {
        self.versionSaver.set(newValue: nil)
    }
    
    
    func migrate(from verfrom: Int, to verto: Int) -> Bool {
        switch (verfrom, verto) {
        case (110, 111):
            // add try later
            return self.migrate_110_111()
        default:
            return false
        }
    }
}

extension AppCache {
    
    func migrate_110_111() -> Bool {
        if let userInfo = SharedCacheBase.getDefault().customObjectForKey(DeprecatedKeys.UserDataService.userInfo) as? UserInfo {
             AppCache.inject(userInfo: userInfo, into: sharedUserDataService)
        }
        if let username = SharedCacheBase.getDefault().string(forKey: DeprecatedKeys.UserDataService.username) {
            AppCache.inject(username: username, into: sharedUserDataService)
        }
        if let mobileSignature = SharedCacheBase.getDefault().string(forKey: DeprecatedKeys.UserCachedStatus.lastLocalMobileSignature) {
            userCachedStatus.mobileSignature = mobileSignature
        }
        
        // mailboxPassword
        if let triviallyProtectedMailboxPassword = sharedKeychain.keychain.string(forKey: DeprecatedKeys.UserDataService.mailboxPassword),
            let cleartextMailboxPassword = try? triviallyProtectedMailboxPassword.decrypt(withPwd: "$Proton$" + DeprecatedKeys.UserDataService.mailboxPassword)
        {
            sharedUserDataService.mailboxPassword = cleartextMailboxPassword
        }
        
        // AuthCredential
        if let credentialRaw = sharedKeychain.keychain.data(forKey: DeprecatedKeys.AuthCredential.keychainStore),
            let credential = NSKeyedUnarchiver.unarchiveObject(with: credentialRaw) as? AuthCredential
        {
            credential.storeInKeychain()
        }
        
        // MainKey
        let appLockMigration = DispatchGroup()
        var appWasLocked = false
        
        // via touch id
        if userCachedStatus.getShared().bool(forKey: DeprecatedKeys.UserCachedStatus.isTouchIDEnabled) {
            appWasLocked = true
            appLockMigration.enter()
            keymaker.activate(BioProtection()) { _ in appLockMigration.leave() }
        }
        
        // via pin
        if userCachedStatus.getShared().bool(forKey: DeprecatedKeys.UserCachedStatus.isPinCodeEnabled),
            let pin = sharedKeychain.keychain.string(forKey: DeprecatedKeys.UserCachedStatus.pinCodeCache)
        {
            appWasLocked = true
            appLockMigration.enter()
            keymaker.activate(PinProtection(pin: pin)) { _ in appLockMigration.leave() }
        }
        
        // and lock the app afterwards
        if appWasLocked {
            appLockMigration.notify(queue: .main) { keymaker.lockTheApp() }
        }
        
        return true
    }
}


extension AppCache {
    enum DeprecatedKeys {
        enum AuthCredential {
            static let keychainStore = "keychainStoreKey"
        }
        enum UserCachedStatus {
            static let pinCodeCache         = "pinCodeCache"
            static let enterBackgroundTime  = "enterBackgroundTime"
            static let isManuallyLockApp    = "isManuallyLockApp"
            static let isPinCodeEnabled     = "isPinCodeEnabled"
            static let isTouchIDEnabled     = "isTouchIDEnabled"
            static let touchIDEmail         = "touchIDEmail"
            static let lastLocalMobileSignature = "last_local_mobile_signature"
        }
        enum UserDataService {
            static let password                  = "passwordKey"
            static let mailboxPassword           = "mailboxPasswordKey"
            static let isRememberUser            = "isRememberUserKey"
            static let userInfo                  = "userInfoKey"
            static let isRememberMailboxPassword = "isRememberMailboxPasswordKey"
            static let username                  = "usernameKey"
        }
        enum PushNotificationService {
            static let token    = "DeviceTokenKey"
            static let UID      = "DeviceUID"
            
            static let badToken = "DeviceBadToken"
            static let badUID   = "DeviceBadUID"
        }
    }
}

