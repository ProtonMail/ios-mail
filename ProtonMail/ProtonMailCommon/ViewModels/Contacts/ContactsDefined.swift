//
//  ContactsDefined.swift
//  ProtonMail - Created on 6/9/17.
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



protocol ContactEditTypeInterface {
    func getCurrentType() -> ContactFieldType
    func getSectionType() -> ContactEditSectionType
    func updateType(type: ContactFieldType) -> Void
    func types() -> [ContactFieldType]
    func needsUpdate() -> Bool
    
    func isEmpty() -> Bool
}

protocol ContactEditNoTypeInterface {
    func getSectionType() -> ContactEditSectionType
    func needsUpdate() -> Bool
    func isEmpty() -> Bool
}

final class ContactEditProfile {
    var origDisplayName : String = ""
    var isNew : Bool = false
    
    var newDisplayName : String = ""
    
    init(n_displayname: String) {
        self.newDisplayName = n_displayname
        self.isNew = true
    }
    
    init(n_displayname: String, isNew: Bool) {
        self.origDisplayName = n_displayname
        self.newDisplayName = n_displayname
        self.isNew = isNew
    }
    
    init(o_displayname : String) {
        self.origDisplayName = o_displayname
        self.newDisplayName = o_displayname
        self.isNew = false
    }
    
    func needsUpdate() -> Bool {
        if isNew && newDisplayName.isEmpty {
            return false
        }
        if origDisplayName == newDisplayName {
            return false
        }
        return true
    }
}


final class ContactEditEmail: ContactEditTypeInterface {
    private var origOrder = 0
    private var origType: ContactFieldType = .empty
    private var origEmail = ""
    private var origContactGroupIDs = Set<String>() // the selection state when init is called
    private var isNew = false

    private var newContactGroupIDs = Set<String>() // the current selection state
    private var newOrder = 0
    var newType: ContactFieldType = .empty
    var newEmail = ""
    
    var keys: [PMNIKey]?
    var encrypt: PMNIPMEncrypt?
    var sign: PMNIPMSign?
    var scheme: PMNIPMScheme?
    var mimeType: PMNIPMMimeType?
    
    private let delegate: ContactEditViewModelContactGroupDelegate?
    private let coreDataService: CoreDataService
    
    init(order: Int,
         type: ContactFieldType,
         email: String,
         isNew: Bool,
         keys : [PMNIKey]?,
         contactID: String?,
         encrypt : PMNIPMEncrypt?,
         sign : PMNIPMSign?,
         scheme : PMNIPMScheme?,
         mimeType: PMNIPMMimeType?,
         delegate: ContactEditViewModelContactGroupDelegate?,
         coreDataService: CoreDataService) {
        self.delegate = delegate
        self.coreDataService = coreDataService
        
        self.newOrder = order
        self.newType = type
        self.newEmail = email
        if let contactID = contactID {
            self.getContactGroupIDsFromCoreData(contactID: contactID)
        } else {
            origContactGroupIDs.removeAll()
            newContactGroupIDs.removeAll()
        }
        self.origOrder = self.newOrder
        
        self.keys = keys
        self.encrypt = encrypt
        self.sign = sign
        self.scheme = scheme
        self.mimeType = mimeType
        
        self.isNew = isNew
        if !self.isNew {
            self.origType = self.newType
            self.origEmail = self.newEmail
            self.origContactGroupIDs = self.newContactGroupIDs
        }
    }
    
    func getCurrentType() -> ContactFieldType {
        return newType
    }
    func getSectionType() -> ContactEditSectionType {
        return .emails
    }
    func updateType(type: ContactFieldType) -> Void {
        newType = type
    }
    
    func types() -> [ContactFieldType] {
        return ContactFieldType.emailTypes
    }
    
    // to
    func toContactEmail() -> ContactEmail {
        return ContactEmail(e: newEmail, t: newType.vcardType)
    }
    
    private func getContactGroupIDsFromCoreData(contactID: String) {
        // we decide to stick with using core data information for now
        origContactGroupIDs.removeAll()
        
        let context = self.coreDataService.mainManagedObjectContext
        let emailObject = Email.EmailForAddressWithContact(self.newEmail,
                                                           contactID: contactID,
                                                           inManagedObjectContext: context)
        if let emailObject = emailObject {
            if let contactGroups = emailObject.labels.allObjects as? [Label] {
                for contactGroup in contactGroups {
                    origContactGroupIDs.insert(contactGroup.labelID)
                }
            } else {
                // TODO: handle error
                PMLog.D("Can't get contact groups")
            }
        } else {
            // TODO: handle error
            PMLog.D("Can't get email from address")
        }
        
        newContactGroupIDs = origContactGroupIDs
    }
    
    func getContactGroupNames() -> [String] {
        var result: [String] = []
        for labelID in newContactGroupIDs {
            let context = self.coreDataService.mainManagedObjectContext
            if let label = Label.labelForLableID(labelID, inManagedObjectContext: context) {
                result.append(label.name)
            } else {
                // TODO: handle error
                PMLog.D(("Can't get label from ID"))
            }
        }
        
        return result
    }
    
    // contact group
    /**
     - Returns: all currently selected contact group IDs
    */
    func getCurrentlySelectedContactGroupsID() -> Set<String> {
        return newContactGroupIDs
    }
    
    /**
     - Returns: all currently selected contact group's color
    */
    func getCurrentlySelectedContactGroupColors() -> [String] {
        var colors = [String]()
        
        let context = self.coreDataService.mainManagedObjectContext
        for ID in newContactGroupIDs {
            let label = Label.labelForLableID(ID, inManagedObjectContext: context)
            
            if let label = label {
                colors.append(label.color)
            } else {
                // TODO: handle error
                PMLog.D("Can't retrieve label by ID")
            }
        }
        
        return colors
    }
    
    /**
     Update the selected contact group information for this email
    */
    func updateContactGroups(updatedContactGroups: Set<String>) {
        let currentSet = newContactGroupIDs
        
        // perform diffing
        let increase = updatedContactGroups.subtracting(currentSet) // the contact groups that requires +1 to their count
        let decrease = currentSet.subtracting(updatedContactGroups) // the contact groups that requires -1 to their count
        
        delegate?.updateContactCounts(increase: true, contactGroups: increase)
        delegate?.updateContactCounts(increase: false, contactGroups: decrease)
        
        // update
        newContactGroupIDs = updatedContactGroups
    }
    
    // update
    func needsUpdate() -> Bool {
        if isNew && newEmail.isEmpty {
            return false
        }
        
        if origOrder == newOrder &&
            origType == newType &&
            origEmail == newEmail &&
            origContactGroupIDs == newContactGroupIDs {
            return false
        }
        return true
    }
    
    func isEmpty() -> Bool {
        return newEmail.isEmpty
    }
}

final class ContactEditPhone: ContactEditTypeInterface {
    var origOrder : Int = 0
    var origType : ContactFieldType = .empty
    var origPhone : String = ""
    var isNew : Bool = false
    
    var newOrder : Int = 0
    var newType : ContactFieldType = .empty
    var newPhone : String = ""
    
    init(order: Int, type: ContactFieldType, phone:String, isNew: Bool) {
        self.newType = type
        self.newOrder = order
        self.origOrder = self.newOrder
        self.newPhone = phone
        self.isNew = isNew
        if !self.isNew {
            self.origType = self.newType
            self.origPhone = self.newPhone
        }
    }
    
    //
    func getCurrentType() -> ContactFieldType {
        return newType
    }
    func getSectionType() -> ContactEditSectionType {
        return .cellphone
    }
    func updateType(type: ContactFieldType) -> Void {
        newType = type
    }
    func types() -> [ContactFieldType] {
        return ContactFieldType.phoneTypes
    }
    
    func needsUpdate() -> Bool {
        if isNew && newPhone.isEmpty {
            return false
        }
        if origOrder == newOrder &&
            origType == newType &&
            origPhone == newPhone {
            return false
        }
        return true
    }
    
    func isEmpty() -> Bool {
        return newPhone.isEmpty
    }
}

//url
final class ContactEditUrl: ContactEditTypeInterface {
    var origOrder : Int = 0
    var origType : ContactFieldType = .empty
    var origUrl : String = ""
    var isNew : Bool = false
    
    var newOrder : Int = 0
    var newType : ContactFieldType = .empty
    var newUrl : String = ""
    
    init(order: Int, type: ContactFieldType, url: String, isNew: Bool) {
        self.newType = type
        self.newOrder = order
        self.origOrder = self.newOrder
        self.newUrl = url
        self.isNew = isNew
        if !self.isNew {
            self.origType = self.newType
            self.origUrl = self.newUrl
        }
    }
    
    //
    func getCurrentType() -> ContactFieldType {
        return newType
    }
    func getSectionType() -> ContactEditSectionType {
        return .cellphone
    }
    func updateType(type: ContactFieldType) -> Void {
        newType = type
    }
    func types() -> [ContactFieldType] {
        return ContactFieldType.urlTypes
    }
    
    func needsUpdate() -> Bool {
        if isNew && newUrl.isEmpty {
            return false
        }
        if origOrder == newOrder &&
            origType.rawString == newType.rawString &&
            origUrl == newUrl {
            return false
        }
        return true
    }
    
    func isEmpty() -> Bool {
        return newUrl.isEmpty
    }
}

//address
final class ContactEditAddress: ContactEditTypeInterface {
    var origOrder : Int = 0
    var origType : ContactFieldType = .empty
    var origPoxbox : String = ""
    var origStreet : String = ""
    var origStreetTwo: String = ""
    var origLocality : String = ""
    var origRegion : String = ""
    var origPostal : String = ""
    var origCountry : String = ""
    var isNew : Bool = false
    
    var newOrder : Int = 0
    var newType : ContactFieldType = .empty
    var newPoxbox : String = ""
    var newStreet : String = ""
    var newStreetTwo: String = ""
    var newLocality : String = ""
    var newRegion : String = ""
    var newPostal : String = ""
    var newCountry : String = ""
    
    init(order: Int, type: ContactFieldType,
         pobox: String, street: String, streetTwo: String, locality: String,
         region: String, postal: String, country: String, isNew: Bool) {
        
        self.newOrder = order
        self.origOrder = self.newOrder
        self.newType = type
        self.newPoxbox = pobox
        self.newStreet = street
        self.newStreetTwo = streetTwo
        self.newLocality = locality
        self.newRegion = region
        self.newPostal = postal
        self.newCountry = country
        
        self.isNew = isNew
        
        if !self.isNew {
            self.origType = self.newType
            self.origPoxbox = self.newPoxbox
            self.origStreet = self.newStreet
            self.origStreetTwo = self.newStreetTwo
            self.origLocality = self.newLocality
            self.origRegion = self.newRegion
            self.origPostal = self.newPostal
            self.origCountry = self.newCountry
        }
    }
    
    convenience init(order: Int, type: ContactFieldType) {
        self.init(order: order, type: type, pobox: "", street: "", streetTwo: "", locality: "", region: "", postal: "", country: "", isNew: true)
    }
    
    //
    func getCurrentType() -> ContactFieldType {
        return newType
    }
    func getSectionType() -> ContactEditSectionType {
        return .home_address
    }
    func updateType(type: ContactFieldType) -> Void {
        newType = type
    }
    func types() -> [ContactFieldType] {
        return ContactFieldType.addrTypes
    }
    
    func fullAddress() -> String {
        var full : String = newPoxbox
        if full.isEmpty {
            full = newStreet
        } else {
            full += " "
            full += newStreet
        }
        
        if !newStreetTwo.isEmpty {
            full += " "
            full += newStreetTwo
        }
        
        full += " "
        full += newLocality
        full += " "
        full += newRegion
        full += " "
        full += newPostal
        full += " "
        full += newCountry
        return full
    }
    
    func needsUpdate() -> Bool {
        if isNew &&
            self.newPoxbox.isEmpty &&
            self.newStreet.isEmpty &&
            self.newStreetTwo.isEmpty &&
            self.newLocality.isEmpty &&
            self.newRegion.isEmpty &&
            self.newPostal.isEmpty &&
            self.newCountry.isEmpty {
            return false
        }
        
        if  self.origType == self.newType &&
            self.origPoxbox == self.newPoxbox &&
            self.origStreet == self.newStreet &&
            self.origStreetTwo == self.newStreetTwo &&
            self.origLocality == self.newLocality &&
            self.origRegion == self.newRegion &&
            self.origPostal == self.newPostal &&
            self.origCountry == self.newCountry &&
            self.origOrder == self.newOrder {
            return false
        }
        return true
    }
    
    func isEmpty() -> Bool {
        if self.newStreet.isEmpty &&
            self.newStreetTwo.isEmpty &&
            self.newLocality.isEmpty &&
            self.newRegion.isEmpty &&
            self.newPostal.isEmpty &&
            self.newCountry.isEmpty {
            return true
        }
        return false
    }
}


//informations part
final class ContactEditInformation: ContactEditNoTypeInterface {
    
    var infoType : InformationType
    var origValue : String = ""
    var isNew : Bool = false
    
    var newValue : String = ""
    
    init(type: InformationType, value: String, isNew: Bool) {
        self.infoType = type
        self.newValue = value
        self.isNew = isNew
        
        if !self.isNew {
            self.origValue = self.newValue
        }
    }
    
    func getSectionType() -> ContactEditSectionType {
        return .information
    }
    
    func needsUpdate() -> Bool {
        if isNew && newValue.isEmpty {
            return false
        }
        if self.origValue == self.newValue {
            return false
        }
        return true
    }
    
    func isEmpty() -> Bool {
        return newValue.isEmpty
    }
}

//custom field
final class ContactEditField: ContactEditTypeInterface {
    
    var origOrder : Int = 0
    var origType : ContactFieldType = .empty
    var origField : String = ""
    var isNew : Bool = false
    
    var newOrder : Int = 0
    var newType : ContactFieldType = .empty
    var newField : String = ""
    
    init(order: Int, type: ContactFieldType, field:String, isNew: Bool) {
        self.newType = type
        self.newOrder = order
        self.newField = field
        self.isNew = isNew
        self.origOrder = self.newOrder
        
        if !self.isNew {
            self.origType = self.newType
            self.origField = self.newField
        }
    }
    
    //
    func getCurrentType() -> ContactFieldType {
        return newType
    }
    func getSectionType() -> ContactEditSectionType {
        return .custom_field
    }
    func updateType(type: ContactFieldType) -> Void {
        newType = type
    }
    func types() -> [ContactFieldType] {
        return ContactFieldType.fieldTypes
    }
    
    func needsUpdate() -> Bool {
        if isNew && self.newField.isEmpty && self.newType == .empty {
            return false
        }
        if origOrder == newOrder &&
            origType == newType &&
            origField == newField {
            return false
        }
        return true
    }
    
    func isEmpty() -> Bool {
        return newField.isEmpty
    }
}

final class ContactEditNote {
    var origNote : String = ""
    var isNew : Bool = false
    
    var newNote : String = ""
    init(note:String, isNew: Bool) {
        self.newNote = note
        self.isNew = isNew
        if !self.isNew {
            self.origNote = self.newNote
        }
    }
    
    func needsUpdate() -> Bool {
        if isNew && self.newNote.isEmpty {
            return false
        }
        if self.origNote == self.newNote {
            return false
        }
        return true
    }
}

