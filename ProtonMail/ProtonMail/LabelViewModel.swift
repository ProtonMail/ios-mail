//
//  LabelViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData
import ProtonMailCommon


open class LabelMessageModel {
    var label : Label!
    var totalMessages : [Message] = []
    var originalSelected : [Message] = []
    var origStatus : Int = 0
    var currentStatus : Int = 0
}

open class LabelViewModel {
    
    public typealias OkBlock = () -> Void
    public typealias ErrorBlock = (_ code : Int, _ errorMessage : String) -> Void
    
    public init() {
        
    }
    
    open func getFetchType() -> LabelFetchType {
        fatalError("This method must be overridden")
    }
    
    public func apply (archiveMessage : Bool) -> Bool {
        fatalError("This method must be overridden")
    }
    
    open func cancel () {
        fatalError("This method must be overridden")
    }
    
    open func getLabelMessage(_ label : Label!) -> LabelMessageModel! {
        fatalError("This method must be overridden")
    }
    
    open func cellClicked(_ label : Label!) {
        fatalError("This method must be overridden")
    }
    
    open func singleSelectLabel() {
        
    }
    
    open func getTitle() -> String {
        fatalError("This method must be overridden")
    }
    
    open func showArchiveOption() -> Bool {
        fatalError("This method must be overridden")
    }
    
    open func getApplyButtonText() -> String {
        fatalError("This method must be overridden")
    }
    
    open func getCancelButtonText() -> String {
        fatalError("This method must be overridden")
    }
    
    open func fetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        fatalError("This method must be overridden")
    }
}

