//
//  MailboxViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData


public class MailboxViewModelImpl : MailboxViewModel {
    
    private var location : MessageLocation!
    
    init(location : MessageLocation) {
        super.init()
        self.location = location
    }
    
    override public func getNavigationTitle() -> String {
        return self.location.title
    }
    
    public override func getFetchedResultsController() -> NSFetchedResultsController? {
        let fetchedResultsController = sharedMessageDataService.fetchedResultsControllerForLocation(self.location)
        if let fetchedResultsController = fetchedResultsController {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
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
        case .draft:
            return action != .spam && action != .trash && action != .archive
        case .trash:
            return action != .trash
        case .allmail:
            return false;
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
    
    public override func deleteMessage(msg: Message) -> Bool  {
        var needShowMessage = true
        if msg.managedObjectContext != nil {
            switch(self.location!) {
            case .trash, .spam:
                msg.removeLocationFromLabels(self.location, location: .deleted)
                msg.needsUpdate = true
                msg.location = .deleted
                needShowMessage = false
            default:
                msg.removeLocationFromLabels(self.location, location: .trash)
                msg.needsUpdate = true
                self.updateBadgeNumberWhenMove(msg, to: .deleted)
                msg.location = .trash
            }
            if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
                PMLog.D("error: \(error)")
            }
        }
        return needShowMessage
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
    
    override public func showLocation() -> Bool {
        switch(self.location!) {
        case .allmail:
            return true
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
    
    override func fetchNewMessages(notificationMessageID:String?, Time: Int, completion: CompletionBlock?) {
        sharedMessageDataService.fetchNewMessagesForLocation(self.location, Time: Time, notificationMessageID: notificationMessageID, completion: completion)
    }
    
    override func fetchMessagesForLocationWithEventReset(MessageID: String, Time: Int, completion: CompletionBlock?) {
        sharedMessageDataService.fetchMessagesForLocationWithEventReset(self.location, MessageID: MessageID, Time: Time, completion: completion)
    }
    
    override func getNotificationMessage() -> String? {
        return sharedMessageDataService.pushNotificationMessageID
    }
    override func resetNotificationMessage() -> Void {
        sharedMessageDataService.pushNotificationMessageID = nil
    }
}
