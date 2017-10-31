//
//  MailboxViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData

enum SwipeResponse {
    case showUndo
    case nothing
    case showGeneral
}

class MailboxViewModel {
    typealias CompletionBlock = APIService.CompletionBlock
    
    init() { }
    
    func getNavigationTitle() -> String {
        fatalError("This method must be overridden")
    }
    
    func getFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        fatalError("This method must be overridden")
    }
    
    func lastUpdateTime() -> UpdateTime {
        fatalError("This method must be overridden")
    }
    
    func getSwipeTitle(_ action: MessageSwipeAction) -> String {
        fatalError("This method must be overridden")
    }
    
    func deleteMessage(_ msg: Message) -> SwipeResponse {
        fatalError("This method must be overridden")
    }
    
    func archiveMessage(_ msg: Message) -> SwipeResponse {
        self.updateBadgeNumberWhenMove(msg, to: .archive)
        msg.removeLocationFromLabels(currentlocation: msg.location, location: .archive, keepSent: true)
        msg.needsUpdate = true
        msg.location = .archive
        if let context = msg.managedObjectContext {
            context.perform {
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(error)")
                }
            }
        }
        return .showUndo
    }
    
    func spamMessage(_ msg: Message) -> SwipeResponse {
        self.updateBadgeNumberWhenMove(msg, to: .spam)
        msg.removeLocationFromLabels(currentlocation: msg.location, location: .spam, keepSent: true)
        msg.needsUpdate = true
        msg.location = .spam
        if let context = msg.managedObjectContext {
            context.perform {
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(error)")
                }
            }
        }
        return .showUndo
    }
    
    func starMessage(_ msg: Message) -> SwipeResponse {
        self.updateBadgeNumberWhenMove(msg, to: .starred)
        msg.setLabelLocation(.starred)
        msg.isStarred = true
        msg.needsUpdate = true
        if let context = msg.managedObjectContext {
            context.perform {
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(error)")
                }
            }
        }
        return .nothing
    }
    
    func updateBadgeNumberWhenMove(_ message : Message, to : MessageLocation) {
        let fromLocation = message.location
        let toLocation = to
        
        if toLocation == .starred && message.isStarred {
            return
        }
        
        var fromCount = lastUpdatedStore.UnreadCountForKey(fromLocation)
        var toCount = lastUpdatedStore.UnreadCountForKey(toLocation)
        
        let offset = message.isRead ? 0 : 1
        
        if toLocation != .starred {
            fromCount = fromCount + (-1 * offset)
            if fromCount < 0 {
                fromCount = 0
            }
            lastUpdatedStore.updateUnreadCountForKey(fromLocation, count: fromCount)
        }
        
        if fromLocation != .starred {
            toCount = toCount + offset
            if toCount < 0 {
                toCount = 0
            }
            lastUpdatedStore.updateUnreadCountForKey(toLocation, count: toCount)
        }
        
        if fromLocation == .inbox {
            UIApplication.setBadge(badge: fromCount)
            //UIApplication.shared.applicationIconBadgeNumber = fromCount
        }
        if toLocation == .inbox {
            UIApplication.setBadge(badge: toCount)
            //UIApplication.shared.applicationIconBadgeNumber = toCount
        }
    }
    
    func updateBadgeNumberWhenRead(_ message : Message, changeToRead : Bool) {
        let location = message.location
        
        if message.isRead == changeToRead {
            return
        }
        var count = lastUpdatedStore.UnreadCountForKey(location)
        count = count + (changeToRead ? -1 : 1)
        if count < 0 {
            count = 0
        }
        lastUpdatedStore.updateUnreadCountForKey(location, count: count)
        
        if message.isStarred {
            var staredCount = lastUpdatedStore.UnreadCountForKey(.starred)
            staredCount = staredCount + (changeToRead ? -1 : 1)
            if staredCount < 0 {
                staredCount = 0
            }
            lastUpdatedStore.updateUnreadCountForKey(.starred, count: staredCount)
        }
        if location == .inbox {
            UIApplication.setBadge(badge: count)
            //UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func isDrafts() -> Bool {
        return false
    }
    
    func isArchive() -> Bool {
        return false
    }
    
    func isDelete () -> Bool {
        return false
    }
    
    func showLocation () -> Bool {
        return false
    }
    
    func ignoredLocationTitle() -> String {
        return ""
    }
    
    func isCurrentLocation(_ l : MessageLocation) -> Bool {
        return false
    }
    
    func isSwipeActionValid(_ action: MessageSwipeAction) -> Bool {
        return true
    }
    
    func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
        return false
    }
    
    func isShowEmptyFolder() -> Bool {
        return false
    }
    
    func emptyFolder() {
    }
    
    func fetchMessages(_ MessageID : String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        fatalError("This method must be overridden")
    }
    func fetchNewMessages(_ notificationMessageID:String?, Time: Int, completion: CompletionBlock?) {
        fatalError("This method must be overridden")
    }
    func fetchMessagesForLocationWithEventReset(_ MessageID : String, Time: Int, completion: CompletionBlock?) {
        //fatalError("This method must be overridden")
    }
    
    func getNotificationMessage() -> String? {
        fatalError("This method must be overridden")
    }
    
    func resetNotificationMessage() -> Void {
        fatalError("This method must be overridden")
    }
    
    func reloadTable() -> Bool {
        return false
    }
}
