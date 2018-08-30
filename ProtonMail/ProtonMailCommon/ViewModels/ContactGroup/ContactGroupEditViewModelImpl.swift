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
    var contactGroup: Label! // TODO: fix this
    var allEmails: [Email]
    var tableContent: [[ContactGroupTableCellType]]
    var delegate: ContactGroupEditViewModelDelegate!
    
    /* Setup code */
    init(state: ContactGroupEditViewControllerState = .create,
         contactGroupID: String? = nil)
    {
        self.state = state
        self.allEmails = []
        self.tableContent = []
        
        self.loadContactGroupFromCache(contactGroupID: contactGroupID)
        resetTableContent()
        
        print("After init \(self.contactGroup)")
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
    
    func loadContactGroupFromCache(contactGroupID: String?) {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            switch self.state {
            case .edit:
                if let ID = contactGroupID,
                    let label = Label.labelForLableID(ID,
                                                      inManagedObjectContext: context) {
                    self.contactGroup = label
                    if let temp = self.contactGroup.emails.allObjects as? [Email] {
                        self.allEmails = temp
                    } else {
                        // TODO: handle this gracefully
                        fatalError("Can't convert to [email]")
                    }
                } else {
                    // TODO: handle this gracefully
                    fatalError("Can't load contact group data")
                }
            case .create:
                self.contactGroup = Label(context: context)
            }
        } else {
            // TODO: handle this gracefully
            fatalError("Can't load contact group data")
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
        return contactGroup.name
    }
    
    func getContactGroupID() -> String {
        return contactGroup.labelID
    }
    
    // TODO: default?
    func getCurrentColorWithDefault() -> String {
        return contactGroup.color == "" ? ColorManager.defaultColor : contactGroup.color
    }
    
    func getEmailIDsInContactGroup() -> NSSet {
        return contactGroup.emails
    }
    
    /* Data operation */
    func saveContactGroupDetail(name: String, color: String, emailList: NSSet) {
        switch state {
        case .create:
            createContactGroupDetail(name: name, color: color, emailList: emailList)
        case .edit:
            updateContactGroupDetail(name: name, color: color, emailList: emailList)
        }
    }
    
    private func createContactGroupDetail(name: String,
                                          color: String,
                                          emailList: NSSet) {
        let completionHandler = {
            () -> Void in
            self.delegate.update()
        }
        
        // create contact group
        // TODO: error (nil) check
        sharedContactGroupsDataService.addContactGroup(name: name,
                                                       color: color,
                                                       completionHandler: completionHandler)
        
        // TODO: add email IDs
        //        if let emailList = newContactGroup.emailIDs {
        //            addEmailsToContactGroup(emailList: emailList)
        //        }
    }
    
    private func updateContactGroupDetail(name: String,
                                          color: String,
                                          emailList: NSSet) {
        let completionHandler = {
            () -> Void in
            self.delegate.update()
        }
        
        // update contact group
        sharedContactGroupsDataService.editContactGroup(groupID: contactGroup.labelID,
                                                        name: name,
                                                        color: color,
                                                        completionHandler: completionHandler)
        
        // update email IDs
        //        let toRemove = contactGroup.emailIDs?.filter({
        //            if editedContactGroup.emailIDs == nil {
        //                return true
        //            }
        //            return editedContactGroup.emailIDs!.contains($0) == false
        //        })
        //
        //        let toAdd = editedContactGroup.emailIDs?.filter({
        //            if contactGroup.emailIDs == nil {
        //                return true
        //            }
        //            return contactGroup.emailIDs!.contains($0) == false
        //        })
        //
        //        if let data = toRemove {
        //            removeEmailsFromContactGroup(emailList: data)
        //        }
        //        if let data = toAdd {
        //            addEmailsToContactGroup(emailList: data)
        //        }
        //
        //        contactGroup.emailIDs = editedContactGroup.emailIDs
    }
    
    func deleteContactGroup() {
        let completionHandler = {
            () -> Void in
            
            // TODO: handle self.contactGroup gracefully
            self.delegate.update()
        }
        
        sharedContactGroupsDataService.deleteContactGroup(groupID: contactGroup.labelID,
                                                          completionHandler: completionHandler)
    }
    
    // TODO
    func addEmailsToContactGroup(emailList: NSSet) {
        let completionHandler = {
            () -> Void in
            
            //            if self.contactGroup.emailIDs == nil {
            //                self.contactGroup.emailIDs = [String]()
            //            }
            //
            //            for email in emailList {
            //                if self.contactGroup.emailIDs!.contains(email) == false {
            //                    self.contactGroup.emailIDs!.append(email)
            //                }
            //            }
        }
        
        let temp = emailList.allObjects as! [Email]
        var emails = [String]()
        for t in temp {
            emails.append(t.email)
        }
        
        sharedContactGroupsDataService.addEmailsToContactGroup(groupID: contactGroup.labelID,
                                                               emailList: emails,
                                                               completionHandler: completionHandler)
    }
    
    // TODO
    func removeEmailsFromContactGroup(emailList: NSSet) {
        let completionHandler = {
            () -> Void in
            
            //            guard self.contactGroup.emailIDs != nil else {
            //                return
            //            }
            //
            //            self.contactGroup.emailIDs = self.contactGroup.emailIDs!.filter({
            //                if emailList.contains($0) {
            //                    return false
            //                }
            //                return true
            //            })
            //
            //            if self.contactGroup.emailIDs!.count == 0 {
            //                self.contactGroup.emailIDs = nil
            //            }
        }
        
        let temp = emailList.allObjects as! [Email]
        var emails = [String]()
        for t in temp {
            emails.append(t.email)
        }
        
        sharedContactGroupsDataService.removeEmailsFromContactGroup(groupID: contactGroup.labelID,
                                                                    emailList: emails,
                                                                    completionHandler: completionHandler)
    }
    
    func updateColor(newColor: String?) {
        if let newColor = newColor {
            contactGroup.color = newColor
        } else {
            // TODO: use default
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
        let index = indexPath.row - 1
        guard index < allEmails.count else {
            fatalError("Calculation error")
        }
        
        return (allEmails[index].name, allEmails[index].email)
    }
}
