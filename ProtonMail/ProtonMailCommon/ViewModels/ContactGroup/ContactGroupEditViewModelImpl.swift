//
//  ContactGroupEditViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/21.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

/*
 TODO:
 
 Use the return value (confirmation) of the API call to update the view model
 Currently, the code updates it locally without considering if the API call is successfully or not
 */
class ContactGroupEditViewModelImpl: ContactGroupEditViewModel {
    var state: ContactGroupEditViewControllerState
    var contactGroup: ContactGroup
    var tableContent: [[ContactGroupTableCellType]]
    var allEmails: [Email]
    var delegate: ContactGroupEditViewModelDelegate!
    
    /* Setup code */
    init(state: ContactGroupEditViewControllerState = .create,
         contactGroupID: String? = nil)
    {
        self.state = state
        self.contactGroup = ContactGroup(ID: contactGroupID)
        
        self.tableContent = []
        self.allEmails = sharedContactDataService.allEmails()
        
        resetTableContent()
    }
    
    func resetTableContent() {
        self.tableContent = [
            [.selectColor],
            [.manageContact],
        ]
        if self.state == .edit {
            self.tableContent.append([.deleteGroup])
        }
    }
    
    func tableContent(addEmailWithCount: Int) {
        for _ in 0..<addEmailWithCount {
            self.tableContent[1].append(.email)
        }
    }
    
    func getViewTitle() -> String {
        switch state {
        case .create:
            return "Create contact group"
        case .edit:
            return "Edit contact group"
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
    
    func getContactGroupID() -> String {
        if state == .edit {
            if let ID = contactGroup.ID {
                return ID
            }
        }
        return ""
    }
    
    func getCurrentColor() -> String? {
        return self.contactGroup.color
    }
    
    func getCurrentColorWithDefault() -> String {
        if let c = getCurrentColor() {
            return c
        }
        return "#7272a7"
    }
    
    func getEmailIDsInContactGroup() -> NSMutableSet {
        let result = NSMutableSet()
        if let emailIDs = contactGroup.emailIDs {
            result.addingObjects(from: emailIDs)
        }
        return result
    }
    
    /* Data operation */
    func fetchContactGroupEmailList() {
        if state == .edit {
            if let contactGroupID = contactGroup.ID {
                let completionHandler = {
                    (emailList: [[String: Any]]) -> Void in
                    
                    print("email list \(emailList)")
                    var list: [String] = [String]()
                    for email in emailList {
                        if let emailID = email["ID"] as? String {
                            list.append(emailID)
                        } else {
                            fatalError("API result decoding error")
                        }
                    }
                    
                    if list.count > 0 {
                        self.contactGroup.emailIDs = list
                    }
                    
                    self.resetTableContent()
                    self.tableContent(addEmailWithCount: list.count)
                    
                    self.delegate.update()
                }
                
                sharedContactGroupsDataService.fetchContactGroupEmailList(groupID: contactGroupID,
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
            
            self.delegate.update()
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
            
            self.delegate.update()
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
        
        // update email IDs
        let toRemove = contactGroup.emailIDs?.filter({
            if editedContactGroup.emailIDs == nil {
                return true
            }
            return editedContactGroup.emailIDs!.contains($0) == false
        })
        
        let toAdd = editedContactGroup.emailIDs?.filter({
            if contactGroup.emailIDs == nil {
                return true
            }
            return contactGroup.emailIDs!.contains($0) == false
        })
        
        if let data = toRemove {
            removeEmailsFromContactGroup(emailList: data)
        }
        if let data = toAdd {
            addEmailsToContactGroup(emailList: data)
        }
        
        contactGroup.emailIDs = editedContactGroup.emailIDs
    }
    
    func deleteContactGroup() {
        let completionHandler = {
            () -> Void in
            
            self.contactGroup = ContactGroup()
            self.delegate.update()
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
    
    func updateColor(newColor: String?) {
        if newColor == nil {
            // TODO: use default
        } else {
            contactGroup.color = newColor
        }
        
        self.delegate.update()
    }
    
    /* table operation */
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
    
    /**
     Returns the email data at the designated indexPath
     
     - Parameter indexPath: the indexPath that is asking for data
     - Returns: a tuple of email name and email address
     */
    func getEmail(at indexPath: IndexPath) -> (String, String) {
        // TODO: precondition, all emails must be new enough!
        
        let index = indexPath.row - 1
        guard contactGroup.emailIDs != nil else {
            fatalError("Calculation error")
        }
        guard index < contactGroup.emailIDs!.count else {
            fatalError("Calculation error")
        }
        
        for email in allEmails {
            print("email \(email.emailID)")
            print("contact group emailID \(contactGroup.emailIDs![index])")
            if email.emailID == contactGroup.emailIDs![index] {
                return (email.name, email.email)
            }
        }
        
        fatalError("Invalid email ID error")
        return ("Error", "Error")
    }
}
