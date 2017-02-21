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
        static let labelsUnreadCount = "LabelsUnreadCount"  //for inbox & labels
        static let lastLabelsUpdated = "LastLabelsUpdated" //for inbox & labels
        
        static let unreadMessageCount = "unreadMessageCount"  //total unread
        
        static let lastEventID = "lastEventID"  //
        //
        static let lastCantactsUpdated = "LastCantactsUpdated" //
        
        //Removed at 1.5.5 still need for cleanup
        static let mailboxUnreadCount = "MailboxUnreadCount"
        static let lastInboxesUpdated = "LastInboxesUpdated"
    }
    
    
    public class UpdateTime : NSObject, NSCoding {
        
        public var start : NSDate
        public var end : NSDate
        public var update : NSDate
        public var total : Int32
        public var unread : Int32
        
        private struct CoderKey {
            static let startCode = "start"
            static let endCode = "end"
            static let updateCode = "update"
            static let unread = "unread"
            static let total = "total"
        }
        
        required public init (start: NSDate!, end : NSDate, update : NSDate, total : Int32, unread: Int32){
            self.start = start
            self.end = end
            self.update = update
            self.unread = unread
            self.total = total
        }
        
        public var isNew : Bool {
            get{
                return  self.start == self.end && self.start == self.update
            }
        }
        
        public convenience required init(coder aDecoder: NSCoder) {
            self.init(
                start: aDecoder.decodeObjectForKey(CoderKey.startCode) as! NSDate,
                end: aDecoder.decodeObjectForKey(CoderKey.endCode) as! NSDate,
                update: aDecoder.decodeObjectForKey(CoderKey.updateCode) as! NSDate,
                total: aDecoder.decodeInt32ForKey(CoderKey.total),
                unread: aDecoder.decodeInt32ForKey(CoderKey.unread))
        }
        
        public func encodeWithCoder(aCoder: NSCoder) {
            aCoder.encodeObject(self.start, forKey: CoderKey.startCode)
            aCoder.encodeObject(self.end, forKey: CoderKey.endCode)
            aCoder.encodeObject(self.update, forKey: CoderKey.updateCode)
            aCoder.encodeInt32(self.total, forKey: CoderKey.total)
            aCoder.encodeInt32(self.unread, forKey: CoderKey.unread)
        }
        
        static public func distantPast() -> UpdateTime {
            return UpdateTime(start: NSDate.distantPast() , end: NSDate.distantPast() , update: NSDate.distantPast() , total: 0, unread: 0)
        }
    }

    
//    private var lastInboxesUpdateds: Dictionary<String, UpdateTime> {
//        get {
//            return (getShared().customObjectForKey(Key.lastInboxesUpdated) as? Dictionary<String, UpdateTime>) ?? [:]
//        }
//        set {
//            getShared().setCustomValue(newValue, forKey: Key.lastInboxesUpdated)
//            getShared().synchronize()
//        }
//    }
    
    private var lastLabelsUpdateds: Dictionary<String, UpdateTime> {
        get {
            return (getShared().customObjectForKey(Key.lastLabelsUpdated) as? Dictionary<String, UpdateTime>) ?? [:]
        }
        set {
            getShared().setCustomValue(newValue, forKey: Key.lastLabelsUpdated)
            getShared().synchronize()
        }
    }
    
    private var labelsUnreadCounts: Dictionary<String, Int> {
        get {
            return (getShared().customObjectForKey(Key.labelsUnreadCount) as? Dictionary<String, Int>) ?? [:]
        }
        set {
            getShared().setCustomValue(newValue, forKey: Key.labelsUnreadCount)
            getShared().synchronize()
        }
    }
    
    public var lastEventID: String! {
        get {
            return getShared().stringForKey(Key.lastEventID) ?? "0"
        }
        set {
            getShared().setValue(newValue, forKey: Key.lastEventID)
            getShared().synchronize()
        }
    }
    
    public var totalUnread: Int! {
        get {
            return getShared().integerForKey(Key.unreadMessageCount) ?? 0
        }
        set {
            getShared().setValue(newValue, forKey: Key.unreadMessageCount)
            getShared().synchronize()
        }
    }

    
    /**
    clear the last update time cache
    */
    public func clear() {
        //in use
        getShared().removeObjectForKey(Key.lastCantactsUpdated)
        getShared().removeObjectForKey(Key.lastLabelsUpdated)
        getShared().removeObjectForKey(Key.lastEventID)
        getShared().removeObjectForKey(Key.unreadMessageCount)
        getShared().removeObjectForKey(Key.labelsUnreadCount)
        
        //removed
        getShared().removeObjectForKey(Key.mailboxUnreadCount)
        getShared().removeObjectForKey(Key.lastInboxesUpdated)
        
        //sync
        getShared().synchronize()
    }
    
    
    /**
    get the inbox last update time by location
    
    :param: location MessageLocation
    
    :returns: the Update Time
    */
    public func inboxLastForKey(location : MessageLocation) -> UpdateTime {
        let str_location = String(location.rawValue)
        return lastLabelsUpdateds[str_location] ?? UpdateTime.distantPast()
    }
    
    /**
    update the exsit inbox last update time by location
    
    :param: location   message location
    :param: updateTime the new update time
    */
    public func updateInboxForKey(location : MessageLocation, updateTime: UpdateTime) -> Void {
        let str_location = String(location.rawValue)
        return lastLabelsUpdateds[str_location] = updateTime
    }
    
    public func labelsLastForKey(labelID : String) -> UpdateTime {
        return lastLabelsUpdateds[labelID] ?? UpdateTime.distantPast()
    }
    
    public func updateLabelsForKey(labelID : String, updateTime: UpdateTime) -> Void {
        return lastLabelsUpdateds[labelID] = updateTime
    }
    
    
    // location & label: message unread count
    public func UnreadCountForKey(labelID : String) -> Int {
        return labelsUnreadCounts[labelID] ?? 0
    }
    public func UnreadCountForKey(location : MessageLocation) -> Int {
        let str_location = String(location.rawValue)
        return labelsUnreadCounts[str_location] ?? 0
    }
    
    public func updateLabelsUnreadCountForKey(labelID : String, count: Int) -> Void {
        return labelsUnreadCounts[labelID] = count
    }
    
    public func updateUnreadCountForKey(location : MessageLocation, count: Int) -> Void {
        let str_location = String(location.rawValue)
        return labelsUnreadCounts[str_location] = count
    }
    
    
    // Mailbox unread count change
    public func UnreadMailboxMessage(location : MessageLocation) {
        let str_location = String(location.rawValue)
        var currentCount = labelsUnreadCounts[str_location] ?? 0
        currentCount += 1;
        labelsUnreadCounts[str_location] = currentCount
    }
    
    public func ReadMailboxMessage(location : MessageLocation) {
        let str_location = String(location.rawValue)
        var currentCount = labelsUnreadCounts[str_location] ?? 0
        currentCount -= 1;
        if currentCount < 0 {
            currentCount = 0
        }
        labelsUnreadCounts[str_location] = currentCount
    }
    
    public func MoveUnReadMailboxMessage(from : MessageLocation, to : MessageLocation) {
        UnreadMailboxMessage(from);
        ReadMailboxMessage(to)
    }
    
    
    // reset functions    
    public func resetUnreadCounts() {
        getShared().removeObjectForKey(Key.mailboxUnreadCount)
        getShared().removeObjectForKey(Key.labelsUnreadCount)
        getShared().removeObjectForKey(Key.lastCantactsUpdated)
        getShared().synchronize()
    }
}



