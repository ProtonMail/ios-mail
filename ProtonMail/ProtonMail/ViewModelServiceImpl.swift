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
    
    fileprivate var latestComposerViewModel : ComposeViewModel?
    fileprivate var latestComposerViewController : ViewModelProtocol?
    
    
    override func signOut() {
        self.resetComposerView()
    }
    
    override func changeIndex() {
        
    }
    
    override func resetComposerView() {
        if latestComposerViewController != nil {
            DispatchQueue.main.async {
                self.latestComposerViewController?.inactiveViewModel()
                self.latestComposerViewController = nil
            }
        }
        latestComposerViewModel = nil
    }
    
    override func newDraftViewModel(_ vmp : ViewModelProtocol) {
        if latestComposerViewModel != nil {
            
        }
        
        if latestComposerViewController != nil {
            
        }
        
        latestComposerViewController = vmp
        latestComposerViewModel = ComposeViewModelImpl(msg: nil, action: .newDraft);
        vmp.setViewModel(latestComposerViewModel!)
    }
    
    
    override func newDraftViewModelWithContact(_ vmp : ViewModelProtocol, contact: ContactVO!) {
        if latestComposerViewModel != nil {
            
        }
        
        if latestComposerViewController != nil {
            
        }
        
        latestComposerViewController = vmp
        latestComposerViewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.newDraft);
        latestComposerViewModel?.addToContacts(contact)
        vmp.setViewModel(latestComposerViewModel!)
    }
    
    override func newDraftViewModelWithMailTo(_ vmp: ViewModelProtocol, url: URL?) {
        if latestComposerViewModel != nil {
            
        }
        if latestComposerViewController != nil {
            
        }
        latestComposerViewController = vmp
        latestComposerViewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.newDraft);

        if let mailTo : NSURL = url as NSURL?, mailTo.scheme == "mailto", let resSpecifier = mailTo.resourceSpecifier {
            PMLog.D("\(mailTo)")
            var rawURLparts = resSpecifier.components(separatedBy: "?")
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
                    let params = queryString.components(separatedBy: "&")
                    for param in params {
                        var keyValue = param.components(separatedBy: "=")
                        if (keyValue.count != 2) {
                            continue;
                        }
                        let key = keyValue[0].lowercased()
                        var value = keyValue[1]
                        value = value.removingPercentEncoding ?? ""
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
    
    override func openDraftViewModel(_ vmp : ViewModelProtocol, msg: Message!) {
        if latestComposerViewModel != nil {
            
        }
        
        if latestComposerViewController != nil {
            
        }
        
        latestComposerViewController = vmp
        latestComposerViewModel = ComposeViewModelImpl(msg: msg, action: ComposeMessageAction.openDraft);
        vmp.setViewModel(latestComposerViewModel!)
    }
    
    override func actionDraftViewModel(_ vmp : ViewModelProtocol, msg: Message!, action: ComposeMessageAction) {
        if latestComposerViewModel != nil {
            
        }
        
        if latestComposerViewController != nil {
            
        }
        latestComposerViewController = vmp
        latestComposerViewModel = ComposeViewModelImpl(msg: msg, action: action);
        vmp.setViewModel(latestComposerViewModel!)
    }
    
}
