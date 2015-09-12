//
//  LabelViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData


public class LabelMessageModel {
    var label : Label!
    var totalMessages : [Message] = []
    var originalSelected : [Message] = []
    var status : Int = 0
}

public class LabelViewModel {
    
    public typealias OkBlock = () -> Void
    public typealias ErrorBlock = (code : Int, errorMessage : String) -> Void
    
    public init() {
        
    }
    
    public func apply (archiveMessage : Bool) {
        fatalError("This method must be overridden")
    }
    
    public func cancel () {
        fatalError("This method must be overridden")
    }
    
    public func createLabel (name : String, color : String, error:ErrorBlock,  complete: OkBlock)  {
        fatalError("This method must be overridden")
    }
    
    public func getLabelMessage(label : Label!) -> LabelMessageModel! {
        fatalError("This method must be overridden")
    }
}

public class LabelViewModelImpl : LabelViewModel {
    private var messages : [Message]!
    private var labelMessages : Dictionary<String, LabelMessageModel>!
    
    init(msg:[Message]!) {
        self.messages = msg
        self.labelMessages = Dictionary<String, LabelMessageModel>()
        super.init()
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
                message.location = .archive
                message.needsUpdate = false
            }
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D("error: \(error)")
            }
            let ids = self.messages.map { ($0).messageID }
            let api = MessageActionRequest<ApiResponse>(action: "archive", ids: ids)
            api.call(nil)
        }
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
    
    override public func createLabel(name: String, color: String, error:ErrorBlock,  complete: OkBlock) {
        let api = CreateLabelRequest<CreateLabelRequestResponse>(name: name, color: color)
        
        api.call { (task, response, hasError) -> Void in
            if hasError {
                error(code: response?.code ?? 1000, errorMessage: response?.errorMessage ?? "");
            } else {
                sharedLabelsDataService.addNewLabel(response?.label);
                complete()
            }
        }
    }
    
}