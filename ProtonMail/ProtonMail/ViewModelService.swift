//
//  ViewModelService.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


protocol ViewModelProtocol {
    func setViewModel(_ vm: AnyObject)
    func inactiveViewModel()
}

// this is abstract ViewModel service
class ViewModelService {
    
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
    
    func resetComposerView() {
        fatalError("This method must be overridden")
    }
    
    func signOut() {
        
    }
}

