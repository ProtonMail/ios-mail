//
//  MessageStatus.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



let localCacheStatus = CacheStatus()
class CacheStatus {
    
    struct Key {
        static let lastFetchMessageID = "last_fetch_message_id"
        static let lastFetchMessageTime = "last_fetch_message_time"
        static let lastUpdateTime = "last_update_time"
        static let historyTimeStamp = "history_timestamp"
        static let lastCacheVersion = "last_cache_version"
    }
    
    private var getLastFetchMessageID: String {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey(Key.lastFetchMessageID) ?? "0"
        }
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: Key.lastFetchMessageID)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private var getLastFetchMessageTime: Float {
        get {
            return NSUserDefaults.standardUserDefaults().floatForKey(Key.lastFetchMessageTime)
        }
        set {
            NSUserDefaults.standardUserDefaults().setFloat(newValue, forKey: Key.lastFetchMessageTime)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private var getLastUpdateTime: Float {
        get {
            return NSUserDefaults.standardUserDefaults().floatForKey(Key.lastUpdateTime)
        }
        set {
            NSUserDefaults.standardUserDefaults().setFloat(newValue, forKey: Key.lastUpdateTime)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    func isCacheOk() -> Bool {
        let cachedVersion = NSUserDefaults.standardUserDefaults().integerForKey(Key.lastCacheVersion)
        return cachedVersion == AppConstants.CacheVersion
    }
    
    func resetCache() -> Void {
        NSUserDefaults.standardUserDefaults().setInteger(AppConstants.CacheVersion, forKey: Key.lastCacheVersion)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    
    func signOut()
    {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Key.lastFetchMessageID);
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Key.lastFetchMessageTime);
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Key.lastUpdateTime);
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Key.historyTimeStamp);
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Key.lastCacheVersion);
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
}