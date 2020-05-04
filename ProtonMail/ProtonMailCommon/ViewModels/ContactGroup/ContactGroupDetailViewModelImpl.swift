//
//  ContactGroupDetailViewModelImpl.swift
//  ProtonMail - Created on 2018/9/10.
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
    private(set) var user: UserManager
    
    init(user: UserManager, groupID: String, name: String, color: String, emailIDs: Set<Email>) {
        self.user = user
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
        let context = CoreDataService.shared.mainManagedObjectContext
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
