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
import PromiseKit
import ProtonCore_Services

final class FolderApplyViewModelImpl : LabelViewModel {
    private var messages : [Message]!
    private var labelMessages : [String : LabelMessageModel]!
    
    init(msg:[Message], folderService: LabelsDataService, messageService: MessageDataService, apiService: APIService) {
        super.init(apiService: apiService, labelService: folderService, messageService: messageService)
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
    
    override func apply(archiveMessage : Bool) -> Promise<Bool> {
        return Promise { seal in
            for (key, value) in self.labelMessages {
                guard value.currentStatus != value.origStatus &&
                        value.currentStatus == 2 else {
                    continue
                }
                //add
                var fLabels = [String]()
                for mm in self.messages {
                    let flable = mm.firstValidFolder() ?? Message.Location.inbox.rawValue
                    let id = mm.selfSent(labelID: flable) ?? flable
                    fLabels.append(id)
                }
                self.messageService.move(messages: self.messages, from: fLabels, to: key)
            }
            seal.fulfill(true)
        }
    }
    
    override func getTitle() -> String {
        return LocalString._labels_move_to_folder
    }
    
    override func fetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        let hasSent = self.messages.first { $0.contains(label: "2") } != nil // hidden sent, unremovable
        return labelService.fetchedResultsController(hasSent ? .folderWithOutbox : .folderWithInbox )
    }
    
    override func getFetchType() -> LabelFetchType {
        return .folder
    }
}
