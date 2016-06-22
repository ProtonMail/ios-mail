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
    
    
    override func signOut() {
        self.resetComposerView()
    }
    
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
    
    override func newDraftViewModelWithMailTo(vmp: ViewModelProtocol, url: NSURL?) {
        if latestComposerViewModel != nil {
            //latestComposerViewModel.inactive
        }
        if latestComposerViewController != nil {
            //vmp.inactive
        }
        latestComposerViewController = vmp
        latestComposerViewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.NewDraft);

        if let checkedUrl : NSURL = url where checkedUrl.scheme == "mailto" {
            var rawURLparts = checkedUrl.resourceSpecifier.componentsSeparatedByString("?")
            if (rawURLparts.count > 2) {
                
            } else {
                let defaultRecipient = rawURLparts[0]
                if defaultRecipient.characters.count > 0 { //default to
                    if defaultRecipient.isValidEmail() {
                        latestComposerViewModel?.addToContacts(ContactVO(name: defaultRecipient, email: defaultRecipient))
                    }
                    PMLog.D("to: \(defaultRecipient)")
                }
                
                if (rawURLparts.count == 2) {
                    let queryString = rawURLparts[1]
                    let params = queryString.componentsSeparatedByString("&")
                    for param in params {
                        var keyValue = param.componentsSeparatedByString("=")
                        if (keyValue.count != 2) {
                            continue;
                        }
                        let key = keyValue[0].lowercaseString
                        var value = keyValue[1] ?? ""
                        value = value.stringByRemovingPercentEncoding ?? ""
                        if key == "subject" {
                            PMLog.D("subject: \(value)")
                            latestComposerViewModel?.setSubject(value)
                        }
                        
                        if key == "body" {
                            PMLog.D("body: \(value)")
                            latestComposerViewModel?.setBody(value)
                        }
                        
                        if key == "to" {
                            PMLog.D("to: \(value)")
                            if value.isValidEmail() {
                                latestComposerViewModel?.addToContacts(ContactVO(name: value, email: value))
                            }
                        }
                        
                        if key == "cc" {
                            PMLog.D("cc: \(value)")
                            if value.isValidEmail() {
                                latestComposerViewModel?.addCcContacts(ContactVO(name: value, email: value))
                            }
                        }
                        
                        if key == "bcc" {
                            PMLog.D("bcc: \(value)")
                            if value.isValidEmail() {
                                latestComposerViewModel?.addBccContacts(ContactVO(name: value, email: value))
                            }
                        }
                    }
                }
            }
        }
        
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