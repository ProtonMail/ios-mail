//
//  LastUpdatedStore.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation


//TODO::cache this only need to load after login/authed
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
    
    private var lastLabelsUpdateds: [String : UpdateTime] {
        get {
            return (getShared().customObjectForKey(Key.lastLabelsUpdated) as? [String : UpdateTime]) ?? [:]
        }
        set {
            getShared().setCustomValue(newValue as NSCoding?, forKey: Key.lastLabelsUpdated)
            getShared().synchronize()
        }
    }
    
    private var labelsUnreadCounts: [String : Int] {
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
        
        UIApplication.setBadge(badge: 0)
    }
    
    // reset functions
    func resetUnreadCounts() {
        getShared().removeObject(forKey: Key.mailboxUnreadCount)
        getShared().removeObject(forKey: Key.labelsUnreadCount)
        getShared().removeObject(forKey: Key.lastCantactsUpdated)
        getShared().removeObject(forKey: Key.unreadMessageCount)
        
        getShared().synchronize()
    }
    
    
    // location & label: message unread count
    func unreadCountForKey(_ labelID : String) -> Int {
        return labelsUnreadCounts[labelID] ?? 0
    }
    // update unread count
    func updateUnreadCountForKey(_ labelID : String, count: Int) {
        labelsUnreadCounts[labelID] = count
        
        if labelID == Message.Location.inbox.rawValue {
            UIApplication.setBadge(badge: count)
        }
    }
    
    /// cache time mark part
    func labelsLastForKey(_ labelID : String) -> UpdateTime {
        return lastLabelsUpdateds[labelID] ?? UpdateTime.distantPast()
    }
    
    func updateLabelsForKey(_ labelID : String, updateTime: UpdateTime) {
        lastLabelsUpdateds[labelID] = updateTime
    }

    
//    // Mailbox unread count change
//    func UnreadMailboxMessage(_ location : String) {
//        var currentCount = labelsUnreadCounts[location] ?? 0
//        currentCount += 1;
//        labelsUnreadCounts[location] = currentCount
//    }
//
//    func ReadMailboxMessage(_ location : String) {
//        var currentCount = labelsUnreadCounts[location] ?? 0
//        currentCount -= 1;
//        if currentCount < 0 {
//            currentCount = 0
//        }
//        labelsUnreadCounts[location] = currentCount
//    }
//
//    func MoveUnReadMailboxMessage(_ from : String, to : String) {
//        //TODO:: doesn't right. need to change
//        UnreadMailboxMessage(from);
//        ReadMailboxMessage(to)
//    }
//
    

}



