//
//  ContactGroupDetailViewModelImpl.swift
//  ProtonMail - Created on 2018/9/10.
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
import PromiseKit

class ContactGroupDetailViewModelImpl: ContactGroupDetailViewModel {
    /// the contact group label ID
    let groupID: String
    
    /// the contact group's name
    var name: String
    
    /// the contact group's color
    var color: String
    
    /// the contact group's emails (in NSSet)
    var emailIDs: Set<Email> {
        didSet {
            setupEmailIDsArray()
        }
    }
    
    /// the contact group's email (in Array)
    var emailIDsArray: [Email]
    
    init(groupID: String, name: String, color: String, emailIDs: Set<Email>) {
        self.groupID = groupID
        self.name = name
        self.color = color
        
        emailIDsArray = []
        self.emailIDs = emailIDs
        setupEmailIDsArray()
    }
    
    private func setupEmailIDsArray() {
        emailIDsArray = emailIDs.map{$0}
        emailIDsArray.sort{
            (first: Email, second: Email) -> Bool in
            if first.name == second.name {
                return first.email < second.email
            }
            return first.name < second.name
        }
    }
    
    func getGroupID() -> String {
        return groupID
    }
    
    func getName() -> String {
        return name
    }
    
    func getColor() -> String {
        return color
    }
    
    func getTotalEmails() -> Int {
        return emailIDs.count
    }
    
    func getEmailIDs() -> Set<Email> {
        return emailIDs
    }
    
    func getTotalEmailString() -> String {
        let cnt = self.getTotalEmails()
        
        if cnt <= 1 {
            return String.init(format: LocalString._contact_groups_member_count_description,
                               cnt)
        } else {
            return String.init(format: LocalString._contact_groups_members_count_description,
                               cnt)
        }
    }
    
    func getEmail(at indexPath: IndexPath) -> (emailID: String, name: String, email: String) {
        guard indexPath.row < emailIDsArray.count else {
            // TODO: handle error
            PMLog.D("FatalError: Invalid index row request")
            return ("", "", "")
        }
        
        return (emailIDsArray[indexPath.row].emailID, emailIDsArray[indexPath.row].name, emailIDsArray[indexPath.row].email)
    }
    
    /**
     Reloads the contact group from core data
     
     - Returns: Promise<Bool>. true if the contact group has been deleted from core data, false if the contact group can be fetched from core data
     */
    func reload() -> Promise<Bool> {
        let context = sharedCoreDataService.mainManagedObjectContext
        if let label = Label.labelForLableID(groupID, inManagedObjectContext: context) {
            name = label.name
            color = label.color
            emailIDs = (label.emails as? Set<Email>) ?? Set<Email>()
            
            return .value(false)
        } else {
            // deleted case
            return .value(true)
        }
    }
}
