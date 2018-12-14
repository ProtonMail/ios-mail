//
//  ViewModelService.swift
//  ProtonMail - Created on 6/18/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
    
    func newDraft(vmp: ViewModelProtocolBase, with group: ContactGroupVO) {
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
    func mailbox(fromMenu vmp : ViewModelProtocolBase) {
        fatalError("This method must be overridden")
    }
    
    func labelbox(fromMenu vmp : ViewModelProtocolBase, label: Label) -> Void {
        fatalError("This method must be overridden")
    }
    
    func resetView() {
        fatalError("This method must be overridden")
    }
    
    //contacts
    func contactsViewModel(_ vmp : ViewModelProtocolBase) {
        fatalError("This method must be overridden")
    }
    
    func contactDetailsViewModel(_ vmp : ViewModelProtocolBase, contact: Contact!) {
        fatalError("This method must be overridden")
    }
    
    func contactAddViewModel(_ vmp : ViewModelProtocolBase) {
        fatalError("This method must be overridden")
    }
    
    func contactAddViewModel(_ vmp : ViewModelProtocolBase, contactVO: ContactVO!) {
        fatalError("This method must be overridden")
    }
    
    func contactEditViewModel(_ vmp : ViewModelProtocolBase, contact: Contact!) {
        fatalError("This method must be overridden")
    }
    
    func contactTypeViewModel(_ vmp : ViewModelProtocol, type: ContactEditTypeInterface) {
        fatalError("This method must be overridden")
    }
    
    func contactSelectContactGroupsViewModel(_ vmp: ViewModelProtocolBase,
                                             groupCountInformation: [(ID: String, name: String, color: String, count: Int)],
                                             selectedGroupIDs: Set<String>,
                                             refreshHandler: @escaping (Set<String>) -> Void) {
        fatalError("This method must be overridden")
    }
    
    // contact groups
    func contactGroupsViewModel(_ vmp: ViewModelProtocolBase) {
        fatalError("This method must be overridden")
    }
    
    func contactGroupDetailViewModel(_ vmp: ViewModelProtocolBase,
                                     groupID: String,
                                     name: String,
                                     color: String,
                                     emailIDs: Set<Email>) {
        fatalError("This method must be overridden")
    }
    
    func contactGroupEditViewModel(_ vmp: ViewModelProtocolBase,
                                   state: ContactGroupEditViewControllerState,
                                   groupID: String? = nil,
                                   name: String? = nil,
                                   color: String? = nil,
                                   emailIDs: Set<Email> = Set<Email>()) {
        fatalError("This method must be overridden")
    }
    
    func contactGroupSelectColorViewModel(_ vmp: ViewModelProtocolBase,
                                          currentColor: String,
                                          refreshHandler: @escaping (String) -> Void) {
        fatalError("This method must be overridden")
    }
    
    func contactGroupSelectEmailViewModel(_ vmp: ViewModelProtocolBase,
                                          selectedEmails: Set<Email>,
                                          refreshHandler: @escaping (Set<Email>) -> Void) {
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

