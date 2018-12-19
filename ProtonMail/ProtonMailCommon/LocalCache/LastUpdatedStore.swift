//
//  LastUpdatedStore.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
            UIApplication.setBadge(badge: self.UnreadCountForKey(Message.Location.inbox.rawValue))
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
    
    func labelsLastForKey(_ labelID : String) -> UpdateTime {
        return lastLabelsUpdateds[labelID] ?? UpdateTime.distantPast()
    }
    
    func updateLabelsForKey(_ labelID : String, updateTime: UpdateTime) {
        lastLabelsUpdateds[labelID] = updateTime
    }
    
    // location & label: message unread count
    func UnreadCountForKey(_ labelID : String) -> Int {
        return labelsUnreadCounts[labelID] ?? 0
    }

    func updateLabelsUnreadCountForKey(_ labelID : String, count: Int) -> Void {
        return labelsUnreadCounts[labelID] = count
    }
    
    // Mailbox unread count change
    func UnreadMailboxMessage(_ location : String) {
        var currentCount = labelsUnreadCounts[location] ?? 0
        currentCount += 1;
        labelsUnreadCounts[location] = currentCount
    }
    
    func ReadMailboxMessage(_ location : String) {
        var currentCount = labelsUnreadCounts[location] ?? 0
        currentCount -= 1;
        if currentCount < 0 {
            currentCount = 0
        }
        labelsUnreadCounts[location] = currentCount
    }
    
    func MoveUnReadMailboxMessage(_ from : String, to : String) {
        //TODO:: doesn't right. need to change
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



