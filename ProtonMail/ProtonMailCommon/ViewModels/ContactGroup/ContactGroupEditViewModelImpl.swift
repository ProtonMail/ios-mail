//
//  ContactGroupEditViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/21.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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
    var contactGroup: ContactGroupData
    
    /// all of the emails in the contact group
    /// not using NSSet so the tableView can easily get access to a specific row
    var emailsInGroup: [Email]
    
    /// this array structures the layout of the tableView in ContactGroupEditViewController
    var tableContent: [[ContactGroupEditTableCellType]]
    
    /// for updating the ContactGroupEditViewController
    weak var delegate: ContactGroupEditViewControllerDelegate? = nil
    
    /**
     Setup the view model
     */
    init(state: ContactGroupEditViewControllerState = .create,
         groupID: String? = nil,
         name: String?,
         color: String?,
         emailIDs: NSSet) {
        self.state = state
        self.emailsInGroup = []
        self.tableContent = []
        self.contactGroup = ContactGroupData(ID: groupID,
                                             name: name,
                                             color: color,
                                             emailIDs: emailIDs)
        
        self.prepareEmails()
    }
    
    /**
     Reset the tableView content to basic elements only
     
     This is called automatically in the updateTableContent(emailCount:)
     */
    private func resetTableContent() {
        self.tableContent = [
            [.selectColor],
            [.manageContact],
        ]
        
        if self.state == .edit {
            self.tableContent.append([.deleteGroup])
        }
    }
    
    /**
     Add email fields to the tableContent array
     
     - Parameter emailCount: the email fields to be added to the tableContent array
     */
    private func updateTableContent(emailCount: Int) {
        resetTableContent()
        
        for _ in 0..<emailCount {
            self.tableContent[1].append(.email)
        }
    }
    
    private func prepareEmails() {
        // get email as an array
        if let emailIDs = contactGroup.emailIDs.allObjects as? [Email] {
            // sort
            self.emailsInGroup = emailIDs
            self.emailsInGroup.sort {
                if $0.name == $1.name {
                    return $0.email < $1.email
                }
                return $0.name < $1.name
            }
            
            // update
            updateTableContent(emailCount: self.emailsInGroup.count)
        } else {
            // TODO: handle error
            PMLog.D("Can't convert NSSet to [Email]")
        }
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
    func setColor(newColor: String?) {
        contactGroup.color = newColor ?? ColorManager.defaultColor
        self.delegate?.update()
    }
    
    /**
     - Parameter emails: Set the emails that will be in the contact group
     */
    func setEmails(emails: NSSet)
    {
        contactGroup.emailIDs = emails
        
        prepareEmails()
        self.delegate?.update()
    }
    
    /**
     - Returns: the title for the ContactGroupEditViewController
     */
    func getViewTitle() -> String {
        switch state {
        case .create:
            return "Create contact group"
        case .edit:
            return "Edit contact group"
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
    func getEmails() -> NSSet {
        return contactGroup.emailIDs
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
        let (promise, seal) = Promise<Void>.pending()
        
        // error check
        guard contactGroup.name != nil else {
            seal.reject(ContactGroupEditError.noNameForGroup)
            return promise
        }
        
        guard contactGroup.emailIDs.count > 0 else {
            seal.reject(ContactGroupEditError.noEmailInGroup)
            return promise
        }
        
        // TODO: promise
        let name = contactGroup.name!
        let color = contactGroup.color
        let emails = contactGroup.emailIDs
        
        switch state {
        case .create:
            createContactGroupDetail(name: name,
                                     color: color,
                                     emailList: emails)
            seal.fulfill(())
        case .edit:
            updateContactGroupDetail(name: name,
                                     color: color,
                                     updatedEmailList: emails)
            seal.fulfill(())
        }
        
        return promise
    }
    
    /**
     Creates the contact group on the server and cache
     
     - Parameters:
     - name: The contact group's name
     - color: The contact group's color
     - emailList: Emails that belongs to this contact group
     */
    private func createContactGroupDetail(name: String,
                                          color: String,
                                          emailList: NSSet) {
        let completionHandler = {
            (contactGroupID: String?) -> Void in
            
            if let contactGroupID = contactGroupID {
                self.contactGroup.ID = contactGroupID
                
                // add email IDs
                self.addEmailsToContactGroup(emailList: emailList)
            } else {
                // TODO: no contactGroupID check
            }
        }
        
        // create contact group
        sharedContactGroupsDataService.createContactGroup(name: name,
                                                          color: color,
                                                          completionHandler: completionHandler)
    }
    
    /**
     Updates the contact group on the server and cache
     
     - Parameters:
     - name: The contact group's name
     - color: The contact group's color
     - emailList: Emails that belongs to this contact group
     */
    private func updateContactGroupDetail(name: String,
                                          color: String,
                                          updatedEmailList: NSSet)  {
        let completionHandler = {
            () -> Void in
            return
        }
        
        // update contact group
        if let ID = contactGroup.ID {
            sharedContactGroupsDataService.editContactGroup(groupID: ID,
                                                            name: name,
                                                            color: color,
                                                            completionHandler: completionHandler)
        } else {
            PMLog.D("No contact group ID")
        }
        
        // update email IDs
        // TODO: handle the conversion gracefully
        let original = contactGroup.emailIDs as! Set<Email>
        let updated = updatedEmailList as! Set<Email>
        
        let toAdd = updated.subtracting(original)
        let toDelete = original.subtracting(updated)
        
        addEmailsToContactGroup(emailList: toAdd as NSSet)
        removeEmailsFromContactGroup(emailList: toDelete as NSSet)
    }
    
    /**
     Deletes the contact group on the server and cache
     */
    func deleteContactGroup() {
        let completionHandler = {
            () -> Void in
            // TODO: handle self.contactGroup gracefully
            return
        }
        
        if let ID = contactGroup.ID {
            sharedContactGroupsDataService.deleteContactGroup(groupID: ID,
                                                              completionHandler: completionHandler)
        } else {
            PMLog.D("No contact group ID")
        }
    }
    
    /**
     Add the current email listing to the contact group on the server
     
     - Parameter emailList: Emails to add to the contact group
     */
    func addEmailsToContactGroup(emailList: NSSet) {
        let completionHandler = {
            () -> Void in
            return
        }
        
        // TODO: handle the conversion error
        let emails = (emailList.allObjects as! [Email])
        if let ID = contactGroup.ID {
            sharedContactGroupsDataService.addEmailsToContactGroup(groupID: ID,
                                                                   emailList: emails,
                                                                   completionHandler: completionHandler)
        } else {
            PMLog.D("No contact group ID")
        }
    }
    
    /**
     Delete the current email listing to the contact group on the server
     
     - Parameter emailList: Emails to delete from the contact group
     */
    func removeEmailsFromContactGroup(emailList: NSSet) {
        let completionHandler = {
            () -> Void in
            return
        }
        
        // TODO: handle the conversion error
        let emails = (emailList.allObjects as! [Email])
        
        if let ID = contactGroup.ID {
            sharedContactGroupsDataService.removeEmailsFromContactGroup(groupID: ID,
                                                                        emailList: emails,
                                                                        completionHandler: completionHandler)
        } else {
            PMLog.D("No contact group ID")
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
    func getEmail(at indexPath: IndexPath) -> (String, String) {
        let index = indexPath.row - 1
        guard index < emailsInGroup.count else {
            fatalError("Calculation error")
        }
        
        return (emailsInGroup[index].name, emailsInGroup[index].email)
    }
}
