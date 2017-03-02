//
//  MailboxViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData


public class MailboxViewModel {
    typealias CompletionBlock = APIService.CompletionBlock
    
    public init() { }
    
    public func getNavigationTitle() -> String {
        fatalError("This method must be overridden")
    }
    
    public func getFetchedResultsController() -> NSFetchedResultsController? {
        fatalError("This method must be overridden")
    }
    
    public func lastUpdateTime() -> LastUpdatedStore.UpdateTime {
        fatalError("This method must be overridden")
    }
    
    public func getSwipeTitle(action: MessageSwipeAction) -> String {
        fatalError("This method must be overridden")
    }
    
    public func deleteMessage(msg: Message) -> Bool {
        fatalError("This method must be overridden")
    }
    
    public func archiveMessage(msg: Message) {
        self.updateBadgeNumberWhenMove(msg, to: .archive)
        msg.removeLocationFromLabels(msg.location, location: .archive)
        msg.needsUpdate = true
        msg.location = .archive
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            PMLog.D("error: \(error)")
        }
    }
    
    public func spamMessage(msg: Message) {
        self.updateBadgeNumberWhenMove(msg, to: .spam)
        msg.removeLocationFromLabels(msg.location, location: .spam)
        msg.needsUpdate = true
        msg.location = .spam
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            PMLog.D("error: \(error)")
        }
    }
    
    public func starMessage(msg: Message) {
        self.updateBadgeNumberWhenMove(msg, to: .starred)
        msg.setLabelLocation(.starred)
        msg.isStarred = true
        msg.needsUpdate = true
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            PMLog.D("error: \(error)")
        }
    }
    
    func updateBadgeNumberWhenMove(message : Message, to : MessageLocation) {
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
            UIApplication.sharedApplication().applicationIconBadgeNumber = fromCount
        }
        if toLocation == .inbox {
            UIApplication.sharedApplication().applicationIconBadgeNumber = toCount
        }
    }
    
    func updateBadgeNumberWhenRead(message : Message, changeToRead : Bool) {
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
            UIApplication.sharedApplication().applicationIconBadgeNumber = count
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
    
    public func isCurrentLocation(l : MessageLocation) -> Bool {
        return false
    }
    
    public func isSwipeActionValid(action: MessageSwipeAction) -> Bool {
        return true
    }
    
    public func stayAfterAction (action: MessageSwipeAction) -> Bool {
        return false
    }
    
    public func isShowEmptyFolder() -> Bool {
        return false
    }
    
    public func emptyFolder() {
    }
    
    func fetchMessages(MessageID : String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        fatalError("This method must be overridden")
    }
    func fetchNewMessages(notificationMessageID:String?, Time: Int, completion: CompletionBlock?) {
        fatalError("This method must be overridden")
    }
    func fetchMessagesForLocationWithEventReset(MessageID : String, Time: Int, completion: CompletionBlock?) {
        //fatalError("This method must be overridden")
    }
    
    func getNotificationMessage() -> String? {
        fatalError("This method must be overridden")
    }
    
    func resetNotificationMessage() -> Void {
        fatalError("This method must be overridden")
    }
}
