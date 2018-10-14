//
//  ContactGroupSubSelectionViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/13.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class ContactGroupSubSelectionViewModelImpl: ContactGroupSubSelectionViewModel
{
    private let groupName: String
    private let groupColor: String?
    private var emailArray: [ContactGroupSubSelectionViewModelEmailInfomation]
    private let delegate: ContactGroupSubSelectionViewModelDelegate
    
    /**
     Setup the sub-selection view of a specific group, at a specific state
     
     For every given contact group, we
     (1) Attempt to get all emails associated with the group name -> email list G
     - might be empty, if the group name is changed to others, etc.
     (2) For every selectedEmails, we compare it to G.
     - If the email is missing from G, we add it in, and mark as selected
     - If the email is in G, we mark it as selected
     (3) Check is encrypted status
     (4) Produce an email array, sorted by name, then email
     */
    init(contactGroupName: String,
         selectedEmails: [String],
         delegate: ContactGroupSubSelectionViewModelDelegate) {
        self.groupName = contactGroupName
        self.delegate = delegate
        
        var emailData: [ContactGroupSubSelectionViewModelEmailInfomation] = []
        
        if let context = sharedCoreDataService.mainManagedObjectContext {
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
                // TODO: handle error
                self.groupColor = nil
            }
            
            // (2)
            for address in selectedEmails {
                var found = false
                for (i, candidate) in emailData.enumerated() {
                    if address == candidate.email {
                        emailData[i].isSelected = true
                        found = true
                        break
                    }
                }
                
                if found {
                    continue
                }
                
                if let emailObj = Email.EmailForAddress(address,
                                                        inManagedObjectContext: context) {
                    emailData.append(ContactGroupSubSelectionViewModelEmailInfomation.init(email: emailObj.email,
                                                                                           name: emailObj.name,
                                                                                           isSelected: true))
                } else {
                    // TODO: handle error
                    PMLog.D("Can't find \(address) in core data")
                }
            }
            
            // (3)
            // TODO
            
            // (4)
            emailData.sort {
                if $0.name == $1.name {
                    return $0.email < $1.email
                }
                return $0.name < $1.name
            }
        } else {
            // TODO: handle error
            self.groupColor = nil
        }
        
        emailArray = emailData // query
    }
    
    /**
     - Returns: currently selected email addresses
    */
    func getCurrentlySelectedEmails() -> [String] {
        var result: [String] = []
        for e in emailArray {
            if e.isSelected {
                result.append(e.email)
            }
        }
        
        return result
    }
    
    /**
     Set the isEncrypted status of the email after the fetch is completed
    */
    func setIsEncrypted(email: String, isEncrypted: UIImage?) {
        if let isEncryptedImage = isEncrypted {
            for i in emailArray.indices {
                if emailArray[i].email == email {
                    emailArray[i].isEncrypted = isEncryptedImage
                    break
                }
            }
        }
    }
    
    /**
     Select the given email address
    */
    func select(email: String) {
        for i in emailArray.indices {
            if emailArray[i].email == email {
                emailArray[i].isSelected = true
                break
            }
        }
        
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
     Deselect the given email address
    */
    func deselect(email: String) {
        // TODO: performance improvement
        let performDeselectInHeader = self.isAllSelected()
        
        for i in emailArray.indices {
            if emailArray[i].email == email {
                emailArray[i].isSelected = false
                break
            }
        }
        
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
            fatalError("Invalid access")
        }
        
        return self.emailArray[indexPath.row - 1] // -1 due to header row
    }
}
