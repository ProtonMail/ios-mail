//
//  ContactGroupSelectEmailViewModelImpl.swift
//  Proton Mail - Created on 2018/8/27.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

/// View model for ContactGroupSelectEmailController
class ContactGroupSelectEmailViewModelImpl: ContactGroupSelectEmailViewModel {

    /// all of the emails that the user have in the contact
    private var allEmails: [EmailEntity]
    
    /// the email result for search bar to use
    private var emailsForDisplay: [EmailEntity]
    
    /// the list of email that is current in the contact group
    private var selectedEmails: Set<EmailEntity>
    
    /// after saving the email list, we refresh the edit view controller's data
    private let refreshHandler: (Set<EmailEntity>) -> Void

    private var originalSelectedEmails: Set<EmailEntity>

    var havingUnsavedChanges: Bool {
        return selectedEmails != originalSelectedEmails
    }

    let contactService: ContactDataService

    /**
     Initializes a new ContactGroupSelectEmailViewModel
     */
    init(selectedEmails: Set<EmailEntity>, contactService: ContactDataService, refreshHandler: @escaping (Set<EmailEntity>) -> Void) {
        self.contactService = contactService
        self.allEmails = self.contactService.allEmails().compactMap(EmailEntity.init)
        self.allEmails.sort {
            if $0.name == $1.name {
                return $0.email < $1.email
            }
            return $0.name < $1.name
        }
        let usersManager: UsersManager = sharedServices.get()
        if let currentUser = usersManager.firstUser {
            self.emailsForDisplay = self.allEmails
                .filter({$0.userID.rawValue == currentUser.userinfo.userId})
        } else {
            self.emailsForDisplay = self.allEmails
        }

        self.emailsForDisplay = self.emailsForDisplay
            .sorted(by: {$1.name.localizedCaseInsensitiveCompare($0.name) == .orderedDescending})

        self.selectedEmails = selectedEmails
        self.originalSelectedEmails = selectedEmails
        self.refreshHandler = refreshHandler
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
    func getCellData(at indexPath: IndexPath) -> (ID: EmailID, name: String, email: String, isSelected: Bool) {
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
    func selectEmail(ID: EmailID) {
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
    func deselectEmail(ID: EmailID) {
        for email in allEmails {
            if email.emailID == ID {
                selectedEmails.remove(email)
                break
            }
        }
    }

    func search(query rawQuery: String?) {
        let usersManager: UsersManager = sharedServices.get()
        if let currentUser = usersManager.firstUser {
            self.emailsForDisplay = self.allEmails
                .filter({$0.userID.rawValue == currentUser.userinfo.userId})
                .sorted(by: {$1.name.localizedCaseInsensitiveCompare($0.name) == .orderedDescending})
        } else {
            self.emailsForDisplay = self.allEmails.sorted(by: {$1.name.localizedCaseInsensitiveCompare($0.name) == .orderedDescending})
        }

        if let query = rawQuery,
            query.count > 0 {
            let lowercaseQuery = query.lowercased()

            emailsForDisplay = emailsForDisplay.filter({
                if $0.email.lowercased().contains(check: lowercaseQuery) ||
                    $0.name.lowercased().contains(check: lowercaseQuery) {
                    return true
                } else {
                    return false
                }
            })
        }
    }
}
