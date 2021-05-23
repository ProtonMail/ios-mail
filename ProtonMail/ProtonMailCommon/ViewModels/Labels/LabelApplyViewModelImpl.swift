//
//  LabelApplayViewModel.swift
//  ProtonMail - Created on 10/19/16.
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

final class LabelApplyViewModelImpl : LabelViewModel {
    fileprivate var messages : [Message]!
    fileprivate var labelMessages : [String : LabelMessageModel]!

    let cacheService: CacheService
    
    init(msg:[Message]!, labelService: LabelsDataService, messageService: MessageDataService, apiService: APIService, cacheService: CacheService) {
        self.cacheService = cacheService
        
        super.init(apiService: apiService, labelService: labelService, messageService: messageService)
        self.messages = msg
        self.labelMessages = [String : LabelMessageModel]()
    }

    override func showArchiveOption() -> Bool {
        if let msg = messages.first {
            if msg.contains(label: .draft) || msg.contains(label: .archive) {
                return false
            }
        }
        return true
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
            let lmm = LabelMessageModel()
            lmm.label = label
            lmm.totalMessages = self.messages
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
                lmm.origStatus = 0
                lmm.currentStatus = 0
            }
            else if lmm.originalSelected.count > 0 && lmm.originalSelected.count < lmm.totalMessages.count {
                lmm.origStatus = 1
                lmm.currentStatus = 1
            } else {
                lmm.origStatus = 2
                lmm.currentStatus = 2
            }
            self.labelMessages[label.labelID] = lmm
            return lmm
        }
    }
    
    override func cellClicked(_ label: Label!) {
        if let model = self.labelMessages[label.labelID] {
            var plusCount = 1
            if model.totalMessages.count <= 1 || 0 ==  model.originalSelected.count || model.originalSelected.count ==  model.totalMessages.count {
                plusCount = 2
            }
            
            var tempStatus = model.currentStatus + plusCount
            if tempStatus > 2 {
                tempStatus = 0
            }
            
            model.currentStatus = tempStatus
        }
    }
    
    override func apply(archiveMessage : Bool) -> Promise<Bool> {
        return Promise { seal in
            for (key, value) in self.labelMessages {
                #warning("v4 update")
                if value.currentStatus != value.origStatus && value.currentStatus == 0 { //remove
                    self.messageService.label(messages: self.messages, label: key, apply: false)
                } else if value.currentStatus != value.origStatus && value.currentStatus == 2 { //add
                    self.messageService.label(messages: self.messages, label: key, apply: true)
                }
            }

            if archiveMessage {
                var _msgs = [Message]()
                var fLabels = [String]()
                for message in self.messages {
                    if let flabel = message.firstValidFolder() {
                        fLabels.append(flabel)
                        _msgs.append(message)
                    }
                }
                self.messageService.move(messages: _msgs, from: fLabels, to: Message.Location.archive.rawValue)
            }

            seal.fulfill(true)
        }
    }
    
    override func getTitle() -> String {
        return LocalString._apply_labels
    }
    
    override func cancel() {

    }
    
    override func fetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        return self.labelService.fetchedResultsController(.label)
    }

    override func getFetchType() -> LabelFetchType {
        return .label
    }
}
