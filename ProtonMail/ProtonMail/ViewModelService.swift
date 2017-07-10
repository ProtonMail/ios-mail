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
    
    func changeIndex() {
        fatalError("This method must be overridden")
    }
    
    func newDraftViewModel(_ vmp : ViewModelProtocol) {
        fatalError("This method must be overridden")
    }
    
    func newDraftViewModelWithContact(_ vmp : ViewModelProtocol, contact: ContactVO!) {
        fatalError("This method must be overridden")
    }
    
    func newDraftViewModelWithMailTo(_ vmp : ViewModelProtocol, url: URL?) {
        fatalError("This method must be overridden")
    }
    
    func openDraftViewModel(_ vmp : ViewModelProtocol, msg: Message!) {
        fatalError("This method must be overridden")
    }
    
    func actionDraftViewModel(_ vmp : ViewModelProtocol, msg: Message!, action: ComposeMessageAction) {
        fatalError("This method must be overridden")
    }
    
    //messgae detail part
    func messageDetails(fromList vmp : ViewModelProtocol) -> Void {
        fatalError("This method must be overridden")
    }
    func messageDetails(fromPush vmp : ViewModelProtocol) -> Void {
        fatalError("This method must be overridden")
    }
    
    //inbox part
    func mailbox(fromMenu vmp : ViewModelProtocol, location : MessageLocation) -> Void {
        fatalError("This method must be overridden")
    }
    func labelbox(fromMenu vmp : ViewModelProtocol, label: Label) -> Void {
        fatalError("This method must be overridden")
    }
    
    
    func resetView() {
        fatalError("This method must be overridden")
    }
    
    func signOut() {
        
    }
}

