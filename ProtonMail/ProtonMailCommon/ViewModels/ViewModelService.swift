//
//  ViewModelService.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


// this is abstract ViewModel service for tracking the ui flow
class ViewModelService {
    
    func changeIndex() {
        fatalError("This method must be overridden")
    }
    
    func buildComposer<T: ViewModelProtocolNew>(_ vmp: T, subject: String, content: String, files: [FileData]) {
        fatalError("This method must be overridden")
    }
    
    
    /// NewDraft
    /// init normal new draft viewModel
    /// - Parameter vmp: the ViewController based on ViewModelProtocal
    func newDraft(vmp : ViewModelProtocolBase) {
        fatalError("This method must be overridden")
    }
    
    func newDraft(vmp : ViewModelProtocolBase, with contact: ContactVO?) {
         fatalError("This method must be overridden")
    }
    
    func newDraft(vmp : ViewModelProtocolBase, with mailTo : URL?) {
        fatalError("This method must be overridden")
    }
    
    func openDraft(vmp: ViewModelProtocolBase, with msg: Message!) {
        fatalError("This method must be overridden")
    }
    
    func newDraft(vmp: ViewModelProtocolBase, with msg: Message!, action: ComposeMessageAction) {
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
    
    //contacts
    func contactsViewModel(_ vmp : ViewModelProtocol) {
        fatalError("This method must be overridden")
    }
    
    func contactDetailsViewModel(_ vmp : ViewModelProtocol, contact: Contact!) {
        fatalError("This method must be overridden")
    }
    
    func contactAddViewModel(_ vmp : ViewModelProtocol) {
        fatalError("This method must be overridden")
    }
    
    func contactAddViewModel(_ vmp : ViewModelProtocol, contactVO: ContactVO!) {
        fatalError("This method must be overridden")
    }
    
    func contactEditViewModel(_ vmp : ViewModelProtocol, contact: Contact!) {
        fatalError("This method must be overridden")
    }
    
    func contactTypeViewModel(_ vmp : ViewModelProtocol, type: ContactEditTypeInterface) {
        fatalError("This method must be overridden")
    }
    
    // contact groups
    func contactGroupsViewModel(_ vmp: ViewModelProtocol) {
        fatalError("This method must be overridden")
    }
    
    func contactGroupEditViewModel(_ vmp: ViewModelProtocol,
                                   state: ContactGroupEditViewControllerState,
                                   contactGroupID: String?) {
        fatalError("This method must be overridden")
    }
    
    func contactGroupSelectColorViewModel(_ vmp: ViewModelProtocol,
                                          currentColor: String?,
                                          refreshHandler: @escaping (String?) -> Void) {
        fatalError("This method must be overridden")
    }
    
    func contactGroupSelectEmailViewModel(_ vmp: ViewModelProtocol,
                                          selectedEmails: NSSet,
                                          refreshHandler: @escaping (NSSet) -> Void) {
        fatalError("This method must be overridden")
    }
    
    ///////////////////////
    ///
    func upgradeAlert(signature vmp: ViewModelProtocolBase) {
        fatalError("This method must be overridden")
    }
    ///
    func upgradeAlert(contacts vmp: ViewModelProtocolBase) {
        fatalError("This method must be overridden")
    }
    
    
    //
    func signOut() { }
    func cleanLegacy() {
        //get current version
    }
}

