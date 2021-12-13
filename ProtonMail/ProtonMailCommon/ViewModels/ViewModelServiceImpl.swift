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


//TODO:: move this to coordinator.
//keep this unique
let sharedVMService: ViewModelServiceImpl = ViewModelServiceImpl(coreDataService: sharedServices.get(by: CoreDataService.self))
//keep this unique
class ViewModelServiceImpl {
    private let coreDataService: CoreDataService
    private var activeViewControllerNew : ViewModelProtocolBase?
    
    private func setup(composer vmp: ViewModelProtocolBase) {
        self.activeViewControllerNew = vmp
    }
    
    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
    }
    
    func signOut() {
        self.resetView()
    }
    
    func resetView() {
        DispatchQueue.main.async {
            if let actived  = self.activeViewControllerNew {
                actived.inactiveViewModel()
                self.activeViewControllerNew = nil
            }
        }
    }
        
    // msg details
    func messageDetails(fromList vmp: ViewModelProtocolBase) {
        activeViewControllerNew = vmp
    }
    
    func messageDetails(fromPush vmp: ViewModelProtocolBase) {
        activeViewControllerNew = vmp
    }
    
    func mailbox(fromMenu vmp : ViewModelProtocolBase) {
        if let oldVC = activeViewControllerNew {
            oldVC.inactiveViewModel()
        }
        activeViewControllerNew = vmp
    }
    
    func labelbox(fromMenu vmp : ViewModelProtocolBase, label: Label) -> Void {
        if let oldVC = activeViewControllerNew {
            oldVC.inactiveViewModel()
        }
    }
    //contacts
    func contactsViewModel(_ vmp: ViewModelProtocolBase, user: UserManager) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactsViewModelImpl(user: user, coreDataService: self.coreDataService))
    }
    
    func contactDetailsViewModel(_ vmp: ViewModelProtocolBase, user: UserManager, contact: Contact!) {
        activeViewControllerNew = vmp
        let viewModel = ContactDetailsViewModelImpl(contact: contact, user: user, coreDateService: self.coreDataService)
        vmp.setModel(vm: viewModel)
    }
    
    func contactAddViewModel(_ vmp: ViewModelProtocolBase, user: UserManager) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactAddViewModelImpl(user: user, coreDataService: self.coreDataService))
    }
    
    func contactAddViewModel(_ vmp: ViewModelProtocolBase, user: UserManager, contactVO: ContactVO!) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactAddViewModelImpl(contactVO: contactVO, user: user, coreDataService: self.coreDataService))
    }
    
    func contactEditViewModel(_ vmp: ViewModelProtocolBase, user: UserManager, contact: Contact!) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactEditViewModelImpl(c: contact, user: user, coreDataService: self.coreDataService))
    }
    
    func contactTypeViewModel(_ vmp : ViewModelProtocolBase, type: ContactEditTypeInterface) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactTypeViewModelImpl(t: type))
    }
    
    func contactSelectContactGroupsViewModel(_ vmp: ViewModelProtocolBase,
                                                      user: UserManager,
                                                      groupCountInformation: [(ID: String, name: String, color: String, count: Int)],
                                                      selectedGroupIDs: Set<String>,
                                                      refreshHandler: @escaping (Set<String>) -> Void) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactGroupMutiSelectViewModelImpl(user: user, coreDateService: CoreDataService.shared,
                                                             groupCountInformation: groupCountInformation,
                                                             selectedGroupIDs: selectedGroupIDs,
                                                             refreshHandler: refreshHandler))
    }
    
    // contact groups
    func contactGroupsViewModel(_ vmp: ViewModelProtocolBase, user: UserManager) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactGroupsViewModelImpl(user: user, coreDataService: self.coreDataService))
    }
    
    func contactGroupDetailViewModel(_ vmp: ViewModelProtocolBase,
                                              user: UserManager,
                                              groupID: String,
                                              name: String,
                                              color: String,
                                              emailIDs: Set<Email>) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactGroupDetailViewModelImpl(user: user,
                                                         groupID: groupID,
                                                         name: name,
                                                         color: color,
                                                         emailIDs: emailIDs,
                                                         labelsDataService: user.labelService))
    }
    
    func contactGroupEditViewModel(_ vmp : ViewModelProtocolBase,
                                            user: UserManager,
                                            state: ContactGroupEditViewControllerState,
                                            groupID: String? = nil,
                                            name: String? = nil,
                                            color: String? = nil,
                                            emailIDs: Set<Email> = Set<Email>()) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactGroupEditViewModelImpl(state: state,
                                                       user: user,
                                                       groupID: groupID,
                                                       name: name,
                                                       color: color,
                                                       emailIDs: emailIDs))
    }
    
    func contactGroupSelectColorViewModel(_ vmp: ViewModelProtocolBase,
                                                   currentColor: String,
                                                   refreshHandler: @escaping (String) -> Void) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactGroupSelectColorViewModelImpl(currentColor: currentColor,
                                                              refreshHandler: refreshHandler))
    }
    
    func contactGroupSelectEmailViewModel(_ vmp: ViewModelProtocolBase,
                                                   user: UserManager,
                                                   selectedEmails: Set<Email>,
                                                   refreshHandler: @escaping (Set<Email>) -> Void) {
        activeViewControllerNew = vmp
        vmp.setModel(vm: ContactGroupSelectEmailViewModelImpl(selectedEmails: selectedEmails,
                                                              contactService: user.contactService,
                                                              refreshHandler: refreshHandler))
    }
    
    //TODO::fixme
    func cleanLegacy() {
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
