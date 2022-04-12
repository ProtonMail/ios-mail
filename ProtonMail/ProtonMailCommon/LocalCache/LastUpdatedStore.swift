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
import ProtonCore_DataModel
import UIKit

protocol LastUpdatedStoreProtocol {
    var contactsCached: Int { get set }
    
    static func clear()
    static func cleanUpAll() -> Promise<Void>
    
    func clear()
    func cleanUp(userId: String) -> Promise<Void>
    func resetUnreadCounts()
    
    func updateEventID(by userID : String, eventID: String) -> Promise<Void>
    func lastEventID(userID: String) -> String
    func lastEvent(userID: String, context: NSManagedObjectContext) -> UserEvent
    func lastEventUpdateTime(userID: String) -> Date?
    
    func lastUpdate(by labelID : String, userID: String, context: NSManagedObjectContext, type: ViewMode) -> LabelCount?
    func lastUpdateDefault(by labelID : String, userID: String, context: NSManagedObjectContext, type: ViewMode) -> LabelCount
    func unreadCount(by labelID : String, userID: String, type: ViewMode) -> Promise<Int>
    func unreadCount(by labelID : String, userID: String, type: ViewMode) -> Int
    func updateUnreadCount(by labelID : String, userID: String, unread: Int, total: Int?, type: ViewMode, shouldSave: Bool)
    func removeUpdateTime(by userID: String, type: ViewMode)
    func resetCounter(labelID: String, userID: String, type: ViewMode?)
    func removeUpdateTimeExceptUnread(by userID: String, type: ViewMode)
    func lastUpdates(by labelIDs: [String], userID: String, context: NSManagedObjectContext, type: ViewMode) -> [LabelCount]
    func getUnreadCounts(by labelID: [String], userID: String, type: ViewMode) -> Promise<[String: Int]>
}

final class LastUpdatedStore : SharedCacheBase, HasLocalStorage, LastUpdatedStoreProtocol, Service {
    typealias LabelType = ViewMode
    
    fileprivate struct Key {
        
        static let unreadMessageCount  = "unreadMessageCount"  //total unread
        
        static let lastCantactsUpdated = "LastCantactsUpdated"
        
        //added 1.8.0 new contacts
        static let isContactsCached    = "isContactsCached"
        
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
    
    let coreDataService: CoreDataService
    var context: NSManagedObjectContext {
        return coreDataService.rootSavingContext
    }
    
    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        super.init()
    }
    
    /**
     clear the last update time cache
     */
    func clear() {
        
        //in use
        getShared().removeObject(forKey: Key.isContactsCached)
        
        //removed
        getShared().removeObject(forKey: Key.lastLabelsUpdated)
        getShared().removeObject(forKey: Key.lastCantactsUpdated)
        getShared().removeObject(forKey: Key.unreadMessageCount)
        getShared().removeObject(forKey: Key.labelsUnreadCount)
        getShared().removeObject(forKey: Key.mailboxUnreadCount)
        getShared().removeObject(forKey: Key.lastInboxesUpdated)
        getShared().removeObject(forKey: Key.lastEventID)
        
        //sync
        getShared().synchronize()
    }
    
    static func clear() {
        if let userDefault = UserDefaults(suiteName: Constants.App.APP_GROUP) {
            //in use
            userDefault.removeObject(forKey: Key.isContactsCached)
            
            //removed
            userDefault.removeObject(forKey: Key.lastCantactsUpdated)
            userDefault.removeObject(forKey: Key.lastLabelsUpdated)
            userDefault.removeObject(forKey: Key.unreadMessageCount)
            userDefault.removeObject(forKey: Key.labelsUnreadCount)
            userDefault.removeObject(forKey: Key.mailboxUnreadCount)
            userDefault.removeObject(forKey: Key.lastInboxesUpdated)
            userDefault.removeObject(forKey: Key.lastEventID)
            
            //sync
            userDefault.synchronize()
            
            UIApplication.setBadge(badge: 0)
        }
    }
    
    func cleanUp() -> Promise<Void> {
        fatalError()
    }
    
    func cleanUp(userId: String) -> Promise<Void> {
        return Promise { seal in
            let context = self.coreDataService.operationContext
            coreDataService.enqueue(context: context) { (context) in
                _ = UserEvent.remove(by: userId, inManagedObjectContext: context)
                _ = LabelUpdate.remove(by: userId, inManagedObjectContext: context)
                _ = ConversationCount.remove(by: userId, inManagedObjectContext: context)
                seal.fulfill_()
            }
        }
    }
    
    static func cleanUpAll() -> Promise<Void> {
        return Promise { seal in
            let coreDataService = sharedServices.get(by: CoreDataService.self)
            let context = coreDataService.operationContext
            coreDataService.enqueue(context: context) { (context) in
                UserEvent.deleteAll(inContext: context)
                LabelUpdate.deleteAll(inContext: context)
                ConversationCount.deleteAll(inContext: context)
                seal.fulfill_()
            }
        }
    }
    
    func resetUnreadCounts() {
        getShared().removeObject(forKey: Key.mailboxUnreadCount)
        getShared().removeObject(forKey: Key.labelsUnreadCount)
        getShared().removeObject(forKey: Key.lastCantactsUpdated)
        getShared().removeObject(forKey: Key.unreadMessageCount)
        
        getShared().synchronize()
    }
}

//MARK: - Event ID
extension LastUpdatedStore {
    func updateEventID(by userID : String, eventID: String) -> Promise<Void> {
        return Promise { seal in
            self.coreDataService.enqueue(context: context) { (context) in
                let event = self.eventIDDefault(by: userID, context: context)
                event.eventID = eventID
                event.updateTime = Date()
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
    
    func lastEvent(userID: String, context: NSManagedObjectContext) -> UserEvent {
        return eventIDDefault(by: userID, context: context)
    }
    
    func lastEventID(userID: String) -> String {
        var eventID = ""
        context.performAndWait {
            eventID = eventIDDefault(by: userID, context: context).eventID
        }
        return eventID
    }
    
    func lastEventUpdateTime(userID: String) -> Date? {
        var time: Date?
        context.performAndWait {
            time = eventIDDefault(by: userID, context: context).updateTime
        }
        return time
    }
}

// MARK: - Conversation/Message Counts
extension LastUpdatedStore {

    func lastUpdates(by labelIDs: [String], userID: String, context: NSManagedObjectContext, type: ViewMode) -> [LabelCount] {
        switch type {
        case .singleMessage:
            return LabelUpdate.fetchLastUpdates(by: labelIDs, userID: userID, context: context)
        case .conversation:
            return ConversationCount.fetchConversationCounts(by: labelIDs, userID: userID, context: context)
        }
    }
    
    func lastUpdate(by labelID : String, userID: String, context: NSManagedObjectContext, type: ViewMode) -> LabelCount? {
        //TODO:: fix me fetch everytime is expensive
        switch type {
        case .singleMessage:
            return LabelUpdate.lastUpdate(by: labelID, userID: userID, inManagedObjectContext: context)
        case .conversation:
            return ConversationCount.lastContextUpdate(by: labelID, userID: userID, inManagedObjectContext: context)
        }
    }
    
    func lastUpdateDefault(by labelID : String, userID: String, context: NSManagedObjectContext, type: ViewMode) -> LabelCount {
        switch type {
        case .singleMessage:
            if let update = LabelUpdate.lastUpdate(by: labelID, userID: userID, inManagedObjectContext: context) {
                return update
            }
            return LabelUpdate.newLabelUpdate(by: labelID, userID: userID, inManagedObjectContext: context)
        case .conversation:
            if let update = ConversationCount.lastContextUpdate(by: labelID, userID: userID, inManagedObjectContext: context) {
                return update
            }
            return ConversationCount.newConversationCount(by: labelID, userID: userID, inManagedObjectContext: context)
        }
        
    }
    
    func unreadCount(by labelID : String, userID: String, type: ViewMode) -> Promise<Int> {
        return Promise { seal in
            var unreadCount: Int32?
            context.perform {
                let update = self.lastUpdate(by: labelID, userID: userID, context: self.context, type: type)
                unreadCount = update?.unread

                guard let result = unreadCount else {
                    seal.fulfill(0)
                    return
                }
                seal.fulfill(Int(result))
            }
        }
    }

    func getUnreadCounts(by labelID: [String], userID: String, type: ViewMode) -> Promise<[String: Int]> {
        return Promise { seal in
            context.perform {
                var results: [String: Int] = [:]
                let labelCounts = self.lastUpdates(by: labelID, userID: userID, context: self.context, type: type)
                labelCounts.forEach({ results[$0.labelID] = Int($0.unread) })
                seal.fulfill(results)
            }
        }
    }
    
    func unreadCount(by labelID : String, userID: String, type: ViewMode) -> Int {
        var unreadCount: Int32?

        context.performAndWait {
            let update = self.lastUpdate(by: labelID, userID: userID, context: context, type: type)
            unreadCount = update?.unread
        }
        
        guard let result = unreadCount else {
            return 0
        }
        return Int(result)
    }
    
    func updateUnreadCount(by labelID : String, userID: String, unread: Int, total: Int?, type: ViewMode, shouldSave: Bool) {
        context.performAndWait {
            let update = self.lastUpdateDefault(by: labelID, userID: userID, context: context, type: type)
            update.unread = Int32(unread)
            if let total = total {
                update.total = Int32(total)
            }

            if shouldSave {
                let _ = context.saveUpstreamIfNeeded()
            }
        }
        let users: UsersManager = sharedServices.get(by: UsersManager.self)
        let isPrimary = users.firstUser?.userInfo.userId == userID
        guard labelID == Message.Location.inbox.rawValue,
              isPrimary,
              let viewMode = users.firstUser?.getCurrentViewMode(),
              type == viewMode else { return }
        UIApplication.setBadge(badge: unread)
    }

    
    /// Reset counter value to zero
    /// - Parameters:
    ///   - type: Optional, nil will reset conversation and message counter
    func resetCounter(labelID: String, userID: String, type: ViewMode?) {
        context.performAndWait { [weak self] in
            guard let self = self else { return }
            let counts: [LabelCount]
            if let type = type {
                let count = self.lastUpdateDefault(by: labelID, userID: userID, context: context, type: type)
                counts = [count]
            } else {
                let conversationCount = self.lastUpdateDefault(by: labelID, userID: userID, context: context, type: .conversation)
                let messageCount = self.lastUpdateDefault(by: labelID, userID: userID, context: context, type: .singleMessage)
                counts = [conversationCount, messageCount]
            }
            counts.forEach { count in
                count.total = 0
                count.unread = 0
                count.unreadStart = nil
                count.unreadEnd = nil
                count.unreadUpdate = nil
            }
            let _ = context.saveUpstreamIfNeeded()
        }
    }
    
    //remove all updates for a user
    func removeUpdateTime(by userID: String, type: ViewMode) {
        self.coreDataService.enqueue(context: context) { (context) in
            switch type {
            case .singleMessage:
                let _ = LabelUpdate.remove(by: userID, inManagedObjectContext: context)
            case .conversation:
                let _ = ConversationCount.remove(by: userID, inManagedObjectContext: context)
            }
        }
    }

    func removeUpdateTimeExceptUnread(by userID: String, type: ViewMode) {
        self.coreDataService.enqueue(context: context) { context in
            switch type {
            case .singleMessage:
                let data = LabelUpdate.lastUpdates(userID: userID, inManagedObjectContext: context)
                data.forEach({ $0.resetDataExceptUnread() })
            case .conversation:
                let data = ConversationCount.getConversationCounts(userID: userID, inManagedObjectContext: context)
                data.forEach({ $0.resetDataExceptUnread() })
            }
            _ = context.saveUpstreamIfNeeded()
        }
    }
}

