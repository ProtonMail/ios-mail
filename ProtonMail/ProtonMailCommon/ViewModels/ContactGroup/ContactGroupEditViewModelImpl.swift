//
//  ContactGroupEditViewModelImpl.swift
//  ProtonMail - Created on 2018/8/21.
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
import PromiseKit

/*
 TODO:
 
 1. Use the return value (confirmation) of the API call to update the view model. Currently, the code updates it locally without considering if the API call is successfully or not
 */
class ContactGroupEditViewModelImpl: ContactGroupEditViewModel {
    /// the state of the controller, can only be either create or edit
    var state: ContactGroupEditViewControllerState
    
    /// the contact group data
    var contactGroup: ContactGroupData {
        didSet {
            prepareEmails()
        }
    }
    
    /// all of the emails in the contact group
    /// not using NSSet so the tableView can easily get access to a specific row
    var emailsInGroup: [Email]
    
    /// this array structures the layout of the tableView in ContactGroupEditViewController
    var tableContent: [[ContactGroupEditTableCellType]]
    
    /// this array holds the section titles for the tableView
    var tableSectionTitle: [String]
    
    /// for updating the ContactGroupEditViewController
    weak var delegate: ContactGroupEditViewControllerDelegate? = nil
    
    private(set) var user: UserManager
    var contactGroupService : ContactGroupsDataService
    
    /**
     Setup the view model
     */
    init(state: ContactGroupEditViewControllerState = .create,
         user: UserManager,
         groupID: String? = nil,
         name: String?,
         color: String?,
         emailIDs: Set<Email>) {
        self.state = state
        self.emailsInGroup = []
        self.tableContent = []
        self.tableSectionTitle = []
        self.contactGroup = ContactGroupData(ID: groupID,
                                             name: name,
                                             color: color,
                                             emailIDs: emailIDs)
        self.user = user
        self.contactGroupService = user.contactGroupService
        prepareEmails()
    }
    
    /**
     Reset the tableView content to basic elements only
     
     This is called automatically in the updateTableContent(emailCount:)
     */
    private func resetTable() {
        // content
        self.tableContent = [
            [.manageContact],
            []
        ]
        
        if self.state == .edit {
            self.tableContent.append([.deleteGroup])
        }
        
        // title
        self.tableSectionTitle = [
            "",
            "",
            ""
        ]
        
        if self.state == .edit {
            self.tableSectionTitle.append("")
        }
    }
    
    /**
     Add email fields to the tableContent array
     
     - Parameter emailCount: the email fields to be added to the tableContent array
     */
    private func updateTableContent(emailCount: Int) {
        resetTable()
        
        for _ in 0..<emailCount {
            self.tableContent[1].append(.email)
        }
        
        if emailCount == 1 {
            tableSectionTitle[1] = String.init(format: LocalString._contact_groups_member_count_description,
                                               emailCount)
        } else if emailCount > 1 {
            tableSectionTitle[1] = String.init(format: LocalString._contact_groups_members_count_description,
                                               emailCount)
        } else { // 0, don't show
            tableSectionTitle[1] = ""
        }
    }
    
    /**
     Load email content and prepare the tableView for displaying them
     */
    private func prepareEmails() {
        self.emailsInGroup = contactGroup.emailIDs.map{$0}
        self.emailsInGroup.sort {
            if $0.name == $1.name {
                return $0.email < $1.email
            }
            return $0.name < $1.name
        }
        
        // update
        updateTableContent(emailCount: self.emailsInGroup.count)
        self.delegate?.update()
    }
    
    /**
     - Parameter name: The name of the contact group to be set to
     
     // TODO: bundle it with the textField delegate, so we can keep the contactGroup status up-to-date
     */
    func setName(name: String)
    {
        if name.count == 0 {
            contactGroup.name = nil
        } else {
            contactGroup.name = name
        }
    }
    
    /**
     - Parameter color: The color of the contact group to be set to. Notice that is the color is nil, the default color will be used
     */
    func setColor(newColor: String) {
        contactGroup.color = newColor
        self.delegate?.update()
    }
    
    /**
     - Parameter emails: Set the emails that will be in the contact group
     */
    func setEmails(emails: Set<Email>)
    {
        contactGroup.emailIDs = emails
    }
    
    /**
     Remove an email from the listing in the contact group.
     */
    func removeEmail(emailID: String) {
        for emailObj in emailsInGroup {
            if emailObj.emailID == emailID {
                // remove email from set
                contactGroup.emailIDs.remove(emailObj)
                prepareEmails()
                return
            }
        }
        
        // TODO: handle error
        PMLog.D("FatalError: Email to delete doesn't exist")
    }
    
    /**
     - Returns: the title for the ContactGroupEditViewController
     */
    func getViewTitle() -> String {
        switch state {
        case .create:
            return LocalString._contact_groups_add
        case .edit:
            return LocalString._contact_groups_edit
        }
    }
    
    /**
     - Returns: the contact group name
     */
    func getName() -> String {
        return contactGroup.name ?? ""
    }
    
    /**
     - Returns: the contact group ID
     */
    func getContactGroupID() -> String? {
        if state == .create {
            return nil
        }
        return contactGroup.ID
    }
    
    /**
     - Returns: the color of the contact group
     */
    func getColor() -> String {
        return contactGroup.color
    }
    
    /**
     - Returns: the emails in the contact group
     */
    func getEmails() -> Set<Email> {
        return contactGroup.emailIDs
    }
    
    /**
     - Returns: the section title
     */
    func getSectionTitle(for section: Int) -> String {
        guard section < tableSectionTitle.count else {
            return ""
        }
        return tableSectionTitle[section]
    }
    
    /* Data operation */
    
    /**
     Saves the contact group to the server and cache
     
     This function will perform data checking,
     and it will decide which function to call for create/update
     
     - Parameters:
     - name: The contact group's name
     - color: The contact group's color
     - emailList: Emails that belongs to this contact group
     
     - Returns: Promise<Void>
     */
    func saveDetail() -> Promise<Void> {
        return firstly {
            () -> Promise<Void> in
            let (promise, seal) = Promise<Void>.pending()
            
            // error check
            guard self.contactGroup.name != nil else {
                seal.reject(ContactGroupEditError.noNameForGroup)
                return promise
            }
            
            guard self.contactGroup.emailIDs.count > 0 else {
                seal.reject(ContactGroupEditError.noEmailInGroup)
                return promise
            }
            
            seal.fulfill(())
            return promise
            }.then {
                _ -> Promise<Void> in
                // perform
                let name = self.contactGroup.name!
                let color = self.contactGroup.color
                let emails = self.contactGroup.emailIDs
                
                switch self.state {
                case .create:
                    return self.createContactGroupDetail(name: name,
                                                         color: color,
                                                         emailList: emails)
                case .edit:
                    return self.updateContactGroupDetail(name: name,
                                                         color: color,
                                                         updatedEmailList: emails)
                }
        }
    }
    
    /**
     Returns true if the contact group is modified
     */
    func hasUnsavedChanges() -> Bool {
        return self.contactGroup.hasChanged()
    }
    
    /**
     Creates the contact group on the server and cache
     
     - Parameters:
     - name: The contact group's name
     - color: The contact group's color
     - emailList: Emails that belongs to this contact group
     
     - Returns: Promise<Void>
     */
    private func createContactGroupDetail(name: String,
                                          color: String,
                                          emailList: Set<Email>) -> Promise<Void> {
        return firstly {
            return self.contactGroupService.createContactGroup(name: name, color: color)
        }.then {
            (ID: String) -> Promise<Void> in
            self.contactGroup.ID = ID
            return self.addEmailsToContactGroup(emailList: emailList)
        }
    }
    
    /**
     Updates the contact group on the server and cache
     
     - Parameters:
     - name: The contact group's name
     - color: The contact group's color
     - emailList: Emails that belongs to this contact group
     
     - Returns: Promise<Void>
     */
    private func updateContactGroupDetail(name: String,
                                          color: String,
                                          updatedEmailList: Set<Email>) -> Promise<Void> {
        
        return firstly {
            () -> Promise<Void> in
            
            if let ID = contactGroup.ID {
                // update contact group
                return self.contactGroupService.editContactGroup(groupID: ID, name: name, color: color)
            } else {
                return Promise.init(error: ContactGroupEditError.TypeCastingError)
            }
        }.then {
            () -> Promise<Void> in
            
            let original = self.contactGroup.originalEmailIDs
            let toAdd = updatedEmailList.subtracting(original)
            return self.addEmailsToContactGroup(emailList: toAdd)
        }.then {
            () -> Promise<Void> in
            
            let original = self.contactGroup.originalEmailIDs
            let toDelete = original.subtracting(updatedEmailList)
            return self.removeEmailsFromContactGroup(emailList: toDelete)
        }
    }
    
    /**
     Deletes the contact group on the server and cache
     
     - Returns: Promise<Void>
     */
    func deleteContactGroup() -> Promise<Void> {
        return firstly {
            () -> Promise<Void> in
            
            if let ID = contactGroup.ID {
                return self.contactGroupService.deleteContactGroup(groupID: ID)
            } else {
                return Promise.init(error: ContactGroupEditError.InternalError)
            }
        }
    }
    
    /**
     Add the current email listing to the contact group on the server
     
     - Parameter emailList: Emails to add to the contact group
     
     - Returns: Promise<Void>
     */
    func addEmailsToContactGroup(emailList: Set<Email>) -> Promise<Void> {
        return firstly {
            () -> Promise<Void> in
            let emails = emailList.map{$0}
            if let ID = contactGroup.ID {
                return self.contactGroupService.addEmailsToContactGroup(groupID: ID, emailList: emails)
            } else {
                return Promise.init(error: ContactGroupEditError.InternalError)
            }
        }
    }
    
    /**
     Delete the current email listing to the contact group on the server
     
     - Parameter emailList: Emails to delete from the contact group
     
     - Returns: Promise<Void>
     */
    func removeEmailsFromContactGroup(emailList: Set<Email>) -> Promise<Void> {
        return firstly {
            () -> Promise<Void> in
            
            let emails = emailList.map{$0}
            if let ID = contactGroup.ID {
                return self.contactGroupService.removeEmailsFromContactGroup(groupID: ID, emailList: emails)
            } else {
                return Promise.init(error: ContactGroupEditError.InternalError)
            }
        }
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
    
    func getCellType(at indexPath: IndexPath) -> ContactGroupEditTableCellType {
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
    func getEmail(at indexPath: IndexPath) -> (String, String, String) {
        let index = indexPath.row
        guard index < emailsInGroup.count else {
            PMLog.D("FatalError: Calculation error")
            return ("", "", "")
        }
        
        return (emailsInGroup[index].emailID, emailsInGroup[index].name, emailsInGroup[index].email)
    }
}
