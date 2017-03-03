//
//  LabelApplayViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 10/19/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

public class LabelApplyViewModelImpl : LabelViewModel {
    private var messages : [Message]!
    private var labelMessages : Dictionary<String, LabelMessageModel>!
    
    init(msg:[Message]!) {
        super.init()
        self.messages = msg
        self.labelMessages = Dictionary<String, LabelMessageModel>()
    }

    override public func showArchiveOption() -> Bool {
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
                lmm.status = 0;
            }
            else if lmm.originalSelected.count > 0 && lmm.originalSelected.count < lmm.totalMessages.count {
                lmm.status = 1;
            } else {
                lmm.status = 2;
            }
            
            self.labelMessages[label.labelID] = lmm;
            return lmm
        }
    }
    
    override public func apply(archiveMessage : Bool) {
        
        let context = sharedCoreDataService.newMainManagedObjectContext()
        for (key, value) in self.labelMessages {
            if value.status == 0 { //remove
                let ids = self.messages.map { ($0).messageID }
                let api = RemoveLabelFromMessageRequest(labelID: key, messages: ids)
                api.call(nil)
                context.performBlockAndWait { () -> Void in
                    for mm in self.messages {
                        let labelObjs = mm.mutableSetValueForKey("labels")
                        labelObjs.removeObject(value.label)
                        mm.setValue(labelObjs, forKey: "labels")
                    }
                }
            } else if value.status == 2 { //add
                let ids = self.messages.map { ($0).messageID }
                let api = ApplyLabelToMessageRequest(labelID: key, messages: ids)
                api.call(nil)
                context.performBlockAndWait { () -> Void in
                    for mm in self.messages {
                        let labelObjs = mm.mutableSetValueForKey("labels")
                        labelObjs.addObject(value.label)
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
                message.removeLocationFromLabels(message.location, location: .archive)
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
    }
    
    override public func getTitle() -> String {
        return NSLocalizedString("Apply Labels")
    }
    
    override public func cancel() {
        let context = sharedCoreDataService.newMainManagedObjectContext()
        for (_, value) in self.labelMessages {
            
            for mm in self.messages {
                let labelObjs = mm.mutableSetValueForKey("labels")
                labelObjs.removeObject(value.label)
                mm.setValue(labelObjs, forKey: "labels")
            }
            
            for mm in value.originalSelected {
                let labelObjs = mm.mutableSetValueForKey("labels")
                labelObjs.addObject(value.label)
                mm.setValue(labelObjs, forKey: "labels")
            }
        }
        
        let error = context.saveUpstreamIfNeeded()
        if let error = error {
            PMLog.D("error: \(error)")
        }
    }
    
    public override func fetchController() -> NSFetchedResultsController? {
        return sharedLabelsDataService.fetchedResultsController(.label)
    }

    public override func getFetchType() -> LabelFetchType {
        return .label
    }
}
