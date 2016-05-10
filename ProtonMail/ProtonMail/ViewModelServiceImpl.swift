//
//  ViewModelServiceImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

let sharedVMService : ViewModelService = ViewModelServiceImpl()
class ViewModelServiceImpl: ViewModelService {
    
    private var latestComposerViewModel : ComposeViewModel?
    private var latestComposerViewController : ViewModelProtocol?
    
    override func changeIndex() {
        
    }
    
    override func resetComposerView() {
        if latestComposerViewController != nil {
            latestComposerViewController?.inactiveViewModel()
            latestComposerViewController = nil
        }
        
        latestComposerViewModel = nil
    }
    
    override func newDraftViewModel(vmp : ViewModelProtocol) {
        if latestComposerViewModel != nil {
            //latestComposerViewModel.inactive
        }
        
        if latestComposerViewController != nil {
            //vmp.inactive
        }
        
        latestComposerViewController = vmp
        latestComposerViewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.NewDraft);
        vmp.setViewModel(latestComposerViewModel!)
    }

    
    override func newDraftViewModelWithContact(vmp : ViewModelProtocol, contact: ContactVO!) {
        if latestComposerViewModel != nil {
            //latestComposerViewModel.inactive
        }
        
        if latestComposerViewController != nil {
            //vmp.inactive
        }
        
        latestComposerViewController = vmp
        latestComposerViewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.NewDraft);
        latestComposerViewModel?.addToContacts(contact)
        vmp.setViewModel(latestComposerViewModel!)
    }
    
    override func openDraftViewModel(vmp : ViewModelProtocol, msg: Message!) {
        if latestComposerViewModel != nil {
            //latestComposerViewModel.inactive
        }
        
        if latestComposerViewController != nil {
            //vmp.inactive
        }
        
        latestComposerViewController = vmp
        latestComposerViewModel = ComposeViewModelImpl(msg: msg, action: ComposeMessageAction.OpenDraft);
        vmp.setViewModel(latestComposerViewModel!)
    }
    
    override func actionDraftViewModel(vmp : ViewModelProtocol, msg: Message!, action: ComposeMessageAction) {
        if latestComposerViewModel != nil {
            //latestComposerViewModel.inactive
        }
        
        if latestComposerViewController != nil {
            //vmp.inactive
        }
        
        latestComposerViewController = vmp
        latestComposerViewModel = ComposeViewModelImpl(msg: msg, action: action);
        vmp.setViewModel(latestComposerViewModel!)
    }

}