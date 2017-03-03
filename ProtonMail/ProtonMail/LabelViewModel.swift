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
    
    public func getTitle() -> String {
        fatalError("This method must be overridden")
    }
    
    public func showArchiveOption() -> Bool {
        fatalError("This method must be overridden")
    }
    
    public func getApplyButtonText() -> String {
        fatalError("This method must be overridden")
    }
    
    public func getCancelButtonText() -> String {
        fatalError("This method must be overridden")
    }
    
    public func fetchController() -> NSFetchedResultsController? {
        fatalError("This method must be overridden")
    }
}

