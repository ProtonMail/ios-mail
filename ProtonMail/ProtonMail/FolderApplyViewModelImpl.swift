//
//  FolderApplyViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/2/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



//
//  LabelApplayViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 10/19/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

public class FolderApplyViewModelImpl : LabelViewModel {
    private var messages : [Message]!
    private var labelMessages : Dictionary<String, LabelMessageModel>!
    
    init(msg:[Message]!) {
        super.init()
        self.messages = msg
        self.labelMessages = Dictionary<String, LabelMessageModel>()
    }
    
    override public func showArchiveOption() -> Bool {
        return false;
    }
    
    public override func getApplyButtonText() -> String {
        return NSLocalizedString("Apply")
    }
    
    public override func getCancelButtonText() -> String {
        return NSLocalizedString("Cancel")
    }
    
    override public func getLabelMessage( label : Label!) -> LabelMessageModel! {
        if let outVar = self.labelMessages[label.labelID] {
            return outVar
        } else {
            let lmm = LabelMessageModel();
            lmm.label = label
            lmm.totalMessages = self.messages;
            for  m  in self.messages {
                let labels = m.mutableSetValueForKey("labels")
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
    
    
    public override func cellClicked(label: Label!) {
        
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
    
    override public func apply(archiveMessage : Bool) -> Bool {
        var changed : Bool = false
        let context = sharedCoreDataService.newMainManagedObjectContext()
        for (key, value) in self.labelMessages {
            if value.currentStatus != value.origStatus && value.currentStatus == 2 { //add
                let ids = self.messages.map { ($0).messageID }
                let api = ApplyLabelToMessageRequest(labelID: key, messages: ids)
                api.call(nil)
                context.performBlockAndWait { () -> Void in
                    for mm in self.messages {
                        let labelObjs = mm.mutableSetValueForKey("labels")
                        var needsDelete : [Label] = []
                        for lo in labelObjs {
                            if let l = lo as? Label {
                                switch l.labelID {
                                case "0", "3", "4", "6":
                                    needsDelete.append(l)
                                    changed = true
                                default:
                                    if l.exclusive == true {
                                        needsDelete.append(l)
                                        changed = true
                                    }
                                    break
                                }
                                
                            }
                        }
                        for l in needsDelete {
                            labelObjs.removeObject(l)
                            changed = true
                        }
                        labelObjs.addObject(value.label)
                        mm.setValue(labelObjs, forKey: "labels")
                    }
                }
            }
            
            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D("error: \(error)")
            }
        }
        return changed
    }
    
    override public func getTitle() -> String {
        return NSLocalizedString("Move to Folder")
    }
    
    override public func cancel() {
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
    
    public override func fetchController() -> NSFetchedResultsController? {
        return sharedLabelsDataService.fetchedResultsController(.folder)
    }
    
    
    public override func getFetchType() -> LabelFetchType {
        return .folder
    }

}
