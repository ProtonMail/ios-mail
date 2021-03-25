//
//  LabelManagerViewModel.swift
//  ProtonMail - Created on 6/10/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import CoreData
import PromiseKit
import PMCommon


// labels and folders manager
final class LabelManagerViewModelImpl : LabelViewModel {
    fileprivate var labelMessages = [String : LabelMessageModel]()
    
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
    
    override func apply(archiveMessage : Bool) -> Promise<Bool> {
        return Promise { seal in
            let context = self.coreDataService.mainManagedObjectContext
            self.coreDataService.enqueue(context: context) { (context) in
                for (key, value) in self.labelMessages {
                    if value.currentStatus == 2 { //delete
                        if value.label.managedObjectContext != nil && key == value.label.labelID {
                            let api = DeleteLabelRequest(lable_id: key)
                            // TODO:: fix me.  check if self.apiService works
                            self.labelService.apiService.exec(route: api) { (_, _) in
                                
                            }
                            context.delete(value.label)
                        }
                    }
                }
                seal.fulfill(true)
            }
        }
    }
    
    override func cancel() {
        
    }
    
    override func fetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        return self.labelService.fetchedResultsController(.all)
    }

    override func getFetchType() -> LabelFetchType {
        return .all
    }
}

