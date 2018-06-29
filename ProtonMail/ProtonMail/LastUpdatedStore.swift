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

let lastUpdatedStore = LastUpdatedStore()

final class LastUpdatedStore : SharedCacheBase {
    
    fileprivate struct Key {
        static let labelsUnreadCount   = "LabelsUnreadCount"  //for inbox & labels
        static let lastLabelsUpdated   = "LastLabelsUpdated" //for inbox & labels
        
        static let unreadMessageCount  = "unreadMessageCount"  //total unread
        
        static let lastEventID         = "lastEventID"  //
        static let lastCantactsUpdated = "LastCantactsUpdated" //
        
        //added 1.8.0 new contacts
        static let isContactsCached    = "isContactsCached"  //
        
        //Removed at 1.5.5 still need for cleanup
        static let mailboxUnreadCount  = "MailboxUnreadCount"
        static let lastInboxesUpdated  = "LastInboxesUpdated"
    }
    
    var lastLabelsUpdateds: [String : UpdateTime] {
        get {
            return (getShared().customObjectForKey(Key.lastLabelsUpdated) as? [String : UpdateTime]) ?? [:]
        }
        set {
            getShared().setCustomValue(newValue as NSCoding?, forKey: Key.lastLabelsUpdated)
            getShared().synchronize()
        }
    }
    
    var labelsUnreadCounts: [String : Int] {
        get {
            return (getShared().customObjectForKey(Key.labelsUnreadCount) as? [String : Int]) ?? [:]
        }
        set {
            getShared().setCustomValue(newValue as NSCoding?, forKey: Key.labelsUnreadCount)
            getShared().synchronize()
        }
    }
    
    var lastEventID: String! {
        get {
            let eid =  getShared().string(forKey: Key.lastEventID) ?? "0"
            return eid
        }
        set {
            getShared().setValue(newValue, forKey: Key.lastEventID)
            getShared().synchronize()
        }
    }
    
    var contactsCached: Int {
        get {
            return getShared().integer(forKey: Key.isContactsCached)
        }
        set {
            getShared().setValue(newValue, forKey: Key.isContactsCached)
            getShared().synchronize()
        }
    }
    
    var totalUnread: Int! {
        get {
            return getShared().integer(forKey: Key.unreadMessageCount) 
        }
        set {
            getShared().setValue(newValue, forKey: Key.unreadMessageCount)
            getShared().synchronize()
        }
    }

    
    /**
    clear the last update time cache
    */
    func clear() {
        //in use
        getShared().removeObject(forKey: Key.lastCantactsUpdated)
        getShared().removeObject(forKey: Key.lastLabelsUpdated)
        getShared().removeObject(forKey: Key.lastEventID)
        getShared().removeObject(forKey: Key.unreadMessageCount)
        getShared().removeObject(forKey: Key.labelsUnreadCount)
        getShared().removeObject(forKey: Key.isContactsCached)
        
        //removed
        getShared().removeObject(forKey: Key.mailboxUnreadCount)
        getShared().removeObject(forKey: Key.lastInboxesUpdated)
        
        //sync
        getShared().synchronize()
    }
    
    
    /**
    get the inbox last update time by location
    
    :param: location MessageLocation
    
    :returns: the Update Time
    */
    func inboxLastForKey(_ location : MessageLocation) -> UpdateTime {
        let str_location = String(location.rawValue)
        return lastLabelsUpdateds[str_location] ?? UpdateTime.distantPast()
    }
    
    /**
    update the exsit inbox last update time by location
    
    :param: location   message location
    :param: updateTime the new update time
    */
    func updateInboxForKey(_ location : MessageLocation, updateTime: UpdateTime) -> Void {
        let str_location = String(location.rawValue)
        return lastLabelsUpdateds[str_location] = updateTime
    }
    
    func labelsLastForKey(_ labelID : String) -> UpdateTime {
        return lastLabelsUpdateds[labelID] ?? UpdateTime.distantPast()
    }
    
    func updateLabelsForKey(_ labelID : String, updateTime: UpdateTime) -> Void {
        return lastLabelsUpdateds[labelID] = updateTime
    }
    
    
    // location & label: message unread count
    func UnreadCountForKey(_ labelID : String) -> Int {
        return labelsUnreadCounts[labelID] ?? 0
    }
    
    func UnreadCountForKey(_ location : MessageLocation) -> Int {
        let str_location = String(location.rawValue)
        return labelsUnreadCounts[str_location] ?? 0
    }
    
    func updateLabelsUnreadCountForKey(_ labelID : String, count: Int) -> Void {
        return labelsUnreadCounts[labelID] = count
    }
    
    func updateUnreadCountForKey(_ location : MessageLocation, count: Int) -> Void {
        let str_location = String(location.rawValue)
        return labelsUnreadCounts[str_location] = count
    }
    
    // Mailbox unread count change
    func UnreadMailboxMessage(_ location : MessageLocation) {
        let str_location = String(location.rawValue)
        var currentCount = labelsUnreadCounts[str_location] ?? 0
        currentCount += 1;
        labelsUnreadCounts[str_location] = currentCount
    }
    
    func ReadMailboxMessage(_ location : MessageLocation) {
        let str_location = String(location.rawValue)
        var currentCount = labelsUnreadCounts[str_location] ?? 0
        currentCount -= 1;
        if currentCount < 0 {
            currentCount = 0
        }
        labelsUnreadCounts[str_location] = currentCount
    }
    
    func MoveUnReadMailboxMessage(_ from : MessageLocation, to : MessageLocation) {
        UnreadMailboxMessage(from);
        ReadMailboxMessage(to)
    }
    
    
    // reset functions    
    func resetUnreadCounts() {
        getShared().removeObject(forKey: Key.mailboxUnreadCount)
        getShared().removeObject(forKey: Key.labelsUnreadCount)
        getShared().removeObject(forKey: Key.lastCantactsUpdated)
        getShared().removeObject(forKey: Key.unreadMessageCount)
        
        getShared().synchronize()
    }
}



