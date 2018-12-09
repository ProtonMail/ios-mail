//
//  LabelManagerViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/10/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation
import CoreData


// labels and folders manager
final class LabelManagerViewModelImpl : LabelViewModel {
    fileprivate var labelMessages : [String : LabelMessageModel]!
    override init() {
        super.init()
        self.labelMessages = [String : LabelMessageModel]()
    }
    
    override func showArchiveOption() -> Bool {
        return false
    }
    
    override func getLabelMessage( _ label : Label!) -> LabelMessageModel! {
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
    
    override func getTitle() -> String {
        return LocalString._labels_manage_title
    }
    
    override func getApplyButtonText() -> String {
        return LocalString._general_delete_action
    }
    
    override func getCancelButtonText() -> String {
        return LocalString._general_close_action
    }
    
    override func cellClicked(_ label: Label!) {
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
    
    override func apply(archiveMessage : Bool) -> Bool {
        let context = sharedCoreDataService.mainManagedObjectContext
        for (key, value) in self.labelMessages {
            if value.currentStatus == 2 { //delete
                if value.label.managedObjectContext != nil && key == value.label.labelID {
                    let api = DeleteLabelRequest(lable_id: key)
                    api.call(nil)
                    context.performAndWait { () -> Void in
                        context.delete(value.label)
                    }
                }
            }
        }
        return true
    }
    
    override func cancel() {
        
    }
    
    override func fetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        return sharedLabelsDataService.fetchedResultsController(.all)
    }

    override func getFetchType() -> LabelFetchType {
        return .all
    }
    
}

