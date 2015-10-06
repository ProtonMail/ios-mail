//
//  LabelViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



public class LabelMessageModel {
    var selectedMessage : [Message]!
    
    var needSelect : Bool!
    var needRemove : Bool!
}

public class LabelViewModel {

    public typealias OkBlock = () -> Void
    public typealias ErrorBlock = () -> Void
    
    public init() {
    
    }

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
    
    public func createLabel (name : String, color : String, error:ErrorBlock,  complete: OkBlock)  {
        fatalError("This method must be overridden")
    }
}

public class LabelViewModelImpl : LabelViewModel {
    private var message : [Message]!
    
    var currentList = NSMutableSet()
    var addList = NSMutableSet()
    var removeList = NSMutableSet()
    
    init(msg:[Message]!) {
        self.message = msg
        super.init()
        //TODO need figureout the labels
        let labels = self.message[0].mutableSetValueForKey("labels")
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
        
//        let context = sharedCoreDataService.newMainManagedObjectContext()
//        context.performBlockAndWait { () -> Void in
            if self.addList.count > 0 {
                for str in self.addList.allObjects {
                    if let str = str as? String {
//                        if let label = Label.labelForLableID(str, inManagedObjectContext: context) {
//                            var labelObjs = self.message.mutableSetValueForKey("labels")
//                            labelObjs.addObject(label)
//                            self.message.setValue(labelObjs, forKey: "labels")
//                        }
                        let api = ApplyLabelToMessageRequest(labelID: str, messages: [self.message[0].messageID])
                        api.call(nil)
                    }
                    
                }
            }
            
            if self.removeList.count > 0 {
                for str in self.removeList.allObjects {
                    if let str = str as? String {
//                        if let label = Label.labelForLableID(str, inManagedObjectContext: context) {
//                            var labelObjs = self.message.mutableSetValueForKey("labels")
//                            labelObjs.removeObject(label)
//                            self.message.setValue(labelObjs, forKey: "labels")
//                        }
                        let api = RemoveLabelFromMessageRequest(labelID: str, messages: [self.message[0].messageID])
                        api.call(nil)
                    }
                }
            }
            //context.saveUpstreamIfNeeded()
        //}
    }
    
    override public func createLabel(name: String, color: String, error:ErrorBlock,  complete: OkBlock) {
        let api = CreateLabelRequest<CreateLabelRequestResponse>(name: name, color: color)
        
        api.call { (task, response, hasError) -> Void in
            if hasError {
                error();
            } else {
                //var label = response["Label"] as? Dictionary<String,AnyObject>
                sharedLabelsDataService.addNewLabel(response?.label);
                complete()
            }
        }
    }
    
}