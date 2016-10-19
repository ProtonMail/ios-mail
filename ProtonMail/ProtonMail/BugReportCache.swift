//
//  BugReportCache.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 10/19/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation



let cachedBugReport = BugReportCache(shared: NSUserDefaults.standardUserDefaults())

public class BugReportCache : SharedCacheBase {
    
    private struct Key {
        static let lastBugReport = "BugReportCache_LastBugReport"
    }
    
    public var cachedBug: String! {
        get {
            return getShared().stringForKey(Key.lastBugReport) ?? ""
        }
        set {
            getShared().setValue(newValue, forKey: Key.lastBugReport)
            getShared().synchronize()
        }
    }
    
    public func clear() {
        getShared().removeObjectForKey(Key.lastBugReport)
        getShared().synchronize()
    }
}