//
//  LabelboxViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData

public class LabelboxViewModelImpl : MailboxViewModel {
    
    private var label : Label!
    
    init(label : Label) {
        super.init()
        self.label = label
    }
    
    public override func showLocation () -> Bool {
        return true
    }
    
    public override func ignoredLocationTitle() -> String {
        return self.label.exclusive ? self.label.name : ""
    }
    
    public func stayAfterAction () -> Bool {
        return true
    }
    
    override public func getNavigationTitle() -> String {
        return self.label.name
    }
    
    public override func getSwipeTitle(action: MessageSwipeAction) -> String {
        return action.description;
    }
    
    public override func stayAfterAction (action: MessageSwipeAction) -> Bool {
        return true
    }
    
    public override func deleteMessage(msg: Message) -> Bool {
        msg.removeLocationFromLabels(msg.location, location: .trash)
        msg.needsUpdate = true
        msg.location = .trash
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            PMLog.D(" error: \(error)")
        }
        return true
    }

    public override func getFetchedResultsController() -> NSFetchedResultsController? {
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
    
    private func getLabelID() -> String {
        if label.managedObjectContext != nil {
            return label.labelID
        }
        return "unknown"
    }
    
    public override func lastUpdateTime() -> LastUpdatedStore.UpdateTime {
        return lastUpdatedStore.labelsLastForKey(self.getLabelID())
    }
    
    override func fetchMessages(MessageID: String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        sharedMessageDataService.fetchMessagesForLabels(self.getLabelID(), MessageID: MessageID, Time:Time, foucsClean: foucsClean, completion:completion)
    }
    
    override func fetchNewMessages(notificationMessageID:String?, Time: Int, completion: CompletionBlock?) {
        sharedMessageDataService.fetchNewMessagesForLabels(self.getLabelID(), Time: Time, notificationMessageID: notificationMessageID, completion: completion)
    }
    
    override func getNotificationMessage() -> String? {
        return sharedMessageDataService.pushNotificationMessageID
    }
    
    override func resetNotificationMessage() -> Void {
        sharedMessageDataService.pushNotificationMessageID = nil
    }
}
