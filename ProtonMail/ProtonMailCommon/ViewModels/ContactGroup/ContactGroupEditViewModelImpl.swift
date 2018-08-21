//
//  ContactGroupEditViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/21.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class ContactGroupEditViewModelImpl: ContactGroupEditViewModel {
    var state: ContactGroupEditViewControllerState
    var contactGroup: ContactGroup

    init(state: ContactGroupEditViewControllerState = .create, contactGroupID: String?)
    {
        self.state = state
        self.contactGroup = ContactGroup(ID: contactGroupID)
    }
    
    func fetchContactGroupDetail() {
        if state == .edit {
            // TODO: fetch
        }
    }

    func getContactGroupDetail() -> ContactGroup {
        return self.contactGroup
    }

    func addEmailsToContactGroup(emailList: [String]) {
        
    }

    func removeEmailsFromContactGroup(emailList: [String]) {
        
    }

    func saveContactGroupDetail(newContactGroup: ContactGroup) {
        
    }

    func updateContactGroupDetail(editedContactGroup: ContactGroup) {
        
    }

    func deleteContactGroup() {
        
    }
}
