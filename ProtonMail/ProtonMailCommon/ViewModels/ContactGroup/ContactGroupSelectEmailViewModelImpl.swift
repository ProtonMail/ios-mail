//
//  ContactGroupSelectEmailViewModelImpl.swift
//  ProtonMail - Created on 2018/8/27.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

/// View model for ContactGroupSelectEmailController
class ContactGroupSelectEmailViewModelImpl: ContactGroupSelectEmailViewModel
{
    /// all of the emails that the user have in the contact
    private var allEmails: [Email]
    
    /// the email result for search bar to use
    private var emailsForDisplay: [Email]
    
    /// the list of email that is current in the contact group
    private var selectedEmails: Set<Email>
    
    /// after saving the email list, we refresh the edit view controller's data
    private let refreshHandler: (Set<Email>) -> Void
    
    /**
     Initializes a new ContactGroupSelectEmailViewModel
     */
    init(selectedEmails: Set<Email>, refreshHandler: @escaping (Set<Email>) -> Void) {
        self.allEmails = sharedContactDataService.allEmails()
        self.allEmails.sort {
            if $0.name == $1.name {
                return $0.email < $1.email
            }
            return $0.name < $1.name
        }
        self.emailsForDisplay = self.allEmails
        
        self.selectedEmails = selectedEmails
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
        refreshHandler(selectedEmails)
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
