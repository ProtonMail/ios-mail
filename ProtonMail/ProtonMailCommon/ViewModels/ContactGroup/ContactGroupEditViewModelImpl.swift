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
        self.tableSectionTitle = []
        self.contactGroup = ContactGroupData(ID: groupID,
                                             name: name,
                                             color: color,
                                             emailIDs: emailIDs)
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
        
        tableSectionTitle[1] = "\(emailCount) MEMBER\(emailCount > 1 ? "S" : "")"
    }
    
    /**
     Load email content and prepare the tableView for displaying them
    */
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
            self.delegate?.update()
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
    func setColor(newColor: String) {
        contactGroup.color = newColor
        self.delegate?.update()
    }
    
    /**
     - Parameter emails: Set the emails that will be in the contact group
     */
    func setEmails(emails: NSSet)
    {
        contactGroup.emailIDs = NSMutableSet(set: emails)
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
        fatalError("Email to delete doesn't exist")
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
    func getEmails() -> NSSet {
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
     Creates the contact group on the server and cache
     
     - Parameters:
     - name: The contact group's name
     - color: The contact group's color
     - emailList: Emails that belongs to this contact group
     
     - Returns: Promise<Void>
     */
    private func createContactGroupDetail(name: String,
                                          color: String,
                                          emailList: NSSet) -> Promise<Void> {
        
        return Promise {
            seal in
            
            let completionHandler = {
                (contactGroupID: String?) -> Void in
                
                if let contactGroupID = contactGroupID {
                    self.contactGroup.ID = contactGroupID
                    
                    // add email IDs
                    firstly {
                        self.addEmailsToContactGroup(emailList: emailList)
                        }.done {
                            seal.fulfill(())
                        }.catch {
                            error in
                            seal.reject(error)
                    }
                } else {
                    PMLog.D("No contact group ID")
                    seal.reject(ContactGroupEditError.addFailed)
                }
            }
            
            // create contact group
            sharedContactGroupsDataService.createContactGroup(name: name,
                                                              color: color,
                                                              completionHandler: completionHandler)
            
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
                                          updatedEmailList: NSSet) -> Promise<Void> {
        
        return Promise {
            seal in
            
            let completionHandler = {
                (success: Bool) -> Void in
                
                if success {
                    // update email IDs
                    if let original = self.contactGroup.originalEmailIDs as? Set<Email>,
                        let updated = updatedEmailList as? Set<Email> {
                        
                        let toAdd = updated.subtracting(original)
                        let toDelete = original.subtracting(updated)
                        
                        firstly {
                            () -> Promise<Void> in
                            self.addEmailsToContactGroup(emailList: toAdd as NSSet)
                            }.then {
                                _ -> Promise<Void> in
                                self.removeEmailsFromContactGroup(emailList: toDelete as NSSet)
                            }.done {
                                seal.fulfill(())
                            }.catch {
                                error in
                                seal.reject(error)
                        }
                    } else {
                        PMLog.D("NSSet to Email set conversion failure")
                        seal.reject(ContactGroupEditError.NSSetConversionToEmailSetFailure)
                    }
                } else {
                    seal.reject(ContactGroupEditError.updateFailed)
                }
            }
            
            // update contact group
            if let ID = contactGroup.ID {
                sharedContactGroupsDataService.editContactGroup(groupID: ID,
                                                                name: name,
                                                                color: color,
                                                                completionHandler: completionHandler)
            } else {
                PMLog.D("No contact group ID")
                seal.reject(ContactGroupEditError.noContactGroupID)
            }
        }
    }
    
    /**
     Deletes the contact group on the server and cache
     
     - Returns: Promise<Void>
    */
    func deleteContactGroup() -> Promise<Void> {
        return Promise {
            seal in
            
            let completionHandler = {
                (success: Bool) -> Void in
                
                if success {
                    seal.fulfill(())
                } else {
                    seal.reject(ContactGroupEditError.deleteFailed)
                }
            }
            
            if let ID = contactGroup.ID {
                sharedContactGroupsDataService.deleteContactGroup(groupID: ID,
                                                                  completionHandler: completionHandler)
            } else {
                PMLog.D("No contact group ID")
                seal.reject(ContactGroupEditError.noContactGroupID)
            }
        }
    }
    
    /**
     Add the current email listing to the contact group on the server
     
     - Parameter emailList: Emails to add to the contact group
     
     - Returns: Promise<Void>
     */
    func addEmailsToContactGroup(emailList: NSSet) -> Promise<Void> {
        return Promise {
            seal in
            
            let completionHandler = {
                () -> Void in
                
                seal.fulfill(())
            }
            
            if let emails = emailList.allObjects as? [Email] {
                if let ID = contactGroup.ID {
                    sharedContactGroupsDataService.addEmailsToContactGroup(groupID: ID,
                                                                           emailList: emails,
                                                                           completionHandler: completionHandler)
                } else {
                    PMLog.D("No contact group ID")
                    
                    seal.reject(ContactGroupEditError.noContactGroupID)
                }
            } else {
                PMLog.D("NSSet to Email array conversion failure")
                seal.reject(ContactGroupEditError.NSSetConversionToEmailArrayFailure)
            }
        }
    }
    
    /**
     Delete the current email listing to the contact group on the server
     
     - Parameter emailList: Emails to delete from the contact group
     
     - Returns: Promise<Void>
     */
    func removeEmailsFromContactGroup(emailList: NSSet) -> Promise<Void> {
        return Promise {
            seal in
            
            let completionHandler = {
                () -> Void in
                
                seal.fulfill(())
            }
            
            if let emails = emailList.allObjects as? [Email] {
                if let ID = contactGroup.ID {
                    sharedContactGroupsDataService.removeEmailsFromContactGroup(groupID: ID,
                                                                                emailList: emails,
                                                                                completionHandler: completionHandler)
                } else {
                    PMLog.D("No contact group ID")
                    seal.reject(ContactGroupEditError.noContactGroupID)
                }
            } else {
                PMLog.D("NSSet to Email array conversion failure")
                seal.reject(ContactGroupEditError.NSSetConversionToEmailArrayFailure)
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
            fatalError("Calculation error")
        }
        
        return (emailsInGroup[index].emailID, emailsInGroup[index].name, emailsInGroup[index].email)
    }
}
