//
//  ContactGroupDetailViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/10.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import PromiseKit

class ContactGroupDetailViewModelImpl: ContactGroupDetailViewModel
{
    /// the contact group label ID
    let groupID: String
    
    /// the contact group's name
    var name: String
    
    /// the contact group's color
    var color: String
    
    /// the contact group's emails (in NSSet)
    var emailIDs: NSSet {
        didSet {
            setupEmailIDsArray()
        }
    }
    
    /// the contact group's email (in Array)
    var emailIDsArray: [Email]
    
    init(groupID: String, name: String, color: String, emailIDs: NSSet) {
        self.groupID = groupID
        self.name = name
        self.color = color
        
        emailIDsArray = []
        self.emailIDs = emailIDs
        setupEmailIDsArray()
    }
    
    private func setupEmailIDsArray() {
        if let emailIDs = emailIDs.allObjects as? [Email] {
            emailIDsArray = emailIDs
            emailIDsArray.sort{
                (first: Email, second: Email) -> Bool in
                if first.name == second.name {
                    return first.email < second.email
                }
                return first.name < second.name
            }
        } else {
            PMLog.D("EmailIDs conversion error")
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
    
    func getEmailIDs() -> NSSet {
        return emailIDs
    }
    
    func getTotalEmailString() -> String {
        let cnt = self.getTotalEmails()
        
        return "\(cnt) Member\(cnt > 1 ? "s" : "")"
    }
    
    func getEmail(at indexPath: IndexPath) -> (emailID: String, name: String, email: String) {
        guard indexPath.row < emailIDsArray.count else {
            // TODO: handle error
            PMLog.D("Invalid index row request")
            fatalError("Invalid index row request")
        }
        
        return (emailIDsArray[indexPath.row].emailID, emailIDsArray[indexPath.row].name, emailIDsArray[indexPath.row].email)
    }
    
    /**
     Reloads the contact group from core data
     
     - Returns: Promise<Bool>. true if the contact group has been deleted from core data, false if the contact group can be fetched from core data
    */
    func reload() -> Promise<Bool> {
        if let context = sharedCoreDataService.mainManagedObjectContext,
            let label = Label.labelForLableID(groupID,
                                              inManagedObjectContext: context) {
            name = label.name
            color = label.color
            emailIDs = label.emails
            
            return .value(false)
        } else {
            // deleted case
            return .value(true)
        }
    }
}
