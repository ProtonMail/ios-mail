//
//  FolderApplyViewModelImpl.swift
//  ProtonMail - Created on 3/2/17.
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

final class FolderApplyViewModelImpl : LabelViewModel {
    private var messages : [Message]!
    private var labelMessages : [String : LabelMessageModel]!
    
    private let messageService : MessageDataService
    
    init(msg:[Message], folderService: LabelsDataService, messageService: MessageDataService, apiService: APIService) {
        self.messageService = messageService
        
        super.init(apiService: apiService, labelService: folderService)
        self.messages = msg
        self.labelMessages = [String : LabelMessageModel]()
    }
    
    override func showArchiveOption() -> Bool {
        return false;
    }
    
    override func getApplyButtonText() -> String {
        return LocalString._general_apply_button
    }
    
    override func getCancelButtonText() -> String {
        return LocalString._general_cancel_button
    }
    
    override func getLabelMessage( _ label : Label!) -> LabelMessageModel! {
        if let outVar = self.labelMessages[label.labelID] {
            return outVar
        } else {
            let lmm = LabelMessageModel();
            lmm.label = label
            lmm.totalMessages = self.messages;
            for  m  in self.messages {
                let labels = m.mutableSetValue(forKey: "labels")
                for lb in labels {
                    if let lb = lb as? Label {
                        if lb.labelID == lmm.label.labelID {
                            lmm.originalSelected.append(m)
                        }
                    }
                }
            }
            if lmm.originalSelected.count == 0 {
                lmm.origStatus = 0;
                lmm.currentStatus = 0;
            }
            else if lmm.originalSelected.count > 0 && lmm.originalSelected.count < lmm.totalMessages.count {
                lmm.origStatus = 1;
                lmm.currentStatus = 1;
            } else {
                lmm.origStatus = 2;
                lmm.currentStatus = 2;
            }
            self.labelMessages[label.labelID] = lmm;
            return lmm
        }
    }
    
    
    override func cellClicked(_ label: Label!) {
        
        for (_, model) in self.labelMessages {
            if model.label == label {
                var plusCount = 1
                if model.totalMessages.count <= 1 || 0 ==  model.originalSelected.count || model.originalSelected.count ==  model.totalMessages.count {
                    plusCount = 2
                }
                var tempStatus = model.currentStatus + plusCount;
                if tempStatus > 2 {
                    tempStatus = 0
                }
                model.currentStatus = tempStatus
            } else {
                model.currentStatus = 0
            }
        }
    }
    
    override func apply(archiveMessage : Bool) -> Bool {
        let context = CoreDataService.shared.backgroundManagedObjectContext
        for (key, value) in self.labelMessages {
            if value.currentStatus != value.origStatus && value.currentStatus == 2 { //add
                let ids = self.messages.map { ($0).messageID }
                let api = ApplyLabelToMessages(labelID: key, messages: ids)
                api.call(api: self.apiService, nil)
                context.performAndWait { () -> Void in
                    for mm in self.messages {
                        let flable = mm.firstValidFolder() ?? Message.Location.inbox.rawValue
                        let id = mm.selfSent(labelID: flable)
                        messageService.move(message: mm, from: id ?? flable, to: key, queue: false)
                    }
                }
            }
        }
        return true
    }
    
    override func getTitle() -> String {
        return LocalString._labels_move_to_folder
    }
    
    override func cancel() {
//        let context = sharedCoreDataService.newMainManagedObjectContext()
//        for (_, value) in self.labelMessages {
//            
//            for mm in self.messages {
//                let labelObjs = mm.mutableSetValueForKey("labels")
//                labelObjs.removeObject(value.label)
//                mm.setValue(labelObjs, forKey: "labels")
//            }
//            
//            for mm in value.originalSelected {
//                let labelObjs = mm.mutableSetValueForKey("labels")
//                labelObjs.addObject(value.label)
//                mm.setValue(labelObjs, forKey: "labels")
//            }
//        }
//        
//        let error = context.saveUpstreamIfNeeded()
//        if let error = error {
//            PMLog.D("error: \(error)")
//        }
    }
    
    override func fetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        let hasSent = self.messages.first { $0.contains(label: "2") } != nil // hidden sent, unremovable
        return labelService.fetchedResultsController(hasSent ? .folderWithOutbox : .folderWithInbox )
    }
    
    
    override func getFetchType() -> LabelFetchType {
        return .folder
    }

}
