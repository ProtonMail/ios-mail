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

public class MailboxViewModel {
    public typealias CompletionBlock = APIService.CompletionBlock
    
    public init() { }
    
    public func getNavigationTitle() -> String {
        fatalError("This method must be overridden")
    }
    
    public func getFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        fatalError("This method must be overridden")
    }
    
    public func lastUpdateTime() -> UpdateTime {
        fatalError("This method must be overridden")
    }
    
    public func getSwipeTitle(_ action: MessageSwipeAction) -> String {
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
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            PMLog.D("error: \(error)")
        }
        
        return .showUndo
    }
    
    func spamMessage(_ msg: Message) -> SwipeResponse {
        self.updateBadgeNumberWhenMove(msg, to: .spam)
        msg.removeLocationFromLabels(currentlocation: msg.location, location: .spam, keepSent: true)
        msg.needsUpdate = true
        msg.location = .spam
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            PMLog.D("error: \(error)")
        }
        return .showUndo
    }
    
    func starMessage(_ msg: Message) -> SwipeResponse {
        self.updateBadgeNumberWhenMove(msg, to: .starred)
        msg.setLabelLocation(.starred)
        msg.isStarred = true
        msg.needsUpdate = true
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            PMLog.D("error: \(error)")
        }
        return .nothing
    }
    
    public func updateBadgeNumberWhenMove(_ message : Message, to : MessageLocation) {
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
            UIApplication.shared.applicationIconBadgeNumber = fromCount
        }
        if toLocation == .inbox {
            UIApplication.shared.applicationIconBadgeNumber = toCount
        }
    }
    
    public func updateBadgeNumberWhenRead(_ message : Message, changeToRead : Bool) {
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
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    public func isDrafts() -> Bool {
        return false
    }
    
    public func isArchive() -> Bool {
        return false
    }
    
    public func isDelete () -> Bool {
        return false
    }
    
    public func showLocation () -> Bool {
        return false
    }
    
    public func ignoredLocationTitle() -> String {
        return ""
    }
    
    public func isCurrentLocation(_ l : MessageLocation) -> Bool {
        return false
    }
    
    public func isSwipeActionValid(_ action: MessageSwipeAction) -> Bool {
        return true
    }
    
    public func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
        return false
    }
    
    public func isShowEmptyFolder() -> Bool {
        return false
    }
    
    public func emptyFolder() {
    }
    
    public func fetchMessages(_ MessageID : String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        fatalError("This method must be overridden")
    }
    public func fetchNewMessages(_ notificationMessageID:String?, Time: Int, completion: CompletionBlock?) {
        fatalError("This method must be overridden")
    }
    public func fetchMessagesForLocationWithEventReset(_ MessageID : String, Time: Int, completion: CompletionBlock?) {
        //fatalError("This method must be overridden")
    }
    
    public func getNotificationMessage() -> String? {
        fatalError("This method must be overridden")
    }
    
    public func resetNotificationMessage() -> Void {
        fatalError("This method must be overridden")
    }
}
