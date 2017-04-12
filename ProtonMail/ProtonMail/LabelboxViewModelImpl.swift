//
//  LabelboxViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData

class LabelboxViewModelImpl : MailboxViewModel {
    
    fileprivate var label : Label!
    
    init(label : Label) {
        super.init()
        self.label = label
    }
    
    open override func showLocation () -> Bool {
        return true
    }
    
    open override func ignoredLocationTitle() -> String {
        return self.label.exclusive ? self.label.name : ""
    }
    
    open func stayAfterAction () -> Bool {
        return true
    }
    
    override open func getNavigationTitle() -> String {
        return self.label.name
    }
    
    open override func getSwipeTitle(_ action: MessageSwipeAction) -> String {
        return action.description;
    }
    
    open override func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
        return true
    }
    
    open override func deleteMessage(_ msg: Message) -> Bool {
        msg.removeLocationFromLabels(currentlocation: msg.location, location: .trash, keepSent: true)
        msg.needsUpdate = true
        msg.location = .trash
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            PMLog.D(" error: \(error)")
        }
        return true
    }

    open override func getFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        let fetchedResultsController = sharedMessageDataService.fetchedResultsControllerForLabels(self.label)
        if let fetchedResultsController = fetchedResultsController {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                 PMLog.D(" error: \(ex)")
            }
        }
        return fetchedResultsController
    }
    
    fileprivate func getLabelID() -> String {
        if label.managedObjectContext != nil {
            return label.labelID
        }
        return "unknown"
    }
    
    override func lastUpdateTime() -> UpdateTime {
        return lastUpdatedStore.labelsLastForKey(self.getLabelID())
    }
    
    override func fetchMessages(_ MessageID: String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        sharedMessageDataService.fetchMessagesForLabels(self.getLabelID(), MessageID: MessageID, Time:Time, foucsClean: foucsClean, completion:completion)
    }
    
    override func fetchNewMessages(_ notificationMessageID:String?, Time: Int, completion: CompletionBlock?) {
        sharedMessageDataService.fetchNewMessagesForLabels(self.getLabelID(), Time: Time, notificationMessageID: notificationMessageID, completion: completion)
    }
    
    override func getNotificationMessage() -> String? {
        return sharedMessageDataService.pushNotificationMessageID
    }
    
    override func resetNotificationMessage() -> Void {
        sharedMessageDataService.pushNotificationMessageID = nil
    }
}
