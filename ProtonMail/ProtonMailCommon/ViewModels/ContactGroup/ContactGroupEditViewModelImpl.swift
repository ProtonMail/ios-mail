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
    var contactGroupEditViewDelegate: ContactGroupsViewModelDelegate!
    
    init(state: ContactGroupEditViewControllerState = .create, contactGroupID: String? = nil, color: String? = nil)
    {
        self.state = state
        self.contactGroup = ContactGroup(ID: contactGroupID, color: color)
    }
    
    func fetchContactGroupDetail() {
        if state == .edit {
            if let contactGroupID = contactGroup.ID {
                let completionHandler = {
                    (fetchedData: [String: Any]) -> Void in
                    
                    var emailList: [String] = [String]()
                    if let contactEmails = fetchedData["ContactEmails"] as? [[String: Any]] {
                        for record in contactEmails {
                            emailList.append(String(describing: record["ID"]))
                        }
                    }
                    
                    self.contactGroup = ContactGroup(ID: self.contactGroup.ID,
                                                     name: String(describing: fetchedData["Name"]),
                                                     color: self.contactGroup.color,
                                                     emailIDs: emailList.count > 0 ? emailList : nil)
                    
                    self.contactGroupEditViewDelegate.updated()
                }
                
                sharedContactGroupsDataService.fetchContactGroupDetail(groupID: contactGroupID,
                                                                       completionHandler: completionHandler)
            } else {
                PMLog.D("[Contact Group API] contact group ID is nil = \(contactGroup)")
            }
        }
    }
    
    func getContactGroupDetail() -> ContactGroup {
        return self.contactGroup
    }
    
    func saveContactGroupDetail(name: String?, color: String?, emailList: [String]?) {
        switch state {
        case .create:
            let data = ContactGroup(name: name, color: color, emailIDs: emailList)
            createContactGroupDetail(newContactGroup: data)
        case .edit:
            let data = ContactGroup(ID: contactGroup.ID,
                                    name: name ?? contactGroup.name,
                                    color: color ?? contactGroup.color,
                                    emailIDs: emailList ?? contactGroup.emailIDs)
            updateContactGroupDetail(editedContactGroup: data)
        }
    }
    
    private func createContactGroupDetail(newContactGroup: ContactGroup) {
        let completionHandler = {
            (createdContactGroup: [String: Any]) -> Void in
            
            let ID = String(describing: createdContactGroup["ID"])
            let name = String(describing: createdContactGroup["Name"])
            let color = String(describing: createdContactGroup["Color"])
            
            self.contactGroup.ID = ID
            self.contactGroup.name = name
            self.contactGroup.color = color
        }
        
        // create contact group
        if let name = newContactGroup.name, let color = newContactGroup.color {
            sharedContactGroupsDataService.addContactGroup(name: name,
                                                           color: color,
                                                           completionHandler: completionHandler)
        } else {
            PMLog.D("[Contact Group API] not enough valid argument for creating the contact group = \(newContactGroup)")
        }
        
        // add email IDs
        if let emailList = newContactGroup.emailIDs {
            addEmailsToContactGroup(emailList: emailList)
        }
    }
    
    private func updateContactGroupDetail(editedContactGroup: ContactGroup) {
        
    }
    
    func deleteContactGroup() {
        
    }
    
    func addEmailsToContactGroup(emailList: [String]) {
        
    }
    
    func removeEmailsFromContactGroup(emailList: [String]) {
        
    }
}
