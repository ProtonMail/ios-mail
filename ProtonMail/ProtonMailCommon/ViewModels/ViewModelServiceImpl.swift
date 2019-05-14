//
//  ViewModelServiceImpl.swift
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
import UICKeyChainStore

//TODO:: move this to coordinator.
//keep this unique
let sharedVMService : ViewModelServiceImpl = ViewModelServiceImpl()
//keep this unique
class ViewModelServiceImpl: ViewModelService {

    private var activeViewControllerNew : ViewModelProtocolBase?
    
    private func setup(composer vmp: ViewModelProtocolBase) {
        self.activeViewControllerNew = vmp
    }
    
    override func signOut() {
        self.resetView()
    }
    
    override func resetView() {
        DispatchQueue.main.async {
            if let actived  = self.activeViewControllerNew {
                actived.inactiveViewModel()
                self.activeViewControllerNew = nil
            }
        }
    }
        
    // msg details
    override func messageDetails(fromList vmp: ViewModelProtocolBase) {
        activeViewControllerNew = vmp
    }
    
    override func messageDetails(fromPush vmp: ViewModelProtocolBase) {
        activeViewControllerNew = vmp
    }
    
    override func mailbox(fromMenu vmp : ViewModelProtocolBase) {
        if let oldVC = activeViewControllerNew {
            oldVC.inactiveViewModel()
        }
        activeViewControllerNew = vmp
    }
    
    override func labelbox(fromMenu vmp : ViewModelProtocolBase, label: Label) -> Void {
        if let oldVC = activeViewControllerNew {
            oldVC.inactiveViewModel()
        }
    }
    //contacts
    override func contactsViewModel(_ vmp: ViewModelProtocolBase) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactsViewModelImpl())
    }
    
    override func contactDetailsViewModel(_ vmp: ViewModelProtocolBase, contact: Contact!) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactDetailsViewModelImpl(c: contact))
    }
    
    override func contactAddViewModel(_ vmp: ViewModelProtocolBase) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactAddViewModelImpl())
    }
    
    override func contactAddViewModel(_ vmp: ViewModelProtocolBase, contactVO: ContactVO!) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactAddViewModelImpl(contactVO: contactVO))
    }
    
    override func contactEditViewModel(_ vmp: ViewModelProtocolBase, contact: Contact!) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactEditViewModelImpl(c: contact))
    }
    
    override func contactTypeViewModel(_ vmp : ViewModelProtocolBase, type: ContactEditTypeInterface) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactTypeViewModelImpl(t: type))
    }
    
    override func contactSelectContactGroupsViewModel(_ vmp: ViewModelProtocolBase,
                                                      groupCountInformation: [(ID: String, name: String, color: String, count: Int)],
                                                      selectedGroupIDs: Set<String>,
                                                      refreshHandler: @escaping (Set<String>) -> Void) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactGroupMutiSelectViewModelImpl(groupCountInformation: groupCountInformation,
                                                             selectedGroupIDs: selectedGroupIDs,
                                                             refreshHandler: refreshHandler))
    }
    
    // contact groups
    override func contactGroupsViewModel(_ vmp: ViewModelProtocolBase) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactGroupsViewModelImpl())
    }
    
    override func contactGroupDetailViewModel(_ vmp: ViewModelProtocolBase,
                                              groupID: String,
                                              name: String,
                                              color: String,
                                              emailIDs: Set<Email>) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactGroupDetailViewModelImpl(groupID: groupID,
                                                         name: name,
                                                         color: color,
                                                         emailIDs: emailIDs))
    }
    
    override func contactGroupEditViewModel(_ vmp : ViewModelProtocolBase,
                                            state: ContactGroupEditViewControllerState,
                                            groupID: String? = nil,
                                            name: String? = nil,
                                            color: String? = nil,
                                            emailIDs: Set<Email> = Set<Email>()) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactGroupEditViewModelImpl(state: state,
                                                       groupID: groupID,
                                                       name: name,
                                                       color: color,
                                                       emailIDs: emailIDs))
    }
    
    override func contactGroupSelectColorViewModel(_ vmp: ViewModelProtocolBase,
                                                   currentColor: String,
                                                   refreshHandler: @escaping (String) -> Void) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactGroupSelectColorViewModelImpl(currentColor: currentColor,
                                                              refreshHandler: refreshHandler))
    }
    
    override func contactGroupSelectEmailViewModel(_ vmp: ViewModelProtocolBase,
                                                   selectedEmails: Set<Email>,
                                                   refreshHandler: @escaping (Set<Email>) -> Void) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactGroupSelectEmailViewModelImpl(selectedEmails: selectedEmails,
                                                              refreshHandler: refreshHandler))
    }
    
    // composer

    
    func buildTerms(_ base : ViewModelProtocolBase) {
        let model = TermsWebViewModelImpl()
        base.setModel(vm: model)
    }
    
    func buildPolicy(_ base : ViewModelProtocolBase) {
        let model = PolicyWebViewModelImpl()
        base.setModel(vm: model)
    }
    
    /////////////////
    override func upgradeAlert(contacts vmp: ViewModelProtocolBase) {
        vmp.setModel(vm: ContactAlertViewModelImpl())
    }
    override func upgradeAlert(signature vmp: ViewModelProtocolBase) {
        vmp.setModel(vm: SignatureAlertViewModelImpl())
    }
    
    
    
    
    //TODO::fixme
    override func cleanLegacy() {
        //get current cache version
        let currentVersion = UserDefaultsSaver<Int>(key: AppCache.Key.cacheVersion).get()
        if currentVersion > 0 && currentVersion < 98 {
            sharedCoreDataService.cleanLegacy()//clean core data
            
            //get default sharedbased
            let oldDefault = UserDefaults.standard
            
            //keychain part
            oldDefault.removeObject(forKey: "keychainStoreKey")
            UICKeyChainStore.removeItem(forKey: "keychainStoreKey")
            
            oldDefault.removeObject(forKey: "UserTempCachedStatusKey")
            UICKeyChainStore.removeItem(forKey: "UserTempCachedStatusKey")
            
            oldDefault.synchronize()
        }
    }
    
}
