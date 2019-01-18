//
//  LabelManagerViewModel.swift
//  ProtonMail - Created on 6/10/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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

