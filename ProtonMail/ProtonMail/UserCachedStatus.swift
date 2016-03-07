//
//  MessageStatus.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

let userCachedStatus = UserCachedStatus(shared: NSUserDefaults.standardUserDefaults())

//the data in there store longer.

class UserCachedStatus : SharedCacheBase {
    struct Key {
        // inuse
        static let lastCacheVersion = "last_cache_version" //user cache
        static let isCheckSpaceDisabled = "isCheckSpaceDisabledKey" //user cache
        static let lastAuthCacheVersion = "last_auth_cache_version" //user cache
        
        // touch id 
        static let isTouchIDEnabled = "isTouchIDEnabled" //global cache
        static let autoLogoutTime = "autoLogoutTime" //global cache
        static let touchIDEmail = "touchIDEmail" //user cache
        static let askEnableTouchID = "askEnableTouchID" //global cache
        
        //wait
        static let lastFetchMessageID = "last_fetch_message_id"
        static let lastFetchMessageTime = "last_fetch_message_time"
        static let lastUpdateTime = "last_update_time"
        static let historyTimeStamp = "history_timestamp"
        
        //Global Cache
        static let lastSplashViersion = "last_splash_viersion" //global cache
        static let lastTourViersion = "last_tour_viersion" //global cache
    }
    
    var isForcedLogout : Bool = false
    
    var isCheckSpaceDisabled: Bool {
        get {
            return getShared().boolForKey(Key.isCheckSpaceDisabled)
        }
        set {
            setValue(newValue, forKey: Key.isCheckSpaceDisabled)
        }
    }
    
    func isSplashOk() -> Bool {
        let splashVersion = getShared().integerForKey(Key.lastSplashViersion)
        return splashVersion == AppConstants.SplashVersion
    }
    
    func isTourOk() -> Bool {
        let tourVersion = getShared().integerForKey(Key.lastTourViersion)
        return tourVersion == AppConstants.TourVersion
    }
    
    func showTourNextTime() {
        setValue(0, forKey: Key.lastTourViersion)
    }
    
    func isCacheOk() -> Bool {
        let cachedVersion = getShared().integerForKey(Key.lastCacheVersion)
        return cachedVersion == AppConstants.CacheVersion
    }
    
    func isAuthCacheOk() -> Bool {
        let cachedVersion = getShared().integerForKey(Key.lastAuthCacheVersion)
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
    
    func signOut()
    {
        getShared().removeObjectForKey(Key.lastFetchMessageID);
        getShared().removeObjectForKey(Key.lastFetchMessageTime);
        getShared().removeObjectForKey(Key.lastUpdateTime);
        getShared().removeObjectForKey(Key.historyTimeStamp);
        getShared().removeObjectForKey(Key.lastCacheVersion);
        getShared().removeObjectForKey(Key.isCheckSpaceDisabled);
        getShared().removeObjectForKey(Key.lastAuthCacheVersion);
        
        //touch id
        getShared().removeObjectForKey(Key.touchIDEmail);
        
        getShared().synchronize()
    }
    
    func cleanGlobal() {
        getShared().removeObjectForKey(Key.lastSplashViersion)
        getShared().removeObjectForKey(Key.lastTourViersion);
        
        //touch id
        getShared().removeObjectForKey(Key.isTouchIDEnabled)
        getShared().removeObjectForKey(Key.autoLogoutTime);
        getShared().removeObjectForKey(Key.askEnableTouchID)
        
        getShared().synchronize()
    }
}


// touch id part
extension UserCachedStatus {
    var touchIDEmail : String {
        get {
            return getShared().stringForKey(Key.touchIDEmail) ?? ""
        }
        set {
            setValue(newValue, forKey: Key.touchIDEmail)
        }
    }
    func resetTouchIDEmail() {
        setValue("", forKey: Key.touchIDEmail)
    }
    
// static let autoLogoutTime = "autoLogoutTime" //global cache
// static let askEnableTouchID = "askEnableTouchID" //global cache
    var isTouchIDEnabled : Bool {
        get {
            return getShared().boolForKey(Key.isTouchIDEnabled)
        }
        set {
            setValue(newValue, forKey: Key.isTouchIDEnabled)
        }
    }
    
    func alreadyAskedEnableTouchID () -> Bool {
        let code = getShared().integerForKey(Key.askEnableTouchID)
        return code == AppConstants.AskTouchID
    }
    
    func resetAskedEnableTouchID() {
        setValue(AppConstants.AskTouchID, forKey: Key.askEnableTouchID)
    }
    
//
//    func resetCache() -> Void {
//        setValue(AppConstants.CacheVersion, forKey: Key.lastCacheVersion)
//    }
//    
//    func resetAuthCache() -> Void {
//        setValue(AppConstants.AuthCacheVersion, forKey: Key.lastAuthCacheVersion)
//    }
//    
//    func resetSplashCache() -> Void {
//        setValue(AppConstants.SplashVersion, forKey: Key.lastSplashViersion)
//    }
//    
//    func resetTourValue() {
//        setValue(AppConstants.TourVersion, forKey: Key.lastTourViersion)
//    }
    
    
}

