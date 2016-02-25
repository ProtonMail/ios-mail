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
        static let lastCacheVersion = "last_cache_version"
        static let isCheckSpaceDisabled = "isCheckSpaceDisabledKey"
        static let lastAuthCacheVersion = "last_auth_cache_version"
        
        //wait
        static let lastFetchMessageID = "last_fetch_message_id"
        static let lastFetchMessageTime = "last_fetch_message_time"
        static let lastUpdateTime = "last_update_time"
        static let historyTimeStamp = "history_timestamp"
        
        //Global Cache
        static let lastSplashViersion = "last_splash_viersion"
        static let lastTourViersion = "last_tour_viersion"
        
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
        
        getShared().synchronize()
    }
    
    func cleanGlobal() {
        getShared().removeObjectForKey(Key.lastSplashViersion)
        getShared().removeObjectForKey(Key.lastTourViersion);
        
        getShared().synchronize()
    }
}