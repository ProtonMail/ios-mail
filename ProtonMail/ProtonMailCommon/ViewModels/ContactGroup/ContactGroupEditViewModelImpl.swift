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
    var refreshHandler: () -> Void
    var tableContent: [[ContactGroupTableCellType]]
    
    init(state: ContactGroupEditViewControllerState = .create,
         contactGroupID: String? = nil,
         name: String? = nil,
         color: String? = nil,
         refreshHandler: @escaping () -> Void)
    {
        self.state = state
        self.contactGroup = ContactGroup(ID: contactGroupID, name: name, color: color)
        self.refreshHandler = refreshHandler
        self.tableContent = [
            [.selectColor],
            [.manageContact],
            [.deleteGroup]
        ]
    }
    
    func getViewTitle() -> String {
        switch state {
        case .create:
            return "[Locale] Create contact group"
        case .edit:
            return "[Locale] Edit contact group"
        }
    }
    
    func getContactGroupName() -> String {
        if state == .edit {
            if let groupName = contactGroup.name {
                return groupName
            }
        }
        return ""
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
                    
                    self.contactGroup = ContactGroup(ID: contactGroupID,
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
            
            self.refreshHandler()
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
        let completionHandler = {
            () -> Void in
            
            self.contactGroup.ID = editedContactGroup.ID
            self.contactGroup.name = editedContactGroup.name
            self.contactGroup.color = editedContactGroup.color
            
            self.refreshHandler()
        }
        
        // update contact group
        if let groupID = editedContactGroup.ID,
            let name = editedContactGroup.name,
            let color = editedContactGroup.color {
            sharedContactGroupsDataService.editContactGroup(groupID: groupID,
                                                            name: name,
                                                            color: color,
                                                            completionHandler: completionHandler)
        } else {
            PMLog.D("[Contact Group API] not enough valid argument for creating the contact group = \(editedContactGroup)")
        }
        
        // TODO: do local diffing, opt. API call
        // update email IDs
        if let emailList = contactGroup.emailIDs {
            removeEmailsFromContactGroup(emailList: emailList)
        }
        
        if let emailList = editedContactGroup.emailIDs {
            addEmailsToContactGroup(emailList: emailList)
        }
    }
    
    func deleteContactGroup() {
        let completionHandler = {
            () -> Void in
            
            self.contactGroup = ContactGroup()
            self.refreshHandler()
        }
        
        if let contactGroupID = contactGroup.ID {
            sharedContactGroupsDataService.deleteContactGroup(groupID: contactGroupID, completionHandler: completionHandler)
        } else {
            PMLog.D("[Contact Group API] error deleting the contact group = \(self.contactGroup)")
        }
    }
    
    func addEmailsToContactGroup(emailList: [String]) {
        let completionHandler = {
            () -> Void in
            
            if self.contactGroup.emailIDs == nil {
                self.contactGroup.emailIDs = [String]()
            }
            
            for email in emailList {
                if self.contactGroup.emailIDs!.contains(email) == false {
                    self.contactGroup.emailIDs!.append(email)
                }
            }
        }
        
        if let contactGroupID = contactGroup.ID {
            sharedContactGroupsDataService.addEmailsToContactGroup(groupID: contactGroupID,
                                                                   emailList: emailList,
                                                                   completionHandler: completionHandler)
        }
    }
    
    func removeEmailsFromContactGroup(emailList: [String]) {
        let completionHandler = {
            () -> Void in
            
            guard self.contactGroup.emailIDs != nil else {
                return
            }
            
            self.contactGroup.emailIDs = self.contactGroup.emailIDs!.filter({
                if emailList.contains($0) {
                    return false
                }
                return true
            })
            
            if self.contactGroup.emailIDs!.count == 0 {
                self.contactGroup.emailIDs = nil
            }
        }
        
        if let contactGroupID = contactGroup.ID {
            sharedContactGroupsDataService.removeEmailsFromContactGroup(groupID: contactGroupID,
                                                                        emailList: emailList,
                                                                        completionHandler: completionHandler)
        }
    }
    
    // table
    func getTotalSections() -> Int {
        return self.tableContent.count
    }
    
    func getTotalRows(for section: Int) -> Int {
        guard section < tableContent.count else {
            return 0
        }
        
        return tableContent[section].count
    }
    
    func getCellType(at indexPath: IndexPath) -> ContactGroupTableCellType {
        guard indexPath.section < tableContent.count &&
            indexPath.row < tableContent[indexPath.section].count else {
                return .error
        }
        
        return tableContent[indexPath.section][indexPath.row]
    }
}
