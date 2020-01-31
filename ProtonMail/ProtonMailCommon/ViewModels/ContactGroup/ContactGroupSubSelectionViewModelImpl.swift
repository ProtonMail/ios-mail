//
//  ContactGroupSubSelectionViewModelImpl.swift
//  ProtonMail - Created on 2018/10/13.
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

class ContactGroupSubSelectionViewModelImpl: ContactGroupSubSelectionViewModel
{
    func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?) {
        self.user.contactService.lockerCheck(model: model, progress: progress, complete: complete)
    }
    
    private let user: UserManager
    private let groupName: String
    private let groupColor: String
    private var emailArray: [ContactGroupSubSelectionViewModelEmailInfomation]
    private let delegate: ContactGroupSubSelectionViewModelDelegate
    
    /**
     Setup the sub-selection view of a specific group, at a specific state
     
     For every given contact group, we
     (1) Attempt to get all emails associated with the group name -> email list G
     - might be empty, if the group name was changed to others, etc.
     (2) For every selectedEmails, we compare it to G.
     - If the (name, email) pair is missing from G, we add it in, and mark as selected
     - If the (name, email) pair is in G, we mark it as selected
     (3) Produce an email array, sorted by name, then email
     */
    init(contactGroupName: String,
         selectedEmails: [DraftEmailData],
         user: UserManager,
         delegate: ContactGroupSubSelectionViewModelDelegate) {
        self.user = user
        self.groupName = contactGroupName
        self.delegate = delegate
        
        var emailData: [ContactGroupSubSelectionViewModelEmailInfomation] = []
        
        let context = CoreDataService.shared.mainManagedObjectContext
        // (1)
        if let label = Label.labelForLabelName(self.groupName,
                                               inManagedObjectContext: context),
            let emails = label.emails.allObjects as? [Email] {
            self.groupColor = label.color
            
            for email in emails {
                emailData.append(ContactGroupSubSelectionViewModelEmailInfomation.init(email: email.email,
                                                                                       name: email.name))
            }
        } else {
            // the group might be renamed or deleted
            self.groupColor = ColorManager.defaultColor
        }
        
        // (2)
        for member in selectedEmails {
            var found = false
            for (i, candidate) in emailData.enumerated() {
                if member.email == candidate.email &&
                    member.name == candidate.name &&
                    emailData[i].isSelected == false { // case: >= 2 identical name-email pair occurs
                    emailData[i].isSelected = true
                    found = true
                    break
                }
            }
            
            if found {
                continue
            }
            
            emailData.append(ContactGroupSubSelectionViewModelEmailInfomation(email: member.email,
                                                                              name: member.name,
                                                                              isSelected: true))
        }
        
        // (3)
        emailData.sort {
            if $0.name == $1.name {
                return $0.email < $1.email
            }
            return $0.name < $1.name
        }
        
        emailArray = emailData // query
    }
    
    /**
     - Returns: currently selected email addresses
    */
    func getCurrentlySelectedEmails() -> [DraftEmailData] {
        var result: [DraftEmailData] = []
        for e in emailArray {
            if e.isSelected {
                result.append(DraftEmailData.init(name: e.name, email: e.email))
            }
        }
        
        return result
    }
    
    /**
     Select the given email data
    */
    func select(indexPath: IndexPath) {
        emailArray[indexPath.row - 1].isSelected = true
        
        // TODO: performance improvement
        if self.isAllSelected() {
            delegate.reloadTable()
        }
    }
    
    /**
     Select all email addresses
    */
    func selectAll() {
        for i in emailArray.indices {
            emailArray[i].isSelected = true
        }
        delegate.reloadTable()
    }
    
    /**
     Deselect the given email data
    */
    func deselect(indexPath: IndexPath) {
        // TODO: performance improvement
        let performDeselectInHeader = self.isAllSelected()
        
        emailArray[indexPath.row - 1].isSelected = false
        
        if performDeselectInHeader {
             delegate.reloadTable()
        }
    }
    
    /**
     Deselect all email addresses
    */
    func deSelectAll() {
        for i in emailArray.indices {
            emailArray[i].isSelected = false
        }
        delegate.reloadTable()
    }
    
    /**
     - Returns: true if all of the email are selected
    */
    func isAllSelected() -> Bool {
        for i in emailArray.indices {
            if emailArray[i].isSelected == false {
                return false
            }
        }
        return true
    }
    
    func getGroupName() -> String {
        return self.groupName
    }
    
    func getGroupColor() -> String? {
        return self.groupColor
    }
    
    func getTotalRows() -> Int {
        // 1 header + n emails
        return self.emailArray.count + 1
    }
    
    func cellForRow(at indexPath: IndexPath) -> ContactGroupSubSelectionViewModelEmailInfomation {
        guard indexPath.row < self.getTotalRows() else {
            // TODO: handle error
            PMLog.D("FatalError: Invalid access")
            return ContactGroupSubSelectionViewModelEmailInfomation.init(email: "", name: "")
        }
        
        return self.emailArray[indexPath.row - 1] // -1 due to header row
    }
    
    func setRequiredEncryptedCheckStatus(at indexPath: IndexPath,
                                         to status: ContactGroupSubSelectionEmailLockCheckingState,
                                         isEncrypted: UIImage?) {
        guard indexPath.row < self.getTotalRows() else {
            // TODO: handle error
            PMLog.D("FatalError: Invalid access")
            return
        }
        
        self.emailArray[indexPath.row - 1].isEncrypted = isEncrypted
        self.emailArray[indexPath.row - 1].checkEncryptedStatus = status // -1 due to header row
    }
}
