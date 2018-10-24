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
    private let allEmails: [Email]
    
    /// the email result for search bar to use
    private var emailsForDisplay: [Email]
    
    /// the list of email that is current in the contact group
    private var selectedEmails: Set<Email>
    
    /// after saving the email list, we refresh the edit view controller's data
    private let refreshHandler: (NSSet) -> Void
    
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
        self.emailsForDisplay = self.allEmails
        
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
        return emailsForDisplay.count
    }
    
    /**
     Return the name and the email of the given indexPath
     
     - Parameter indexPath: IndexPath
     - Returns: a tuple of name and email at the given indexPath
     */
    func getCellData(at indexPath: IndexPath) -> (ID: String, name: String, email: String, isSelected: Bool) {
        let selectedEmail = emailsForDisplay[indexPath.row]
        return (selectedEmail.emailID, selectedEmail.name, selectedEmail.email, selectedEmails.contains(selectedEmail))
    }
    
    /**
     Return the selected emails to the contact group
     */
    func save() {
        refreshHandler(selectedEmails as NSSet)
    }
    
    /**
     Add the emailID from the selection state
    */
    func selectEmail(ID: String) {
        for email in allEmails {
            if email.emailID == ID {
                selectedEmails.insert(email)
                break
            }
        }
    }
    
    /**
     Remove the emailID from the selection state
    */
    func deselectEmail(ID: String) {
        for email in allEmails {
            if email.emailID == ID {
                selectedEmails.remove(email)
                break
            }
        }
    }
    
    func search(query rawQuery: String?) {
        if let query = rawQuery,
            query.count > 0 {
            let lowercaseQuery = query.lowercased()
            emailsForDisplay = allEmails.filter({
                if $0.email.lowercased().contains(check: lowercaseQuery) ||
                    $0.name.lowercased().contains(check: lowercaseQuery) {
                    return true
                } else {
                    return false
                }
            })
        } else {
            emailsForDisplay = allEmails
        }
    }
}
