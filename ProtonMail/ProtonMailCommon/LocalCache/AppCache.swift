//
//  AppVersion.swift
//  ProtonMail
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
import PMKeymaker
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
    
    internal var supportedVersions: [Int] = [Version.v110.rawValue,
                                             Version.v111.rawValue]
    
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
        static let CacheVersion : Int = 112 // this is app cache version
        
        case v110 = 110
        case v111 = 111
    }

    init() {
        self.latestVersion = Version.CacheVersion
        self.versionSaver = UserDefaultsSaver<Int>(key: Key.cacheVersion)
    }
    
    
    static func isFirstRun() -> Bool {
        return SharedCacheBase.getDefault().object(forKey: UserDataService.CoderKey.firstRunKey) == nil
    }
    
    func rebuild(reason: RebuildReason) {
        self.cleanLagacy()
        self.currentVersion = self.latestVersion
    }
    
    func cleanLagacy() {
        // Clear up the old stuff on fresh installs also
        KeychainWrapper.keychain.remove(forKey: DeprecatedKeys.UserDataService.password)
        KeychainWrapper.keychain.remove(forKey: DeprecatedKeys.UserDataService.mailboxPassword)
        KeychainWrapper.keychain.remove(forKey: DeprecatedKeys.UserCachedStatus.pinCodeCache)
        KeychainWrapper.keychain.remove(forKey: DeprecatedKeys.AuthCredential.keychainStore)
        KeychainWrapper.keychain.remove(forKey: DeprecatedKeys.UserCachedStatus.enterBackgroundTime)
        KeychainWrapper.keychain.remove(forKey: DeprecatedKeys.UserCachedStatus.linkOpeningMode)
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
            
        case (111, 112):
            return self.migrate_111_112()
            
        default:
            return false
        }
    }
}

extension AppCache {
    func migrate_111_112() -> Bool {
        // LinkOpeningMode was previously local for every device and stored in UserCachedStatus, but as of 1.11.9 it will be part of UserInfo and should be received from BE. This method is only needed to clear old value.
        KeychainWrapper.keychain.remove(forKey: DeprecatedKeys.UserCachedStatus.linkOpeningMode)
        
        return true
    }
    
    func migrate_110_111() -> Bool {
        /// if dev devices have run 1.11.3 before. some of the keys are stuck in the keychain. and if reinstall the app from the apple store(<= 1.11.2) and upgrade to the 1.11.3. the app will get the date from keychain which are shouldn't be there. so migrate from 110-111 should clean the data in keymaker which are saved in keychain. the same case also happens on core data migration but that cache could be removed from the reinstall app.
        keymaker.wipeMainKey()
        
        
//        if let userInfo = SharedCacheBase.getDefault().customObjectForKey(DeprecatedKeys.UserDataService.userInfo) as? UserInfo {
//             AppCache.inject(userInfo: userInfo, into: sharedUserDataService)
//        }
//        if let username = SharedCacheBase.getDefault().string(forKey: DeprecatedKeys.UserDataService.username) {
//            AppCache.inject(username: username, into: sharedUserDataService)
//        }
//        if let mobileSignature = SharedCacheBase.getDefault().string(forKey: DeprecatedKeys.UserCachedStatus.lastLocalMobileSignature) {
//            userCachedStatus.mobileSignature = mobileSignature
//        }
//        
//        // mailboxPassword
//        if let triviallyProtectedMailboxPassword = KeychainWrapper.keychain.string(forKey: DeprecatedKeys.UserDataService.mailboxPassword),
//            let cleartextMailboxPassword = ((try? triviallyProtectedMailboxPassword.decrypt(withPwd: "$Proton$" + DeprecatedKeys.UserDataService.mailboxPassword)) as String??)
//        {
//            sharedUserDataService.mailboxPassword = cleartextMailboxPassword
//        }
//        
//        // AuthCredential
//        if let credentialRaw = KeychainWrapper.keychain.data(forKey: DeprecatedKeys.AuthCredential.keychainStore),
//            let credential = AuthCredential.unarchive(data: credentialRaw as NSData)
//        {
////            credential.storeInKeychain()
//        }
//        
//        // MainKey
//        let appLockMigration = DispatchGroup()
//        var appWasLocked = false
//        
//        // via touch id
//        if userCachedStatus.getShared().bool(forKey: DeprecatedKeys.UserCachedStatus.isTouchIDEnabled) {
//            appWasLocked = true
//            appLockMigration.enter()
//            keymaker.activate(BioProtection()) { _ in appLockMigration.leave() }
//        }
//        
//        // via pin
//        if userCachedStatus.getShared().bool(forKey: DeprecatedKeys.UserCachedStatus.isPinCodeEnabled),
//            let pin = KeychainWrapper.keychain.string(forKey: DeprecatedKeys.UserCachedStatus.pinCodeCache)
//        {
//            appWasLocked = true
//            appLockMigration.enter()
//            keymaker.activate(PinProtection(pin: pin)) { _ in appLockMigration.leave() }
//        }
//        
//        // and lock the app afterwards
//        if appWasLocked {
//            appLockMigration.notify(queue: .main) { keymaker.lockTheApp() }
//        }
        
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
            
            static let linkOpeningMode = "linkOpeningMode"
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

