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



import Foundation


let lastUpdatedStore = LastUpdatedStore(shared: NSUserDefaults.standardUserDefaults())

public class LastUpdatedStore : SharedCacheBase {

    
    private struct Key {
        static let lastInboxesUpdated = "LastInboxesUpdated"
        static let lastLabelsUpdated = "LastLabelsUpdated"
        static let lastCantactsUpdated = "LastCantactsUpdated"
    }
    
    
    public class UpdateTime : NSObject, NSCoding {
        
        private struct CoderKey {
            static let startCode = "start"
            static let endCode = "end"
        }
        
        required public init (start: NSDate!, end : NSDate){
            self.start = start
            self.end = end
        }
        
        public convenience required init(coder aDecoder: NSCoder) {
            self.init(
                start: aDecoder.decodeObjectForKey(CoderKey.startCode) as! NSDate,
                end: aDecoder.decodeObjectForKey(CoderKey.endCode) as! NSDate)
        }
        
        public func encodeWithCoder(aCoder: NSCoder) {
            aCoder.encodeObject(self.start, forKey: CoderKey.startCode)
            aCoder.encodeObject(self.end, forKey: CoderKey.endCode)
        }
        
        
        public var start : NSDate
        public var end : NSDate
        
        static public func distantPast() -> UpdateTime {
            return UpdateTime(start: NSDate.distantPast() as! NSDate, end: NSDate.distantPast() as! NSDate)
        }
    }
    
    private var lastInboxesUpdateds: Dictionary<String, UpdateTime> {
        get {
            return (NSUserDefaults.standardUserDefaults().customObjectForKey(Key.lastInboxesUpdated) as? Dictionary<String, UpdateTime>) ?? [:]
        }
        set {
            NSUserDefaults.standardUserDefaults().setCustomValue(newValue, forKey: Key.lastInboxesUpdated)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }

//    public func getInboxesLastUpdate(key: String) -> UpdateTime {
//        return UpdateTime(start: NSDate.distantPast() as! NSDate, end: NSDate.distantPast() as! NSDate)
//    }
//    
//    public func getLabelsLastUpdate(key: String) -> UpdateTime {
//        return UpdateTime(start: NSDate.distantPast() as! NSDate, end: NSDate.distantPast() as! NSDate)
//    }
//    
//    public func getContactsLastUpdate(key: String) -> UpdateTime {
//        return UpdateTime(start: NSDate.distantPast() as! NSDate, end: NSDate.distantPast() as! NSDate)
//    }
    
    
    /**
    clear the last update time cache
    */
    public func clear() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Key.lastCantactsUpdated)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Key.lastLabelsUpdated)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Key.lastInboxesUpdated)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    
    /**
    get the inbox last update time by location
    
    :param: location MessageLocation
    
    :returns: the Update Time
    */
    public func inboxLastForKey(location : MessageLocation) -> UpdateTime {
        return lastInboxesUpdateds[location.key] ?? UpdateTime.distantPast()
    }
    
    
    /**
    update the exsit inbox last update time by location
    
    :param: location   message location
    :param: updateTime the new update time
    */
    public func updateInboxForKey(location : MessageLocation, updateTime: UpdateTime) -> Void {
        return lastInboxesUpdateds[location.key] = updateTime
    }

    
    //    subscript(key: String) -> NSDate {
    //        get {
    //            return lastUpdatedForKey(key)
    //        }
    //        set {
    //            setLastUpdated(newValue, forKey: key)
    //        }
    //    }
    //
    //    /// Clears all the last updated values from the store.
    //

    //
    //    func setLastUpdated(date: NSDate, forKey key: String) {
    //        lastUpdateds[key] = date
    //    }
    
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
}
