//
//  LastUpdatedStore.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

class LastUpdatedStore {
    
    private struct Key {
        static let lastUpdated = "LastUpdatedKey"
    }
    
    private var lastUpdateds: Dictionary<String, NSDate> {
        get {
            return (NSUserDefaults.standardUserDefaults().objectForKey(Key.lastUpdated) as? Dictionary<String, NSDate>) ?? [:]
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: Key.lastUpdated)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    subscript(key: String) -> NSDate {
        get {
            return lastUpdatedForKey(key)
        }
        set {
            setLastUpdated(newValue, forKey: key)
        }
    }
    
    /// Clears all the last updated values from the store.
    func clear() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Key.lastUpdated)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func lastUpdatedForKey(key: String) -> NSDate {
        return lastUpdateds[key] ?? (NSDate.distantPast() as NSDate)
    }
    
    func setLastUpdated(date: NSDate, forKey key: String) {
        lastUpdateds[key] = date
    }
}