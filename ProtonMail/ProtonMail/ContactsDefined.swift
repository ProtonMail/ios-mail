//
//  ContactsDefined.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/9/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



protocol ContactEditTypeInterface {
    func getCurrentType() -> ContactFieldType
    func getSectionType() -> ContactEditSectionType
    func updateType(type: ContactFieldType) -> Void
    func types() -> [ContactFieldType]
    func needsUpdate() -> Bool
}

protocol ContactEditNoTypeInterface {
    func getSectionType() -> ContactEditSectionType
    func needsUpdate() -> Bool
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
    var origOrder : Int = 0
    var origType : ContactFieldType = .empty
    var origEmail : String = ""
    var isNew : Bool = false
    
    var newOrder : Int = 0
    var newType : ContactFieldType = .empty
    var newEmail : String = ""
    
    init(order: Int, type: ContactFieldType, email: String, isNew: Bool) {
        self.newOrder = order
        self.newType = type
        self.newEmail = email
        self.origOrder = self.newOrder
        
        self.isNew = isNew
        if !self.isNew {
            self.origType = self.newType
            self.origEmail = self.newEmail
        }
    }
    
    //
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
    
    //to
    func toContactEmail() -> ContactEmail {
        return ContactEmail(e: newEmail, t: newType.vcardType)
    }
    
    func needsUpdate() -> Bool {
        if isNew && newEmail.isEmpty {
            return false
        }
        if origOrder == newOrder &&
            origType == newType &&
            origEmail == newEmail {
            return false
        }
        return true
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

