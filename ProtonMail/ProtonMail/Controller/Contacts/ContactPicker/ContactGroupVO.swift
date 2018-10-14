//
//  ContactGroupVO.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/26.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class ContactGroupVO: NSObject, ContactPickerModelProtocol
{
    var modelType: ContactPickerModelState {
        get {
            return .contactGroup
        }
    }
    
    var ID: String
    var contactTitle: String
    var displayName: String?
    var displayEmail: String?
    var contactSubtitle: String?
    var contactImage: UIImage?
    var lock: UIImage?
    var hasPGPPined: Bool
    var hasNonePM: Bool
    
    func notes(type: Int) -> String {
        return ""
    }
    
    func setType(type: Int) { }
    
    func lockCheck(progress: () -> Void, complete: LockCheckComplete?) {}
    
    // contact group sub-selection
    var selectedMembers: Set<String> // [address]
    
    func getSelectedEmailsWithDetail() -> [(Group: String, Name: String, Address: String)]
    {
        var result: [(Group: String, Name: String, Address: String)] = []
        
        if let context = sharedCoreDataService.mainManagedObjectContext {
            for member in selectedMembers {
                if let email = Email.EmailForAddress(member,
                                                     inManagedObjectContext: context) {
                    result.append((self.contactTitle, email.name, member))
                } else {
                    // TODO: handle error
                    PMLog.D("Can't find the data for address = \(member)")
                }
            }
        }
        
        return result
    }
    
    func getSelectedEmails() -> [String] {
        return self.selectedMembers.map{$0}
    }
    
    func setSelectedEmails(selectedMembers: [String])
    {
        self.selectedMembers = Set<String>()
        for member in selectedMembers {
            self.selectedMembers.insert(member)
        }
    }
    
    func selectAllEmail() {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let label = Label.labelForLabelName(contactTitle,
                                                   inManagedObjectContext: context) {
                for email in label.emails.allObjects as! [Email] {
                    self.selectedMembers.insert(email.email)
                }
            }
        }
    }
    
    func getContactGroupInfo() -> (total: Int, color: String) {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let label = Label.labelForLabelName(contactTitle,
                                                   inManagedObjectContext: context) {
                return (label.emails.count, label.color)
            }
        }
        
        return (0, ColorManager.defaultColor)
    }
    
    init(ID: String, name: String) {
        self.ID = ID
        self.contactTitle = name
        self.displayName = nil
        self.displayEmail = nil
        self.contactSubtitle = ""
        self.contactImage = nil
        self.lock = nil
        self.hasPGPPined = false
        self.hasNonePM = false
        self.selectedMembers = Set<String>()
    }
}
