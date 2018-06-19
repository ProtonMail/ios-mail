//
//  MailboxViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData

class MailboxViewModelImpl : MailboxViewModel {
    
    fileprivate var location : MessageLocation!
    
    init(location : MessageLocation) {
        super.init()
        self.location = location
    }
    
    override func getNavigationTitle() -> String {
        return self.location.title
    }
    
    override func getFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult>? {
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
    
    override func lastUpdateTime() -> UpdateTime {
        return lastUpdatedStore.inboxLastForKey(self.location)
    }
    
    override func getSwipeTitle(_ action: MessageSwipeAction) -> String {
        switch(self.location!) {
        case .trash, .spam:
            if action == .trash {
                return LocalString._general_delete_action
            }
            return action.description;
        default:
            return action.description;
        }
    }
    
    override func isSwipeActionValid(_ action: MessageSwipeAction) -> Bool {
        switch(self.location!) {
        case .archive:
            return action != .archive
        case .starred:
            return action != .star
        case .spam:
            return action != .spam
        case .draft, .outbox:
            return action != .spam && action != .trash && action != .archive
        case .trash:
            return action != .trash
        case .allmail:
            return false;
        default:
            return true
        }
    }
    
    override func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
        switch(self.location!) {
        case .starred:
            return true
        default:
            return false
        }
    }
    
    override func deleteMessage(_ msg: Message) -> SwipeResponse  {
        var needShowMessage = true
        if let context = msg.managedObjectContext {
            switch(self.location!) {
            case .trash, .spam:
                msg.removeLocationFromLabels(currentlocation: self.location, location: .deleted, keepSent: false)
                msg.needsUpdate = true
                msg.location = .deleted
                needShowMessage = false
            default:
                msg.removeLocationFromLabels(currentlocation: self.location, location: .trash, keepSent: true)
                msg.needsUpdate = true
                self.updateBadgeNumberWhenMove(msg, to: .deleted)
                msg.location = .trash
            }
            context.perform {
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(error)")
                }
            }
        }
        return needShowMessage ? SwipeResponse.showUndo : SwipeResponse.nothing
    }
    
    override func isDrafts() -> Bool {
        return self.location == MessageLocation.draft
    }
    
    override func isArchive() -> Bool {
        return self.location == MessageLocation.archive
    }
    
    override func isDelete () -> Bool {
        switch(self.location!) {
        case .trash, .spam, .draft:
            return true;
        default:
            return false
        }
    }
    
    override func showLocation() -> Bool {
        switch(self.location!) {
        case .allmail, .outbox:
            return true
        default:
            return false
        }
    }
    
    override func isCurrentLocation(_ l: MessageLocation) -> Bool {
        return self.location == l
    }
    
    override func isShowEmptyFolder() -> Bool {
        switch(self.location!) {
        case .trash, .spam:
            return true;
        default:
            return false
        }
    }
    
    override func emptyFolder() {
        switch(self.location!) {
        case .trash:
            sharedMessageDataService.emptyTrash();
        case .spam:
            sharedMessageDataService.emptySpam();
        default:
            break
        }
    }
    
    override func ignoredLocationTitle() -> String {
        if self.location == .outbox {
            return MessageLocation.outbox.title
        }
        return ""
    }
    
    override func fetchMessages(_ MessageID: String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        sharedMessageDataService.fetchMessagesForLocation(self.location, MessageID: MessageID, Time:Time, foucsClean: foucsClean, completion:completion)
    }
    
    override func fetchNewMessages(_ notificationMessageID:String?, Time: Int, completion: CompletionBlock?) {
        sharedMessageDataService.fetchNewMessagesForLocation(self.location, notificationMessageID: notificationMessageID, completion: completion)
    }
    
    override func fetchMessagesForLocationWithEventReset(_ MessageID: String, Time: Int, completion: CompletionBlock?) {
        sharedMessageDataService.fetchMessagesForLocationWithEventReset(self.location, MessageID: MessageID, Time: Time, completion: completion)
    }
    
    override func getNotificationMessage() -> String? {
        return sharedMessageDataService.pushNotificationMessageID
    }
    override func resetNotificationMessage() -> Void {
        sharedMessageDataService.pushNotificationMessageID = nil
    }
    
    override func reloadTable() -> Bool {
        return self.location == .draft
    }
}
