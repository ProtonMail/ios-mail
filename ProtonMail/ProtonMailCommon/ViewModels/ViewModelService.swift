//
//  ViewModelService.swift
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

// this is abstract ViewModel service for tracking the ui flow
class ViewModelService : Service {
    
    func changeIndex() {
        fatalError("This method must be overridden")
    }
 
    //messgae detail part
    func messageDetails(fromList vmp : ViewModelProtocolBase) -> Void {
        fatalError("This method must be overridden")
    }
    func messageDetails(fromPush vmp : ViewModelProtocolBase) -> Void {
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
    func contactsViewModel(_ vmp : ViewModelProtocolBase, user: UserManager) {
        fatalError("This method must be overridden")
    }
    
    func contactDetailsViewModel(_ vmp : ViewModelProtocolBase, user: UserManager, contact: Contact!) {
        fatalError("This method must be overridden")
    }
    
    func contactAddViewModel(_ vmp : ViewModelProtocolBase, user: UserManager) {
        fatalError("This method must be overridden")
    }
    
    func contactAddViewModel(_ vmp : ViewModelProtocolBase, user: UserManager, contactVO: ContactVO!) {
        fatalError("This method must be overridden")
    }
    
    func contactEditViewModel(_ vmp : ViewModelProtocolBase, user: UserManager, contact: Contact!) {
        fatalError("This method must be overridden")
    }
    
    func contactTypeViewModel(_ vmp : ViewModelProtocolBase, type: ContactEditTypeInterface) {
        fatalError("This method must be overridden")
    }
    
    func contactSelectContactGroupsViewModel(_ vmp: ViewModelProtocolBase,
                                             user: UserManager,
                                             groupCountInformation: [(ID: String, name: String, color: String, count: Int)],
                                             selectedGroupIDs: Set<String>,
                                             refreshHandler: @escaping (Set<String>) -> Void) {
        fatalError("This method must be overridden")
    }
    
    // contact groups
    func contactGroupsViewModel(_ vmp: ViewModelProtocolBase,
                                user: UserManager) {
        fatalError("This method must be overridden")
    }
    
    func contactGroupDetailViewModel(_ vmp: ViewModelProtocolBase,
                                     user: UserManager,
                                     groupID: String,
                                     name: String,
                                     color: String,
                                     emailIDs: Set<Email>) {
        fatalError("This method must be overridden")
    }
    
    func contactGroupEditViewModel(_ vmp: ViewModelProtocolBase,
                                   user: UserManager,
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
                                          user: UserManager,
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

