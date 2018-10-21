//
//  MessageStatus.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import UICKeyChainStore

let userCachedStatus = UserCachedStatus()

//the data in there store longer.

final class UserCachedStatus : SharedCacheBase {
    struct Key {
        // inuse
        static let lastCacheVersion = "last_cache_version" //user cache
        static let isCheckSpaceDisabled = "isCheckSpaceDisabledKey" //user cache
        static let lastAuthCacheVersion = "last_auth_cache_version" //user cache
        static let cachedServerNotices = "cachedServerNotices" //user cache
        static let showServerNoticesNextTime = "showServerNoticesNextTime" //user cache
        static let isPM_MEWarningDisabled = "isPM_MEWarningDisabledKey" //user cache -- maybe could be global
        
        // touch id 
        static let isTouchIDEnabled = "isTouchIDEnabled" //global cache
        static let autoLogoutTime = "autoLogoutTime" //global cache
        static let touchIDEmail = "touchIDEmail" //user cache
        static let askEnableTouchID = "askEnableTouchID" //global cache
        
        // pin code
        static let isPinCodeEnabled = "isPinCodeEnabled" //user cache but could restore
        static let pinCodeCache = "pinCodeCache" //user cache but could restore
        static let autoLockTime = "autoLockTime" ///user cache but could restore
        static let enterBackgroundTime = "enterBackgroundTime"
        static let lastLoggedInUser = "lastLoggedInUser" //user cache but could restore
        static let lastPinFailedTimes = "lastPinFailedTimes" //user cache can't restore
        
        
        static let isManuallyLockApp = "isManuallyLockApp"
        
        //wait
        static let lastFetchMessageID = "last_fetch_message_id"
        static let lastFetchMessageTime = "last_fetch_message_time"
        static let lastUpdateTime = "last_update_time"
        static let historyTimeStamp = "history_timestamp"
        
        //Global Cache
        static let lastSplashViersion = "last_splash_viersion" //global cache
        static let lastTourViersion = "last_tour_viersion" //global cache
        static let lastLocalMobileSignature = "last_local_mobile_signature" //user cache but could restore
        
        // Snooze Notifications
        static let snoozeConfiguration = "snoozeConfiguration"
        
        // FIX ME: double check if the value belongs to user. move it into user object. 2.0
        static let servicePlans = "servicePlans"
        static let currentSubscription = "currentSubscription"
        static let defaultPlanDetails = "defaultPlanDetails"
        static let isIAPAvailable = "isIAPAvailable"
    }
    
    var isForcedLogout : Bool = false
    
    var isCheckSpaceDisabled: Bool {
        get {
            return getShared().bool(forKey: Key.isCheckSpaceDisabled)
        }
        set {
            setValue(newValue, forKey: Key.isCheckSpaceDisabled)
        }
    }
    
    var isPMMEWarningDisabled : Bool {
        get {
            return getShared().bool(forKey: Key.isPM_MEWarningDisabled)
        }
        set {
            setValue(newValue, forKey: Key.isPM_MEWarningDisabled)
        }
    }
    
    var serverNotices : [String] {
        get {
            return getShared().object(forKey: Key.cachedServerNotices) as? [String] ?? [String]()
        }
        set {
            setValue(newValue, forKey: Key.cachedServerNotices)
        }
    }
    
    var serverNoticesNextTime : String {
        get {
            return getShared().string(forKey: Key.showServerNoticesNextTime) ?? "0"
        }
        set {
            setValue(newValue, forKey: Key.showServerNoticesNextTime)
        }
    }
    
    func isSplashOk() -> Bool {
        let splashVersion = getShared().integer(forKey: Key.lastSplashViersion)
        return splashVersion == AppConstants.SplashVersion
    }
    
    func isTourOk() -> Bool {
        let tourVersion = getShared().integer(forKey: Key.lastTourViersion)
        return tourVersion == AppConstants.TourVersion
    }
    
    func showTourNextTime() {
        setValue(0, forKey: Key.lastTourViersion)
    }
    
    func isCacheOk() -> Bool {
        let cachedVersion = getShared().integer(forKey: Key.lastCacheVersion)
        return cachedVersion == AppConstants.CacheVersion
    }
    
    var lastCacheVersion : Int {
        get {
            let cachedVersion = getShared().integer(forKey: Key.lastCacheVersion)
            return cachedVersion
        }
    }
    
    func isAuthCacheOk() -> Bool {
        let cachedVersion = getShared().integer(forKey: Key.lastAuthCacheVersion)
        return cachedVersion == AppConstants.AuthCacheVersion
    }
    
    func resetCache() -> Void {
        setValue(AppConstants.CacheVersion, forKey: Key.lastCacheVersion)
    }
    
    func resetAuthCache() -> Void {
        setValue(AppConstants.AuthCacheVersion, forKey: Key.lastAuthCacheVersion)
    }
    
    func resetSplashCache() -> Void {
        setValue(AppConstants.SplashVersion, forKey: Key.lastSplashViersion)
    }
    
    func resetTourValue() {
        setValue(AppConstants.TourVersion, forKey: Key.lastTourViersion)
    }
    
    var mobileSignature : String {
        get {
            if let s = getShared().string(forKey: Key.lastLocalMobileSignature) {
                return s
            }
            return "Sent from ProtonMail Mobile"
        }
        set {
            setValue(newValue, forKey: Key.lastLocalMobileSignature)
        }
    }
    
    var pinFailedCount : Int {
        get {
            return getShared().integer(forKey: Key.lastPinFailedTimes)
        }
        set {
            setValue(newValue, forKey: Key.lastPinFailedTimes)
        }
    }
    
    func resetMobileSignature() {
        getShared().removeObject(forKey: Key.lastLocalMobileSignature)
        getShared().synchronize()
    }
    
    func signOut()
    {
        getShared().removeObject(forKey: Key.lastFetchMessageID)
        getShared().removeObject(forKey: Key.lastFetchMessageTime)
        getShared().removeObject(forKey: Key.lastUpdateTime)
        getShared().removeObject(forKey: Key.historyTimeStamp)
        getShared().removeObject(forKey: Key.lastCacheVersion)
        getShared().removeObject(forKey: Key.isCheckSpaceDisabled)
        getShared().removeObject(forKey: Key.cachedServerNotices)
        getShared().removeObject(forKey: Key.showServerNoticesNextTime)
        getShared().removeObject(forKey: Key.lastAuthCacheVersion)
        getShared().removeObject(forKey: Key.isPM_MEWarningDisabled)
        
        //touch id
        getShared().removeObject(forKey: Key.touchIDEmail)
        
        //pin code
        getShared().removeObject(forKey: Key.isPinCodeEnabled)
        getShared().removeObject(forKey: Key.lastPinFailedTimes)
        getShared().removeObject(forKey: Key.isManuallyLockApp)
        
        //for version <= 1.6.5 clean old stuff.
        UICKeyChainStore.removeItem(forKey: Key.pinCodeCache)
        UICKeyChainStore.removeItem(forKey: Key.lastLoggedInUser)
        UICKeyChainStore.removeItem(forKey: Key.autoLockTime)
        UICKeyChainStore.removeItem(forKey: Key.enterBackgroundTime)
        
        //for newer version > 1.6.5
        sharedKeychain.keychain.removeItem(forKey: Key.pinCodeCache)
        sharedKeychain.keychain.removeItem(forKey: Key.lastLoggedInUser)
        sharedKeychain.keychain.removeItem(forKey: Key.autoLockTime)
        sharedKeychain.keychain.removeItem(forKey: Key.enterBackgroundTime)
        
        // Clean the keys Anatoly added
        getShared().removeObject(forKey: Key.snoozeConfiguration)
        getShared().removeObject(forKey: Key.servicePlans)
        getShared().removeObject(forKey: Key.currentSubscription)
        getShared().removeObject(forKey: Key.defaultPlanDetails)
        getShared().removeObject(forKey: Key.isIAPAvailable)
                        
        getShared().synchronize()
    }
    
    func cleanGlobal() {
        getShared().removeObject(forKey: Key.lastSplashViersion)
        getShared().removeObject(forKey: Key.lastTourViersion)
        
        //touch id
        getShared().removeObject(forKey: Key.isTouchIDEnabled)
        getShared().removeObject(forKey: Key.autoLogoutTime)
        getShared().removeObject(forKey: Key.askEnableTouchID)
        getShared().removeObject(forKey: Key.isManuallyLockApp)
        
        //
        getShared().removeObject(forKey: Key.lastLocalMobileSignature)
       
        getShared().synchronize()
    }
}


// touch id part
extension UserCachedStatus {
    var isTouchIDEnabled: Bool {
        return keymaker.isProtectorActive(BioProtection.self)
    }
    
    var isPinCodeEnabled : Bool {
        return keymaker.isProtectorActive(PinProtection.self)
    }
    
    var lockTime : String {
        get {
            return sharedKeychain.keychain.string(forKey: Key.autoLockTime) ?? "-1"
        }
        set {
            sharedKeychain.keychain.setString(newValue, forKey: Key.autoLockTime)
        }
    }
    
    var exitTime : String {
        get {
            return sharedKeychain.keychain.string(forKey: Key.enterBackgroundTime) ?? "0"
        }
        set {
            sharedKeychain.keychain.setString(newValue, forKey: Key.enterBackgroundTime)
        }
    }
    
    var lastLoggedInUser : String? {
        get {
            return sharedKeychain.keychain.string(forKey: Key.lastLoggedInUser)
        }
        set {
            sharedKeychain.keychain.setString(newValue, forKey: Key.lastLoggedInUser)
        }
    }
    
    func alreadyAskedEnableTouchID () -> Bool {
        let code = getShared().integer(forKey: Key.askEnableTouchID)
        return code == AppConstants.AskTouchID
    }
    
    func resetAskedEnableTouchID() {
        setValue(AppConstants.AskTouchID, forKey: Key.askEnableTouchID)
    }
}


#if !APP_EXTENSION
extension UserCachedStatus: ServicePlanDataStorage {
    var servicePlansDetails: [ServicePlanDetails]? {
        get {
            guard let data = self.getShared().data(forKey: Key.servicePlans) else {
                return nil
            }
            return try? PropertyListDecoder().decode(Array<ServicePlanDetails>.self, from: data)
        }
        set {
            let data = try? PropertyListEncoder().encode(newValue)
            self.setValue(data, forKey: Key.servicePlans)
        }
    }
    
    var defaultPlanDetails: ServicePlanDetails? {
        get {
            guard let data = self.getShared().data(forKey: Key.defaultPlanDetails) else {
                return nil
            }
            return try? PropertyListDecoder().decode(ServicePlanDetails.self, from: data)
        }
        set {
            let data = try? PropertyListEncoder().encode(newValue)
            self.setValue(data, forKey: Key.defaultPlanDetails)
        }
    }
    
    var currentSubscription: Subscription? {
        get {
            guard let data = self.getShared().data(forKey: Key.currentSubscription) else {
                return nil
            }
            return try? PropertyListDecoder().decode(Subscription.self, from: data)
        }
        set {
            let data = try? PropertyListEncoder().encode(newValue)
            self.setValue(data, forKey: Key.currentSubscription)
        }
    }
    
    var isIAPAvailable: Bool {
        get {
            return self.getShared().bool(forKey: Key.isIAPAvailable)
        }
        set {
            self.setValue(newValue, forKey: Key.isIAPAvailable)
        }
    }
}
#endif
