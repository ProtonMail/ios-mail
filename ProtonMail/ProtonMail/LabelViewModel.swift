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
    
    public func applyLabel(labelID: String) {
        fatalError("This method must be overridden")
    }
    
    public func removeLabel(labelID : String) {
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
        //        if let label = Label.labelForLableID(add as! String, inManagedObjectContext: context) {
        //            var labelObjs = messageObject.mutableSetValueForKey("labels")
        //            labelObjs.addObject(label)
        //            messageObject.setValue(labelObjs, forKey: "labels")
        //        }
    }
    
    override public func applyLabel(labelID: String) {
        addList.addObject(labelID)
        removeList.removeObject(labelID)
        currentList.addObject(labelID)
    }
    
    override public func removeLabel(labelID : String) {
        removeList.addObject(labelID)
        addList.removeObject(labelID)
        currentList.removeObject(labelID)
    }
    
    override public func isEnabled(labelID : String) -> Bool {
        let found = self.currentList.containsObject(labelID)
        return found
    }
    
    override public func apply() {
        println(self.currentList)
    }
    
}