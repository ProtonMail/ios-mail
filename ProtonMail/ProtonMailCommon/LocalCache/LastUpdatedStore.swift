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
import CoreData


//TODO::cache this only need to load after login/authed
let lastUpdatedStore = LastUpdatedStore()

final class LastUpdatedStore : SharedCacheBase, HasLocalStorage {

    fileprivate struct Key {
        
        static let unreadMessageCount  = "unreadMessageCount"  //total unread
        
        static let lastCantactsUpdated = "LastCantactsUpdated" //
        
        //added 1.8.0 new contacts
        static let isContactsCached    = "isContactsCached"  //
        
        //Removed at 1.5.5 still need for cleanup
        static let mailboxUnreadCount  = "MailboxUnreadCount"
        static let lastInboxesUpdated  = "LastInboxesUpdated"
        //Removed at 1.12.0
        static let labelsUnreadCount   = "LabelsUnreadCount"
        static let lastLabelsUpdated   = "LastLabelsUpdated"
        static let lastEventID         = "lastEventID"
        
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
        getShared().removeObject(forKey: Key.unreadMessageCount)
        getShared().removeObject(forKey: Key.labelsUnreadCount)
        getShared().removeObject(forKey: Key.isContactsCached)
        
        //removed
        getShared().removeObject(forKey: Key.mailboxUnreadCount)
        getShared().removeObject(forKey: Key.lastInboxesUpdated)
        getShared().removeObject(forKey: Key.lastEventID)
        
        //sync
        getShared().synchronize()
        
        UIApplication.setBadge(badge: 0)
    }
    
    func cleanUp() {
        // TODO: clean only one specific user
    }
    
    static func cleanUpAll() {
        let context = CoreDataService.shared.backgroundManagedObjectContext
        context.perform {
            UserEvent.deleteAll(inContext: context)
            LabelUpdate.deleteAll(inContext: context)
        }
    }
    
    // reset functions
    func resetUnreadCounts() {
        getShared().removeObject(forKey: Key.mailboxUnreadCount)
        getShared().removeObject(forKey: Key.labelsUnreadCount)
        getShared().removeObject(forKey: Key.lastCantactsUpdated)
        getShared().removeObject(forKey: Key.unreadMessageCount)
        
        getShared().synchronize()
    }
    
    //Mark - new 1.12.0
    
    func lastUpdate(by labelID : String, userID: String, context: NSManagedObjectContext? = nil) -> LabelUpdate? {
        //TODO:: fix me fetch everytime is expensive
        return LabelUpdate.lastUpdate(by: labelID, userID: userID, inManagedObjectContext: context ?? CoreDataService.shared.mainManagedObjectContext)
    }
    
    func lastUpdateDefault(by labelID : String, userID: String, context: NSManagedObjectContext? = nil) -> LabelUpdate {
        if let update = LabelUpdate.lastUpdate(by: labelID, userID: userID, inManagedObjectContext: context ?? CoreDataService.shared.mainManagedObjectContext) {
            return update
        }
        return LabelUpdate.newLabelUpdate(by: labelID, userID: userID, inManagedObjectContext: context ?? CoreDataService.shared.mainManagedObjectContext)
    }
    
    // location & label: message unread count
    func unreadCount(by labelID : String, userID: String, context: NSManagedObjectContext? = nil) -> Int {
        guard let update = lastUpdate(by: labelID, userID: userID, context: context ?? CoreDataService.shared.mainManagedObjectContext) else {
            return 0
        }
        return Int(update.unread)
    }

    // update unread count
    func updateUnreadCount(by labelID : String, userID: String, count: Int, context: NSManagedObjectContext? = nil) {
        let update = lastUpdateDefault(by: labelID, userID: userID, context: context ?? CoreDataService.shared.mainManagedObjectContext)
        update.unread = Int32(count)
        
        let _ = context?.saveUpstreamIfNeeded()
        
        if labelID == Message.Location.inbox.rawValue {
            UIApplication.setBadge(badge: count)
        }
    }
    
    //remove all updates for a user
    func removeUpdateTime(by userID: String, context: NSManagedObjectContext? = nil) {
        let _ = LabelUpdate.remove(by: userID, inManagedObjectContext: context ?? CoreDataService.shared.mainManagedObjectContext)
    }
    
    
    // update event id
    func updateEventID(by userID : String, eventID: String, context: NSManagedObjectContext? = nil) {
        let event = eventIDDefault(by: userID, context: context ?? CoreDataService.shared.mainManagedObjectContext)
        event.eventID = eventID;
        let _ = context?.saveUpstreamIfNeeded()
    }
    
    private func eventIDDefault(by userID : String, context: NSManagedObjectContext? = nil) -> UserEvent {
        if let update = UserEvent.userEvent(by: userID,
                                            inManagedObjectContext: context ?? CoreDataService.shared.mainManagedObjectContext) {
            return update
        }
        return UserEvent.newUserEvent(userID: userID,
                                      inManagedObjectContext: context ?? CoreDataService.shared.mainManagedObjectContext)
    }
    
    func lastEventID(userID: String) -> String {
        let event = eventIDDefault(by: userID, context: CoreDataService.shared.mainManagedObjectContext)
        return event.eventID
    }
}



