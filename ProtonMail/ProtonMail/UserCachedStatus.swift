//
//  MessageStatus.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

let userCachedStatus = UserCachedStatus(shared: NSUserDefaults.standardUserDefaults())

class UserCachedStatus : SharedCacheBase {
    
    struct Key {
        // inuse
        static let lastCacheVersion = "last_cache_version"
        static let isCheckSpaceDisabled = "isCheckSpaceDisabledKey"
        
        //wait
        static let lastFetchMessageID = "last_fetch_message_id"
        static let lastFetchMessageTime = "last_fetch_message_time"
        static let lastUpdateTime = "last_update_time"
        static let historyTimeStamp = "history_timestamp"
    }
    
    var isCheckSpaceDisabled: Bool {
        get {
            return getShared().boolForKey(Key.isCheckSpaceDisabled)
        }
        set {
            setValue(newValue, forKey: Key.isCheckSpaceDisabled)
        }
    }
    
    func isCacheOk() -> Bool {
        let cachedVersion = getShared().integerForKey(Key.lastCacheVersion)
        return cachedVersion == AppConstants.CacheVersion
    }
    
    func resetCache() -> Void {
        setValue(AppConstants.CacheVersion, forKey: Key.lastCacheVersion)
    }
    
    //    private var getLastFetchMessageID: String! {
    //        get {
    //            return getShared().stringForKey(Key.lastFetchMessageID) ?? "0"
    //        }
    //        set {
    //            setValue(newValue, forKey: Key.lastFetchMessageID)
    //        }
    //    }
    //
    //    private var getLastFetchMessageTime: Float {
    //        get {
    //            return getShared().floatForKey(Key.lastFetchMessageTime)
    //        }
    //        set {
    //            setValue(newValue, forKey: Key.lastFetchMessageTime)
    //        }
    //    }
    //
    //    private var getLastUpdateTime: Float {
    //        get {
    //            return getShared().floatForKey(Key.lastUpdateTime)
    //        }
    //        set {
    //            setValue(newValue, forKey: Key.lastUpdateTime)
    //        }
    //    }
    
    func signOut()
    {
        getShared().removeObjectForKey(Key.lastFetchMessageID);
        getShared().removeObjectForKey(Key.lastFetchMessageTime);
        getShared().removeObjectForKey(Key.lastUpdateTime);
        getShared().removeObjectForKey(Key.historyTimeStamp);
        getShared().removeObjectForKey(Key.lastCacheVersion);
        getShared().removeObjectForKey(Key.isCheckSpaceDisabled);
        getShared().synchronize()
    }
}