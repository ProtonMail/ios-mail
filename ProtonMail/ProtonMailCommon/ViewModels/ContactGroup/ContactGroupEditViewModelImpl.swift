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
    
    /// the contact group that we will be manipulating
    /// TODO: consistency, always up to date
    var contactGroup: Label
    
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
         contactGroup: Label? = nil) {
        self.state = state
        self.emailsInGroup = []
        self.tableContent = []
        
        if let contactGroup = contactGroup {
            // .edit
            self.contactGroup = contactGroup
        } else {
            // .create
            if let context = sharedCoreDataService.mainManagedObjectContext {
                self.contactGroup = Label(context: context)
                self.contactGroup.color = self.getColor()
            } else {
                // TODO: handle the error
                PMLog.D("Can't get context")
                fatalError("Can't get context")
            }
        }
        
        self.prepareEmails()
    }
    
    /**
     Reset the tableView content to basic elements only
     
     This is called automatically in the updateTableContent(emailCount:)
     */
    func resetTableContent() {
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
    func updateTableContent(emailCount: Int) {
        resetTableContent()
        
        for _ in 0..<emailCount {
            self.tableContent[1].append(.email)
        }
    }

    /**
     Rollback the modifications on the contact group object
    */
    func cancel() {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            context.refresh(contactGroup, mergeChanges: false)
        }
    }
    
    func prepareEmails() {
        // get email as an array
        if let temp = self.contactGroup.emails.allObjects as? [Email] {
            self.emailsInGroup = temp
            self.emailsInGroup.sort {
                if $0.name == $1.name {
                    return $0.email < $1.email
                }
                return $0.name < $1.name
            }
            updateTableContent(emailCount: self.emailsInGroup.count)
        } else {
            // TODO: handle this gracefully
            fatalError("Can't convert to [email]")
        }
    }
    
    /**
     - Parameter name: The name of the contact group to be set to
     
     // TODO: bundle it with the textField delegate, so we can keep the contactGroup status up-to-date
     */
    func setName(name: String)
    {
        contactGroup.name = name
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
        contactGroup.emails = emails
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
        return contactGroup.name
    }
    
    /**
     - Returns: the contact group ID
     */
    func getContactGroupID() -> String? {
        if state == .create {
            return nil
        }
        return contactGroup.labelID
    }
    
    /**
     - Returns: the color of the contact group
     */
    func getColor() -> String {
        return contactGroup.color == "" ? ColorManager.defaultColor : contactGroup.color
    }
    
    /**
     - Returns: the emails in the contact group
     */
    func getEmails() -> NSSet {
        return contactGroup.emails
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
        guard contactGroup.name != "" else {
            seal.reject(ContactGroupEditError.noNameForGroup)
            return promise
        }
        
        guard contactGroup.emails.count > 0 else {
            seal.reject(ContactGroupEditError.noEmailInGroup)
            return promise
        }
        
        // TODO: promise
        let name = contactGroup.name
        let color = contactGroup.color
        let emails = contactGroup.emails
        cancel() // if no cancel() call, we are using the modified object for saving, which doesn't make sense
        
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
                self.contactGroup.labelID = contactGroupID
                
                // add email IDs
                // TODO: no contactGroupID check
                self.addEmailsToContactGroup(emailList: emailList)
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
        sharedContactGroupsDataService.editContactGroup(groupID: contactGroup.labelID,
                                                        name: name,
                                                        color: color,
                                                        completionHandler: completionHandler)
        
        // update email IDs
        // TODO: handle the conversion gracefully
        let original = contactGroup.emails as! Set<Email>
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
        
        sharedContactGroupsDataService.deleteContactGroup(groupID: contactGroup.labelID,
                                                          completionHandler: completionHandler)
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
        sharedContactGroupsDataService.addEmailsToContactGroup(groupID: contactGroup.labelID,
                                                               emailList: emails,
                                                               completionHandler: completionHandler)
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
        sharedContactGroupsDataService.removeEmailsFromContactGroup(groupID: contactGroup.labelID,
                                                                    emailList: emails,
                                                                    completionHandler: completionHandler)
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
