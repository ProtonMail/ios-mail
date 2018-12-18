//
//  ContactGroupVO.swift
//  ProtonMail - Created on 2018/9/26.
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

class ContactGroupVO: NSObject, ContactPickerModelProtocol {
    
    var modelType: ContactPickerModelState {
        get {
            return .contactGroup
        }
    }
    
    var ID: String
    var contactTitle: String
    var displayName: String?
    var displayEmail: String?
    var contactImage: UIImage?
    var lock: UIImage?
    var hasPGPPined: Bool
    var hasNonePM: Bool
    
    var color: String? {
        get {
            if let color = groupColor {
                return color
            }
            
            let context = sharedCoreDataService.mainManagedObjectContext
            if let label = Label.labelForLabelName(contactTitle,
                                                   inManagedObjectContext: context) {
                groupColor = label.color
                groupSize = label.emails.count
                return label.color
            }
            
            return ColorManager.defaultColor
        }
    }
    
    var contactSubtitle: String? {
        get {
            let count = self.contactCount
            if count <= 1 {
                return String.init(format: LocalString._contact_groups_member_count_description,
                                   count)
            } else {
                return String.init(format: LocalString._contact_groups_members_count_description,
                                    count)
            }
        }
    }
    
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
    private var selectedMembers: MultiSet<DraftEmailData>
    
    func getSelectedEmailsWithDetail() -> [(Group: String, Name: String, Address: String)]
    {
        var result: [(Group: String, Name: String, Address: String)] = []
        
        for member in selectedMembers {
            for _ in 0..<member.value {
                result.append((Group: self.contactTitle,
                               Name: member.key.name,
                               Address: member.key.email))
            }
        }
        
        return result
    }
    
    /**
     Get all email addresses
    */
    func getSelectedEmailAddresses() -> [String] {
        return self.selectedMembers.map{$0.key.email}
    }
    
    /**
     Get all DraftEmailData (the count will match)
    */
    func getSelectedEmailData() -> [DraftEmailData] {
        var result: [DraftEmailData] = []
        for member in selectedMembers {
            for _ in 0..<member.value {
                result.append(member.key)
            }
        }
        return result
    }
    
    /**
     Updates the selected members (completely overwrite)
    */
    func overwriteSelectedEmails(with newSelectedMembers: [DraftEmailData])
    {
        selectedMembers.removeAll()
        for member in newSelectedMembers {
            selectedMembers.insert(member)
        }
    }
    
    /**
     Select all emails from the contact group
     Notice: this method will clear all previous selections
    */
    func selectAllEmailFromGroup() {
        selectedMembers.removeAll()
        
        let context = sharedCoreDataService.mainManagedObjectContext
        if let label = Label.labelForLabelName(contactTitle,
                                               inManagedObjectContext: context) {
            for email in label.emails.allObjects as! [Email] {
                let member = DraftEmailData.init(name: email.name,
                                                 email: email.email)
                selectedMembers.insert(member)
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
        
        let context = sharedCoreDataService.mainManagedObjectContext
        if let label = Label.labelForLabelName(contactTitle,
                                               inManagedObjectContext: context) {
            groupColor = label.color
            groupSize = label.emails.count
            return (label.emails.count, label.color)
        }
        
        return (0, ColorManager.defaultColor)
    }
    
    var contactCount : Int {
        get {
            if let size = groupSize {
                return size
            }
            
            let context = sharedCoreDataService.mainManagedObjectContext
            if let label = Label.labelForLabelName(contactTitle,
                                                   inManagedObjectContext: context) {
                groupColor = label.color
                groupSize = label.emails.count
                return label.emails.count
            }
            
            return 0
        }
    }
    
    /**
     Calculates the group size, selected member count, and group color
     Information for composer collection view cell
    */
    func getGroupInformation() -> (memberSelected: Int, totalMemberCount: Int, groupColor: String) {
        let errorResponse = (0, 0, ColorManager.defaultColor)
        
        let emailMultiSet = MultiSet<DraftEmailData>()
        var color = ""
        let context = sharedCoreDataService.mainManagedObjectContext
        // (1) get all email in the contact group
        if let label = Label.labelForLabelName(self.contactTitle,
                                               inManagedObjectContext: context),
            let emails = label.emails.allObjects as? [Email] {
            color = label.color
        
            for email in emails {
                let member = DraftEmailData.init(name: email.name,
                                                 email: email.email)
                emailMultiSet.insert(member)
            }
        } else {
            // TODO: handle error
            return errorResponse
        }
        
        // (2) get all that is NOT in the contact group, but is selected
        // Because we might have identical name-email pairs, we can't simply use a set
        //
        // We use the frequency map of all name-email pairs, and we
        // 2a) add pairs that are not present in the emailMultiSet
        // or
        // 2b) update the frequency counter of the emailMultiSet only if tmpMultiSet has a larger value
        for member in self.selectedMembers {
            let count = emailMultiSet[member.key] ?? 0
            if member.value > count {
                for _ in 0..<(member.value - count) {
                    emailMultiSet.insert(member.key)
                }
            }
        }
        
        let memberSelected = self.selectedMembers.reduce(0, {x, y in
            return x + y.value
        })
        let totalMemberCount = emailMultiSet.reduce(0, {
            x, y in
            return x + y.value
        })
        
        return (memberSelected, totalMemberCount, color)
    }
    
    init(ID: String, name: String, groupSize: Int? = nil, color: String? = nil) {
        self.ID = ID
        self.contactTitle = name
        self.groupColor = color
        self.groupSize = groupSize
        
        self.displayName = nil
        self.displayEmail = nil
        self.contactImage = nil
        self.lock = nil
        self.hasPGPPined = false
        self.hasNonePM = false
        self.selectedMembers = MultiSet<DraftEmailData>()
    }
    
    func equals(_ other: ContactPickerModelProtocol) -> Bool {
        return self.isEqual(other)
    }
}
