//
//  LabelboxViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



public class LabelboxViewModelImpl : MailboxViewModel {
    
    private let label : Label!
    
    init(label : Label) {
        
        self.label = label
        
        super.init()
    }
    
    public override func showLocation () -> Bool {
        return true
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
    
    public override func deleteMessage(msg: Message) {
        msg.location = .trash
        msg.needsUpdate = true
        if let error = msg.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
    }

    public override func getFetchedResultsController() -> NSFetchedResultsController? {
        let fetchedResultsController = sharedMessageDataService.fetchedResultsControllerForLabels(self.label)
        if let fetchedResultsController = fetchedResultsController {
            var error: NSError?
            if !fetchedResultsController.performFetch(&error) {
                NSLog("\(__FUNCTION__) error: \(error)")
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
    
    override func fetchNewMessages(Time: Int, completion: CompletionBlock?) {
        sharedMessageDataService.fetchNewMessagesForLabels(self.getLabelID(), Time: Time, completion: completion)
    }
    
}