//
//  ContactGroupVO.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/26.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

// contact group sub-selection
struct DraftEmailData: Hashable
{
    let name: String
    let email: String
    
    init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}

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
    
    /*
     contact group subselection
     
     The contact information we can get from draft are name, email address, and group name
     
     So if the (name, email address) pair doesn't match any record inthe  current group,
     we will treat it as a new pair
     */
    private var selectedMembers: Set<DraftEmailData>
    
    func getSelectedEmailsWithDetail() -> [(Group: String, Name: String, Address: String)]
    {
        var result: [(Group: String, Name: String, Address: String)] = []
        
        for member in selectedMembers {
            result.append((Group: self.contactTitle, Name: member.name, Address: member.email))
        }
        
        return result
    }
    
    func getSelectedEmailAddresses() -> [String] {
        return self.selectedMembers.map{$0.email}
    }
    
    func getSelectedEmailData() -> [DraftEmailData] {
        return self.selectedMembers.map{$0}
    }
    
    func overwriteSelectedEmails(with newSelectedMembers: [DraftEmailData])
    {
        selectedMembers = Set<DraftEmailData>()
        for member in newSelectedMembers {
            selectedMembers.insert(member)
        }
    }
    
    /**
     Select all emails from the contact group
     Notice: this method will clear all previous selections
    */
    func selectAllEmailFromGroup() {
        selectedMembers = Set<DraftEmailData>()
        
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let label = Label.labelForLabelName(contactTitle,
                                                   inManagedObjectContext: context) {
                for email in label.emails.allObjects as! [Email] {
                    self.selectedMembers.insert(DraftEmailData.init(name: email.name,
                                                                    email: email.email))
                }
            }
        }
    }
    
    private var groupSize: Int? = nil
    private var groupColor: String? = nil
    /**
     For the composer's autocomplete
     Note that groupSize and groupColor are cached!
     - Returns: the current group size and group color
    */
    func getContactGroupInfo() -> (total: Int, color: String) {
        if let size = groupSize, let color = groupColor {
            return (size, color)
        }
        
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let label = Label.labelForLabelName(contactTitle,
                                                   inManagedObjectContext: context) {
                groupColor = label.color
                groupSize = label.emails.count
                return (label.emails.count, label.color)
            }
        }
        
        return (0, ColorManager.defaultColor)
    }
    
    /**
     Calculates the group size, selected member count, and group color
     Information for composer collection view cell
    */
    func getGroupInformation() -> (memberSelected: Int, totalMemberCount: Int, groupColor: String) {
        let errorResponse = (0, 0, ColorManager.defaultColor)
        
        var emailSet = Set<DraftEmailData>()
        var color = ""
        if let context = sharedCoreDataService.mainManagedObjectContext {
            // (1) get all email in the contact group
            if let label = Label.labelForLabelName(self.contactTitle,
                                                   inManagedObjectContext: context),
                let emails = label.emails.allObjects as? [Email] {
                color = label.color
                
                for email in emails {
                    emailSet.insert(DraftEmailData.init(name: email.name,
                                                              email: email.email))
                }
            } else {
                // TODO: handle error
                return errorResponse
            }
            
            // (2) get all that is NOT in the contact group, but is selected
            for member in self.selectedMembers {
                emailSet.insert(member)
            }
            
            return (selectedMembers.count, emailSet.count, color)
        } else {
            return errorResponse
        }
    }
    
    init(ID: String, name: String, groupSize: Int? = nil, color: String? = nil) {
        self.ID = ID
        self.contactTitle = name
        self.groupColor = color
        self.groupSize = groupSize
        
        self.displayName = nil
        self.displayEmail = nil
        self.contactSubtitle = ""
        self.contactImage = nil
        self.lock = nil
        self.hasPGPPined = false
        self.hasNonePM = false
        self.selectedMembers = Set<DraftEmailData>()
    }
    
    func equals(_ other: ContactPickerModelProtocol) -> Bool {
        return self.isEqual(other)
    }
}
