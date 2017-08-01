//
//  ViewModelService.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


public protocol ViewModelProtocol {
    func setViewModel(_ vm: Any)
    func inactiveViewModel()
}

// this is abstract ViewModel service
public class ViewModelService {
    
    public func changeIndex() {
        fatalError("This method must be overridden")
    }
    
    public func newShareDraftViewModel(_ vmp : ViewModelProtocol, subject: String, content: String) {
        fatalError("This method must be overridden")
    }
    
    public func newDraftViewModel(_ vmp : ViewModelProtocol) {
        fatalError("This method must be overridden")
    }
    
    public func newDraftViewModelWithContact(_ vmp : ViewModelProtocol, contact: ContactVO!) {
        fatalError("This method must be overridden")
    }
    
    public func newDraftViewModelWithMailTo(_ vmp : ViewModelProtocol, url: URL?) {
        fatalError("This method must be overridden")
    }
    
    public func openDraftViewModel(_ vmp : ViewModelProtocol, msg: Message!) {
        fatalError("This method must be overridden")
    }
    
    public func actionDraftViewModel(_ vmp : ViewModelProtocol, msg: Message!, action: ComposeMessageAction) {
        fatalError("This method must be overridden")
    }
    
    //messgae detail part
    public func messageDetails(fromList vmp : ViewModelProtocol) -> Void {
        fatalError("This method must be overridden")
    }
    public func messageDetails(fromPush vmp : ViewModelProtocol) -> Void {
        fatalError("This method must be overridden")
    }
    
    //inbox part
    public func mailbox(fromMenu vmp : ViewModelProtocol, location : MessageLocation) -> Void {
        fatalError("This method must be overridden")
    }
    public func labelbox(fromMenu vmp : ViewModelProtocol, label: Label) -> Void {
        fatalError("This method must be overridden")
    }
    
    public func resetView() {
        fatalError("This method must be overridden")
    }
    
    public func signOut() {
        
    }
    
    func cleanLegacy() {
        
        //get current version
        
    }
}

