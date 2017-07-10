//
//  MessageStatus.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

public let userCachedStatus = UserCachedStatus(shared: UserDefaults.standard)

//the data in there store longer.

public class UserCachedStatus : SharedCacheBase {
    struct Key {
        // inuse
        static let lastCacheVersion = "last_cache_version" //user cache
        static let isCheckSpaceDisabled = "isCheckSpaceDisabledKey" //user cache
        static let lastAuthCacheVersion = "last_auth_cache_version" //user cache
        static let cachedServerNotices = "cachedServerNotices" //user cache
        static let showServerNoticesNextTime = "showServerNoticesNextTime" //user cache
        
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
    }
    
    public var isForcedLogout : Bool = false
    
    public var isCheckSpaceDisabled: Bool {
        get {
            return getShared().bool(forKey: Key.isCheckSpaceDisabled)
        }
        set {
            setValue(newValue, forKey: Key.isCheckSpaceDisabled)
        }
    }
    
    public var serverNotices : [String] {
        get {
            return getShared().object(forKey: Key.cachedServerNotices) as? [String] ?? [String]()
        }
        set {
            setValue(newValue, forKey: Key.cachedServerNotices)
        }
    }
    
    public var serverNoticesNextTime : String {
        get {
            return getShared().string(forKey: Key.showServerNoticesNextTime) ?? "0"
        }
        set {
            setValue(newValue, forKey: Key.showServerNoticesNextTime)
        }
    }
    
    public func isSplashOk() -> Bool {
        let splashVersion = getShared().integer(forKey: Key.lastSplashViersion)
        return splashVersion == AppConstants.SplashVersion
    }
    
    public func isTourOk() -> Bool {
        let tourVersion = getShared().integer(forKey: Key.lastTourViersion)
        return tourVersion == AppConstants.TourVersion
    }
    
    public func showTourNextTime() {
        setValue(0, forKey: Key.lastTourViersion)
    }
    
    public func isCacheOk() -> Bool {
        let cachedVersion = getShared().integer(forKey: Key.lastCacheVersion)
        return cachedVersion == AppConstants.CacheVersion
    }
    
    public func isAuthCacheOk() -> Bool {
        let cachedVersion = getShared().integer(forKey: Key.lastAuthCacheVersion)
        return cachedVersion == AppConstants.AuthCacheVersion
    }
    
    public func resetCache() -> Void {
        setValue(AppConstants.CacheVersion, forKey: Key.lastCacheVersion)
    }
    
    public func resetAuthCache() -> Void {
        setValue(AppConstants.AuthCacheVersion, forKey: Key.lastAuthCacheVersion)
    }
    
    public func resetSplashCache() -> Void {
        setValue(AppConstants.SplashVersion, forKey: Key.lastSplashViersion)
    }
    
    public func resetTourValue() {
        setValue(AppConstants.TourVersion, forKey: Key.lastTourViersion)
    }
    
    public var mobileSignature : String {
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
    
    public var pinFailedCount : Int {
        get {
            return getShared().integer(forKey: Key.lastPinFailedTimes)
        }
        set {
            setValue(newValue, forKey: Key.lastPinFailedTimes)
        }
    }
    
    public func resetMobileSignature() {
        getShared().removeObject(forKey: Key.lastLocalMobileSignature)
        getShared().synchronize()
    }
    
    public func signOut()
    {
        getShared().removeObject(forKey: Key.lastFetchMessageID);
        getShared().removeObject(forKey: Key.lastFetchMessageTime);
        getShared().removeObject(forKey: Key.lastUpdateTime);
        getShared().removeObject(forKey: Key.historyTimeStamp);
        getShared().removeObject(forKey: Key.lastCacheVersion);
        getShared().removeObject(forKey: Key.isCheckSpaceDisabled);
        getShared().removeObject(forKey: Key.cachedServerNotices);
        getShared().removeObject(forKey: Key.showServerNoticesNextTime);
        getShared().removeObject(forKey: Key.lastAuthCacheVersion);
        
        //touch id
        getShared().removeObject(forKey: Key.touchIDEmail);
        
        //pin code
        getShared().removeObject(forKey: Key.isPinCodeEnabled)
        UICKeyChainStore.removeItem(forKey: Key.pinCodeCache)
        UICKeyChainStore.removeItem(forKey: Key.lastLoggedInUser)
        UICKeyChainStore.removeItem(forKey: Key.autoLockTime)
        UICKeyChainStore.removeItem(forKey: Key.enterBackgroundTime)
        getShared().removeObject(forKey: Key.lastPinFailedTimes)
        getShared().removeObject(forKey: Key.isManuallyLockApp)
        
        
        getShared().synchronize()
    }
    
    public func cleanGlobal() {
        getShared().removeObject(forKey: Key.lastSplashViersion)
        getShared().removeObject(forKey: Key.lastTourViersion);
        
        //touch id
        getShared().removeObject(forKey: Key.isTouchIDEnabled)
        getShared().removeObject(forKey: Key.autoLogoutTime);
        getShared().removeObject(forKey: Key.askEnableTouchID)
        getShared().removeObject(forKey: Key.isManuallyLockApp)
        
        //
        
        //
        getShared().removeObject(forKey: Key.lastLocalMobileSignature)
        
        getShared().synchronize()
    }
}


// touch id part
extension UserCachedStatus {
    public var touchIDEmail : String {
        get {
            return getShared().string(forKey: Key.touchIDEmail) ?? ""
        }
        set {
            setValue(newValue, forKey: Key.touchIDEmail)
        }
    }
    
    public func resetTouchIDEmail() {
        setValue("", forKey: Key.touchIDEmail)
    }
    
    public var isTouchIDEnabled : Bool {
        get {
            return getShared().bool(forKey: Key.isTouchIDEnabled)
        }
        set {
            setValue(newValue, forKey: Key.isTouchIDEnabled)
        }
    }
    
    public var isPinCodeEnabled : Bool {
        get {
            return getShared().bool(forKey: Key.isPinCodeEnabled)
        }
        set {
            setValue(newValue, forKey: Key.isPinCodeEnabled)
        }
    }
    
    /// Value is only stored in the keychain
    public var pinCode : String {
        get {
            return UICKeyChainStore.string(forKey: Key.pinCodeCache) ?? ""
        }
        set {
            UICKeyChainStore.setString(newValue, forKey: Key.pinCodeCache)
        }
    }
    
    public var lockTime : String {
        get {
            return UICKeyChainStore.string(forKey: Key.autoLockTime) ?? "-1"
        }
        set {
            UICKeyChainStore.setString(newValue, forKey: Key.autoLockTime)
        }
    }
    
    public var exitTime : String {
        get {
            return UICKeyChainStore.string(forKey: Key.enterBackgroundTime) ?? "0"
        }
        set {
            UICKeyChainStore.setString(newValue, forKey: Key.enterBackgroundTime)
        }
    }
    
    public var lockedApp : Bool {
        get {
            return getShared().bool(forKey: Key.isManuallyLockApp)
        }
        set {
            setValue(newValue, forKey: Key.isManuallyLockApp)
        }
    }
    
    public var lastLoggedInUser : String? {
        get {
            return UICKeyChainStore.string(forKey: Key.lastLoggedInUser)
        }
        set {
            UICKeyChainStore.setString(newValue, forKey: Key.lastLoggedInUser)
        }
    }
    
    public func alreadyAskedEnableTouchID () -> Bool {
        let code = getShared().integer(forKey: Key.askEnableTouchID)
        return code == AppConstants.AskTouchID
    }
    
    public func resetAskedEnableTouchID() {
        setValue(AppConstants.AskTouchID, forKey: Key.askEnableTouchID)
    }
    
}

