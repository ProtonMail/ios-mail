//
//  MailboxViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


public class MailboxViewModelImpl : MailboxViewModel {
    
    private let location : MessageLocation!
    
    init(location : MessageLocation) {
        
        self.location = location
        
        super.init()
    }
    
    override public func getNavigationTitle() -> String {
        return self.location.title
    }
    
    public override func getFetchedResultsController() -> NSFetchedResultsController? {
        let fetchedResultsController = sharedMessageDataService.fetchedResultsControllerForLocation(self.location)
        if let fetchedResultsController = fetchedResultsController {
            var error: NSError?
            if !fetchedResultsController.performFetch(&error) {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }
        return fetchedResultsController
    }
    
    public override func lastUpdateTime() -> LastUpdatedStore.UpdateTime {
        return lastUpdatedStore.inboxLastForKey(self.location)
    }
    
    public override func getSwipeTitle(action: MessageSwipeAction) -> String {
        switch(self.location!) {
        case .trash, .spam:
            if action == .trash {
                return "Delete"
            }
            return action.description;
        default:
            return action.description;
        }
    }
    
    public override func isSwipeActionValid(action: MessageSwipeAction) -> Bool {
        switch(self.location!) {
        case .archive:
            return action != .archive
        case .starred:
            return action != .star
        case .spam:
            return action != .spam
        case .starred:
            return action != .star
        default:
            return true
        }
    }
    
    public override func stayAfterAction (action: MessageSwipeAction) -> Bool {
        switch(self.location!) {
        case .starred:
            return true
        default:
            return false
        }
    }
    
    public override func deleteMessage(msg: Message) {
        switch(self.location!) {
        case .trash, .spam:
            msg.location = .deleted
        default:
            msg.location = .trash
        }
        msg.needsUpdate = true
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
    }
    
    public override func isDrafts() -> Bool {
        return self.location == MessageLocation.draft
    }
    
    public override func isArchive() -> Bool {
        return self.location == MessageLocation.archive
    }
    
    public override func isDelete () -> Bool {
        switch(self.location!) {
        case .trash, .spam:
            return true;
        default:
            return false
        }
    }
    
    public override func isCurrentLocation(l: MessageLocation) -> Bool {
        return self.location == l
    }
    
    public override func isShowEmptyFolder() -> Bool {
        switch(self.location!) {
        case .trash, .spam:
            return true;
        default:
            return false
        }
    }
    
    override public func emptyFolder() {
        switch(self.location!) {
        case .trash:
            sharedMessageDataService.emptyTrash();
        case .spam:
            sharedMessageDataService.emptySpam();
        default:
            break
        }
    }
    
    override func fetchMessages(MessageID: String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        sharedMessageDataService.fetchMessagesForLocation(self.location, MessageID: MessageID, Time:Time, foucsClean: foucsClean, completion:completion)
    }
    
    override func fetchNewMessages(Time: Int, completion: CompletionBlock?) {
        sharedMessageDataService.fetchNewMessagesForLocation(self.location, Time: Time, completion: completion)
    }
    
    override func fetchMessagesForLocationWithEventReset(MessageID: String, Time: Int, completion: CompletionBlock?) {
        sharedMessageDataService.fetchMessagesForLocationWithEventReset(self.location, MessageID: MessageID, Time: Time, completion: completion)
    }
    
}