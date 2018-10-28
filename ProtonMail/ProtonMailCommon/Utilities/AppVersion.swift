//
//  AppVersion.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 15/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import Keymaker
import Pm

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
    
    internal func migration() { // FIXME: this logic should depend of pre-migration version and current version
        // Values need to be protected with mainKey
        
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
        userCachedStatus.getShared().removeObject(forKey: UserCachedStatus.Key.isTouchIDEnabled)
        userCachedStatus.getShared().removeObject(forKey: UserCachedStatus.Key.isPinCodeEnabled)
        userCachedStatus.getShared().removeObject(forKey: UserCachedStatus.Key.isManuallyLockApp)
        userCachedStatus.getShared().removeObject(forKey: UserCachedStatus.Key.touchIDEmail)
        SharedCacheBase.getDefault()?.removeObject(forKey: UserDataService.Key.userInfoPreMainKey)
    }
}
