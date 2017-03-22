//
//  LabelManagerViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/10/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation


// labels and folders manager
public class LabelManagerViewModelImpl : LabelViewModel {
    private var labelMessages : Dictionary<String, LabelMessageModel>!
    public override init() {
        super.init()
        self.labelMessages = Dictionary<String, LabelMessageModel>()
    }
    
    override public func showArchiveOption() -> Bool {
        return false
    }
    
    override public func getLabelMessage( label : Label!) -> LabelMessageModel! {
        if let outVar = self.labelMessages[label.labelID] {
            return outVar
        } else {
            let lmm = LabelMessageModel();
            lmm.label = label
            lmm.origStatus = 0
            lmm.currentStatus = 0
            self.labelMessages[label.labelID] = lmm;
            return lmm
        }
    }
    
    override public func getTitle() -> String {
        return NSLocalizedString("Manage Labels/Folders")
    }
    
    public override func getApplyButtonText() -> String {
        return NSLocalizedString("Delete")
    }
    
    public override func getCancelButtonText() -> String {
        return NSLocalizedString("Close")
    }
    
    public override func cellClicked(label: Label!) {
        if let model = self.labelMessages[label.labelID] {
            var plusCount = 1
            if model.totalMessages.count <= 1 || 0 ==  model.originalSelected.count || model.originalSelected.count ==  model.totalMessages.count {
                plusCount = 2
            }
            
            var tempStatus = model.currentStatus + plusCount;
            if tempStatus > 2 {
                tempStatus = 0
            }
            
            model.currentStatus = tempStatus
        }
    }
    
    override public func apply(archiveMessage : Bool) -> Bool {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            for (key, value) in self.labelMessages {
                if value.currentStatus == 2 { //delete
                    if value.label.managedObjectContext != nil && key == value.label.labelID {
                        let api = DeleteLabelRequest(lable_id: key)
                        api.call(nil)
                        context.performBlockAndWait { () -> Void in
                            context.deleteObject(value.label)
                        }
                    }
                }
            }
        }
        return true
    }
    
    override public func cancel() {
        
    }
    
    public override func fetchController() -> NSFetchedResultsController? {
        return sharedLabelsDataService.fetchedResultsController(.all)
    }

    public override func getFetchType() -> LabelFetchType {
        return .all
    }
    
}

