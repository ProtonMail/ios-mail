//
//  UserTempCachedStatus.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/15/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


let userDebugCached =  NSUserDefaults.standardUserDefaults()
class UserTempCachedStatus: NSObject, NSCoding {
    struct Key{
        static let keychainStore = "UserTempCachedStatusKey"
    }
    
    var lastLoggedInUser : String!
    
    var touchIDEmail : String!
    var isPinCodeEnabled : Bool
    var pinCodeCache : String!
    var autoLockTime : String!
    var showMobileSignature : Bool
    var localMobileSignature : String!
    
    required init(lastLoggedInUser: String!, touchIDEmail: String!, isPinCodeEnabled: Bool, pinCodeCache: String!, autoLockTime : String!, showMobileSignature: Bool, localMobileSignature:String!) {
        self.lastLoggedInUser = lastLoggedInUser ?? ""
        self.touchIDEmail = touchIDEmail ?? ""
        self.isPinCodeEnabled = isPinCodeEnabled
        self.pinCodeCache = pinCodeCache ?? ""
        self.autoLockTime = autoLockTime ?? "-1"
        self.showMobileSignature = showMobileSignature
        self.localMobileSignature = localMobileSignature ?? ""
        super.init()
    }
    
    convenience required init(coder aDecoder: NSCoder) {
        self.init(
            lastLoggedInUser: aDecoder.decodeObjectForKey(CoderKey.lastLoggedInUser) as? String,
            touchIDEmail: aDecoder.decodeObjectForKey(CoderKey.touchIDEmail) as? String,
            isPinCodeEnabled: aDecoder.decodeObjectForKey(CoderKey.isPinCodeEnabled) as? Bool ?? false,
            pinCodeCache: aDecoder.decodeObjectForKey(CoderKey.pinCodeCache) as? String,
            autoLockTime: aDecoder.decodeObjectForKey(CoderKey.autoLockTime) as? String,
            showMobileSignature: aDecoder.decodeObjectForKey(CoderKey.showMobileSignature) as? Bool ?? false,
            localMobileSignature: aDecoder.decodeObjectForKey(CoderKey.localMobileSignature) as? String);
    }
    
    struct CoderKey {
        static let lastLoggedInUser = "lastLoggedInUser"
        static let touchIDEmail = "isPinCodeEnabled"
        static let isPinCodeEnabled = "isPinCodeEnabled"
        static let pinCodeCache = "pinCodeCache"
        static let autoLockTime = "autoLockTime"
        static let showMobileSignature = "showMobileSignature"
        static let localMobileSignature = "localMobileSignature"
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(lastLoggedInUser, forKey: CoderKey.lastLoggedInUser)
        aCoder.encodeObject(touchIDEmail, forKey: CoderKey.touchIDEmail)
        aCoder.encodeObject(isPinCodeEnabled, forKey: CoderKey.isPinCodeEnabled)
        aCoder.encodeObject(pinCodeCache, forKey: CoderKey.pinCodeCache)
        aCoder.encodeObject(autoLockTime, forKey: CoderKey.autoLockTime)
        aCoder.encodeObject(showMobileSignature, forKey: CoderKey.showMobileSignature)
        aCoder.encodeObject(localMobileSignature, forKey: CoderKey.localMobileSignature)
    }
    
    
    class func backup () {
        let u = UserTempCachedStatus(
            lastLoggedInUser: sharedUserDataService.username,
            touchIDEmail: userCachedStatus.touchIDEmail,
            isPinCodeEnabled: userCachedStatus.isPinCodeEnabled,
            pinCodeCache: userCachedStatus.pinCode,
            autoLockTime: userCachedStatus.lockTime,
            showMobileSignature: sharedUserDataService.showMobileSignature,
            localMobileSignature: userCachedStatus.mobileSignature)
        u.storeInKeychain()
    }
    
    class func restore() {
        if let cache = UserTempCachedStatus.fetchFromKeychain() {
            if sharedUserDataService.username == cache.lastLoggedInUser {
                userCachedStatus.touchIDEmail = cache.touchIDEmail ?? ""
                userCachedStatus.isPinCodeEnabled = cache.isPinCodeEnabled
                userCachedStatus.pinCode = cache.pinCodeCache ?? ""
                userCachedStatus.lockTime = cache.autoLockTime ?? "-1"
                sharedUserDataService.showMobileSignature = cache.showMobileSignature
                userCachedStatus.mobileSignature = cache.localMobileSignature ?? ""
            }
        }
        UserTempCachedStatus.clearFromKeychain()
    }
    
    
    func storeInKeychain() {
        userCachedStatus.isForcedLogout = false
        #if DEBUG
            userDebugCached.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: Key.keychainStore)
        #else
            UICKeyChainStore().setData(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: Key.keychainStore)
        #endif
    }
    
    // MARK - Class methods
    class func clearFromKeychain() {
        userDebugCached.removeObjectForKey(Key.keychainStore)
        UICKeyChainStore.removeItemForKey(Key.keychainStore)
    }
    
    class func fetchFromKeychain() -> UserTempCachedStatus? {
        
        #if DEBUG
            if let data = userDebugCached.dataForKey(Key.keychainStore) {
                if let authCredential = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? UserTempCachedStatus {
                    return authCredential
                }
            }
        #else
            if let data = UICKeyChainStore.dataForKey(Key.keychainStore) {
                if let authCredential = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? UserTempCachedStatus {
                    return authCredential
                }
            }
        #endif
        
        return nil
    }
}
