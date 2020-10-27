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
import PromiseKit


//TODO::cache this only need to load after login/authed
let lastUpdatedStore = LastUpdatedStore(coreDataService: sharedServices.get(by: CoreDataService.self))

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
    
    let coreDataService: CoreDataService
    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        super.init()
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
    
    static func clear() {
        if let userDefault = UserDefaults(suiteName: Constants.App.APP_GROUP) {
            //in use
            userDefault.removeObject(forKey: Key.lastCantactsUpdated)
            userDefault.removeObject(forKey: Key.lastLabelsUpdated)
            userDefault.removeObject(forKey: Key.unreadMessageCount)
            userDefault.removeObject(forKey: Key.labelsUnreadCount)
            userDefault.removeObject(forKey: Key.isContactsCached)
            
            //removed
            userDefault.removeObject(forKey: Key.mailboxUnreadCount)
            userDefault.removeObject(forKey: Key.lastInboxesUpdated)
            userDefault.removeObject(forKey: Key.lastEventID)
            
            //sync
            userDefault.synchronize()
            
            UIApplication.setBadge(badge: 0)
        }
    }
    
    func cleanUp() -> Promise<Void> {
        // TODO: clean only one specific user
        return Promise()
    }
    
    func cleanUp(userId: String) -> Promise<Void> {
        return Promise { seal in
            let context = self.coreDataService.backgroundManagedObjectContext
            coreDataService.enqueue(context: context) { (context) in
                _ = UserEvent.remove(by: userId, inManagedObjectContext: context)
                _ = LabelUpdate.remove(by: userId, inManagedObjectContext: context)
                seal.fulfill_()
            }
        }
    }
    
    static func cleanUpAll() -> Promise<Void> {
        return Promise { seal in
            let coreDataService = sharedServices.get(by: CoreDataService.self)
            let context = coreDataService.backgroundManagedObjectContext
            coreDataService.enqueue(context: context) { (context) in
                UserEvent.deleteAll(inContext: context)
                LabelUpdate.deleteAll(inContext: context)
                seal.fulfill_()
            }
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
    
    func lastUpdate(by labelID : String, userID: String, context: NSManagedObjectContext) -> LabelUpdate? {
        //TODO:: fix me fetch everytime is expensive
        return LabelUpdate.lastUpdate(by: labelID, userID: userID, inManagedObjectContext: context)
    }
    
    func lastUpdateDefault(by labelID : String, userID: String, context: NSManagedObjectContext) -> LabelUpdate {
        if let update = LabelUpdate.lastUpdate(by: labelID, userID: userID, inManagedObjectContext: context) {
            return update
        }
        return LabelUpdate.newLabelUpdate(by: labelID, userID: userID, inManagedObjectContext: context)
    }
    
    // location & label: message unread count
    func unreadCount(by labelID : String, userID: String, context: NSManagedObjectContext) -> Promise<Int> {
        return Promise { seal in
            var unreadCount: Int32?
            self.coreDataService.enqueue(context: context) { (context) in
                let update = self.lastUpdate(by: labelID, userID: userID, context: context)
                unreadCount = update?.unread
                
                guard let result = unreadCount else {
                    seal.fulfill(0)
                    return
                }
                seal.fulfill(Int(result))
            }
        }
    }
    
    func unreadCount(by labelID : String, userID: String, context: NSManagedObjectContext) -> Int {
        var unreadCount: Int32?
        let update = self.lastUpdate(by: labelID, userID: userID, context: context)
        unreadCount = update?.unread
        
        guard let result = unreadCount else {
            return 0
        }
        return Int(result)
    }
    
    
    // update unread count
    func updateUnreadCount(by labelID : String, userID: String, count: Int, context: NSManagedObjectContext, shouldSave: Bool = true) {
        let update = self.lastUpdateDefault(by: labelID, userID: userID, context: context)
        update.unread = Int32(count)
        
        if shouldSave {
            let _ = context.saveUpstreamIfNeeded()
        }
        
        if labelID == Message.Location.inbox.rawValue {
            DispatchQueue.main.async {
                UIApplication.setBadge(badge: count)
            }
        }
    }
    
    //remove all updates for a user
    func removeUpdateTime(by userID: String, context: NSManagedObjectContext) {
        self.coreDataService.enqueue(context: context) { (context) in
            let _ = LabelUpdate.remove(by: userID, inManagedObjectContext: context)
        }
    }
    
    
    // update event id
    func updateEventID(by userID : String, eventID: String, context: NSManagedObjectContext) -> Promise<Void> {
        return Promise { seal in
            self.coreDataService.enqueue(context: context) { (context) in
                let event = self.eventIDDefault(by: userID, context: context)
                event.eventID = eventID
                let _ = context.saveUpstreamIfNeeded()
                seal.fulfill_()
            }
        }
    }
    
    private func eventIDDefault(by userID : String, context: NSManagedObjectContext) -> UserEvent {
        if let update = UserEvent.userEvent(by: userID,
                                            inManagedObjectContext: context) {
            return update
        }
        return UserEvent.newUserEvent(userID: userID,
                                      inManagedObjectContext: context)
    }
    
    func lastEventID(userID: String, context: NSManagedObjectContext) -> String {
        let event = eventIDDefault(by: userID, context: context)
        return event.eventID
    }
}



