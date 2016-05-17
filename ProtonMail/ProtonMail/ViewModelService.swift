//
//  ViewModelService.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


// this is abstract ViewModel service
class ViewModelService {
    
    func changeIndex() {
        fatalError("This method must be overridden")
    }
    
    func newDraftViewModel(vmp : ViewModelProtocol) {
        fatalError("This method must be overridden")
    }
    
    func newDraftViewModelWithContact(vmp : ViewModelProtocol, contact: ContactVO!) {
        fatalError("This method must be overridden")
    }
    
    func openDraftViewModel(vmp : ViewModelProtocol, msg: Message!) {
        fatalError("This method must be overridden")
    }
    
    func actionDraftViewModel(vmp : ViewModelProtocol, msg: Message!, action: ComposeMessageAction) {
        fatalError("This method must be overridden")
    }
    
    func resetComposerView() {
        fatalError("This method must be overridden")
    }
    
    func signOut() {
        
    }
}


protocol ViewModelProtocol {
    func setViewModel(vm: AnyObject)
    func inactiveViewModel()
}