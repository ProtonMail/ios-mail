//
//  ViewModelServiceImpl.swift
//  ProtonMail - Created on 6/18/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import Keymaker

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
        
        // TODO:: fixme
        let usersManager : UsersManager = sharedServices.get()
        let user = usersManager.firstUser!
        vmp.setModel(vm: ContactDetailsViewModelImpl(c: contact, contact: user.contactService))
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
        //TODO:: fix me
//        vmp.setModel(vm: ContactGroupMutiSelectViewModelImpl(groupCountInformation: groupCountInformation,
//                                                             selectedGroupIDs: selectedGroupIDs,
//                                                             refreshHandler: refreshHandler))
    }
    
    // contact groups
    override func contactGroupsViewModel(_ vmp: ViewModelProtocolBase) {
        //activeViewControllerNew = vmp
        //vmp.setModel(vm: ContactGroupsViewModelImpl())
        //TODO:: fix me
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
        //TODO::fix me
//        vmp.setModel(vm: ContactGroupEditViewModelImpl(state: state, cgroupService: ContactGroupsDataService,
//                                                       groupID: groupID,
//                                                       name: name,
//                                                       color: color,
//                                                       emailIDs: emailIDs))
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
        //TODO:: fix me
        let users : UsersManager = sharedServices.get()
        vmp.setModel(vm: ContactGroupSelectEmailViewModelImpl(selectedEmails: selectedEmails,
                                                              contactService: users.firstUser!.contactService,
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
        guard let currentVersion = UserDefaultsSaver<Int>(key: AppCache.Key.cacheVersion).get() else {
            return
        }
        if currentVersion > 0 && currentVersion < 98 {
            CoreDataService.shared.cleanLegacy()//clean core data
            
            //get default sharedbased
            let oldDefault = UserDefaults.standard
            
            //keychain part
            oldDefault.removeObject(forKey: "keychainStoreKey")
            KeychainWrapper.keychain.remove(forKey: "keychainStoreKey")
            
            oldDefault.removeObject(forKey: "UserTempCachedStatusKey")
            KeychainWrapper.keychain.remove(forKey: "UserTempCachedStatusKey")
            
            oldDefault.synchronize()
        }
    }
    
}
