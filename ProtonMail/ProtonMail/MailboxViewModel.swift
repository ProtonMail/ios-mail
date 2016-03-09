//
//  MailboxViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


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
    
    public func deleteMessage(msg: Message) {
        fatalError("This method must be overridden")
    }
    
    public func archiveMessage(msg: Message) {
        msg.location = .archive
        msg.needsUpdate = true
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
    }
    
    public func spamMessage(msg: Message) {
        msg.location = .spam
        msg.needsUpdate = true
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
    }
    
    public func starMessage(msg: Message) {
        msg.isStarred = true
        msg.needsUpdate = true
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
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
}
