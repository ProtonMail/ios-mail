//
//  LabelApplayViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 10/19/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

open class LabelApplyViewModelImpl : LabelViewModel {
    fileprivate var messages : [Message]!
    fileprivate var labelMessages : Dictionary<String, LabelMessageModel>!
    
    init(msg:[Message]!) {
        super.init()
        self.messages = msg
        self.labelMessages = Dictionary<String, LabelMessageModel>()
    }

    override open func showArchiveOption() -> Bool {
        if let msg = messages.first {
            let locations = msg.getLocationFromLabels()
            for loc in locations {
                if loc == .outbox {
                    return false;
                }
            }
        }
        return true;
    }
    
    open override func getApplyButtonText() -> String {
        return NSLocalizedString("Apply")
    }
    
    open override func getCancelButtonText() -> String {
        return NSLocalizedString("Cancel")
    }
    
    override open func getLabelMessage( _ label : Label!) -> LabelMessageModel! {
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
    
    open override func cellClicked(_ label: Label!) {
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
    
//    func selectAction() {
//        var plusCount = 1
//        if model.totalMessages.count <= 1 || 0 ==  model.originalSelected.count || model.originalSelected.count ==  model.totalMessages.count {
//            plusCount = 2
//        }
//
//        var tempStatus = self.model.currentStatus + plusCount;
//        if tempStatus > 2 {
//            tempStatus = 0
//        }
//        
//        if tempStatus == 0 {
//            for mm in self.model.totalMessages {
//                let labelObjs = mm.mutableSetValueForKey("labels")
//                labelObjs.removeObject(model.label)
//                mm.setValue(labelObjs, forKey: "labels")
//            }
//        } else if tempStatus == 1 {
//            for mm in self.model.totalMessages {
//                let labelObjs = mm.mutableSetValueForKey("labels")
//                labelObjs.removeObject(model.label)
//                mm.setValue(labelObjs, forKey: "labels")
//            }
//            
//            for mm in self.model.originalSelected {
//                let labelObjs = mm.mutableSetValueForKey("labels")
//                labelObjs.addObject(model.label)
//                mm.setValue(labelObjs, forKey: "labels")
//            }
//        } else if tempStatus == 2 {
//            for mm in self.model.totalMessages {
//                let labelObjs = mm.mutableSetValueForKey("labels")
//                var labelCount = 0
//                for l in labelObjs {
//                    if (l as! Label).labelID != model.label.labelID {
//                        labelCount += 1
//                    }
//                }
//                if labelCount >= maxLabelCount {
//                    let alert = NSLocalizedString("A message cannot have more than \(maxLabelCount) labels").alertController();
//                    alert.addOKAction()
//                    vc.presentViewController(alert, animated: true, completion: nil)
//                    return;
//                }
//            }
//            
//            for mm in self.model.totalMessages {
//                let labelObjs = mm.mutableSetValueForKey("labels")
//                labelObjs.addObject(model.label)
//                mm.setValue(labelObjs, forKey: "labels")
//            }
//        }
//        
//        self.model.currentStatus = tempStatus
//        self.updateStatusButton();
//    }
    
    override public func apply(archiveMessage : Bool) -> Bool {
        let context = sharedCoreDataService.newMainManagedObjectContext()
        for (key, value) in self.labelMessages {
            if value.currentStatus != value.origStatus && value.currentStatus == 0 { //remove
                let ids = self.messages.map { ($0).messageID }
                let api = RemoveLabelFromMessageRequest(labelID: key, messages: ids)
                api.call(nil)
                context.performAndWait { () -> Void in
                    for mm in self.messages {
                        let labelObjs = mm.mutableSetValue(forKey: "labels")
                        labelObjs.remove(value.label)
                        mm.setValue(labelObjs, forKey: "labels")
                    }
                }
            } else if value.currentStatus != value.origStatus && value.currentStatus == 2 { //add
                let ids = self.messages.map { ($0).messageID }
                let api = ApplyLabelToMessageRequest(labelID: key, messages: ids)
                api.call(nil)
                context.performAndWait { () -> Void in
                    for mm in self.messages {
                        let labelObjs = mm.mutableSetValue(forKey: "labels")
                        labelObjs.add(value.label)
                        mm.setValue(labelObjs, forKey: "labels")
                    }
                }
            } else {
                
            }
            
            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D("error: \(error)")
            }
        }
        
        if archiveMessage {
            for message in self.messages {
                message.removeLocationFromLabels(currentlocation: message.location, location: .archive, keepSent: true)
                message.needsUpdate = false
                message.location = .archive
            }
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D("error: \(error)")
            }
            let ids = self.messages.map { ($0).messageID }
            let api = MessageActionRequest<ApiResponse>(action: "archive", ids: ids)
            api.call(nil)
        }
        
        return true
    }
    
    override open func getTitle() -> String {
        return NSLocalizedString("Apply Labels")
    }
    
    override open func cancel() {
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
    
    open override func fetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        return sharedLabelsDataService.fetchedResultsController(.label)
    }

    open override func getFetchType() -> LabelFetchType {
        return .label
    }
}
