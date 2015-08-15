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
    
    override public func getNavigationTitle() -> String {
        return self.label.name
    }
    
    public override func getFetchedResultsController() -> NSFetchedResultsController? {
        return sharedMessageDataService.fetchedResultsControllerForLabels(self.label)
    }
    
    public override func lastUpdateTime() -> LastUpdatedStore.UpdateTime {
        return lastUpdatedStore.labelsLastForKey(label.labelID)
    }
    
    override func fetchMessages(MessageID: String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        sharedMessageDataService.fetchMessagesForLabels(self.label.labelID, MessageID: MessageID, Time:Time, foucsClean: foucsClean, completion:completion)
    }
    
    override func fetchNewMessages(Time: Int, completion: CompletionBlock?) {
        sharedMessageDataService.fetchNewMessagesForLabels(self.label.labelID, Time: Time, completion: completion)
    }
    
}