//
//  ContactGroupSelectEmailViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/27.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

/// View model for ContactGroupSelectEmailController
class ContactGroupSelectEmailViewModelImpl: ContactGroupSelectEmailViewModel
{
    /// all of the emails that the user have in the contact
    let allEmails: [Email]
    
    /// the list of email that is current in the contact group
    var selectedEmails: Set<Email>
    
    /// after saving the email list, we refresh the edit view controller's data
    let refreshHandler: (NSSet) -> Void
    
    /**
     Initializes a new ContactGroupSelectEmailViewModel
    */
    init(selectedEmails: NSSet, refreshHandler: @escaping (NSSet) -> Void) {
        self.allEmails = sharedContactDataService.allEmails()
        self.allEmails.sort {
            if $0.name == $1.name {
                return $0.email < $1.email
            }
            return $0.name < $1.name
        }
        
        // TODO: do conversion check
        self.selectedEmails = selectedEmails as! Set
        self.refreshHandler = refreshHandler
    }
    
    /**
     For the given indexPath, returns if it is in the email list or not
     
     - Parameter indexPath: IndexPath
     - Returns: true if the given indexPath is in the email list, false otherwise
    */
    func getSelectionStatus(at indexPath: IndexPath) -> Bool {
        let selectedEmail = allEmails[indexPath.row]
        return selectedEmails.contains(selectedEmail)
    }
    
    /**
     Return the total number of emails in the email list
     
     - Returns: total email in the list
    */
    func getTotalEmailCount() -> Int {
        return allEmails.count
    }
    
    /**
     Return the name and the email of the given indexPath
     
     - Parameter indexPath: IndexPath
     - Returns: a tuple of name and email at the given indexPath
    */
    func getCellData(at indexPath: IndexPath) -> (name: String, email: String, isSelected: Bool) {
        let selectedEmail = allEmails[indexPath.row]
        return (selectedEmail.name, selectedEmail.email, selectedEmails.contains(selectedEmail))
    }
    
    /**
     Return the selected emails to the contact group
    */
    func save(indexPaths: [IndexPath]?) {
        selectedEmails = Set<Email>()
        if let indexPaths = indexPaths {
            for indexPath in indexPaths {
                print("Selected: \(allEmails[indexPath.row].email)")
                selectedEmails.insert(allEmails[indexPath.row])
            }
        }
        refreshHandler(selectedEmails as NSSet)
    }
    
}
