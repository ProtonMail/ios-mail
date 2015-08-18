//
//  LabelViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


public class LabelViewModel {
    public init() { }
    
    public func applyLabel(labelID: String) -> Bool {
        fatalError("This method must be overridden")
    }
    
    public func removeLabel(labelID : String) -> Bool {
        fatalError("This method must be overridden")
    }
    
    public func isEnabled(labelID : String) -> Bool {
        fatalError("This method must be overridden")
    }
    
    public func apply () {
        fatalError("This method must be overridden")
    }
    
}


public class LabelViewModelImpl : LabelViewModel {
    private var message : Message!
    
    var currentList = NSMutableSet()
    var addList = NSMutableSet()
    var removeList = NSMutableSet()
    
    init(msg:Message!) {
        self.message = msg
        super.init()
        let labels = self.message.mutableSetValueForKey("labels")
        for label in labels {
            if let label = label as? Label {
                currentList.addObject(label.labelID)
            }
        }
    }
    
    override public func applyLabel(labelID: String) -> Bool {
        if currentList.count >= 5 {
            return false
        }
        
        addList.addObject(labelID)
        removeList.removeObject(labelID)
        currentList.addObject(labelID)
        
        return true
    }
    
    override public func removeLabel(labelID : String) -> Bool {
        removeList.addObject(labelID)
        addList.removeObject(labelID)
        currentList.removeObject(labelID)
        return true
    }
    
    override public func isEnabled(labelID : String) -> Bool {
        let found = self.currentList.containsObject(labelID)
        return found
    }
    
    override public func apply() {
        
        //let context = sharedCoreDataService.newMainManagedObjectContext()
        
        if addList.count > 0 {
            for str in addList.allObjects {
                if let str = str as? String {
                    let api = ApplyLabelToMessageRequest(labelID: str, messages: [message.messageID])
                    api.call(nil)
                    
//                    if let label = Label.labelForLableID(str, inManagedObjectContext: context) {
//                        var labelObjs = self.message.mutableSetValueForKey("labels")
//                        labelObjs.addObject(label)
//                        self.message.setValue(labelObjs, forKey: "labels")
//                    }
                    
                }
                
            }
        }
        
        if removeList.count > 0 {
            for str in removeList.allObjects {
                if let str = str as? String {
                    let api = RemoveLabelFromMessageRequest(labelID: str, messages: [message.messageID])
                    api.call(nil)
                    
//                    if let label = Label.labelForLableID(str, inManagedObjectContext: context) {
//                        var labelObjs = self.message.mutableSetValueForKey("labels")
//                        labelObjs.removeObject(label)
//                        self.message.setValue(labelObjs, forKey: "labels")
//                    }
                }
            }
        }
        
        //context.saveUpstreamIfNeeded()
    }
    
}