//
//  ContactsDefined.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/9/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



protocol ContactEditTypeInterface {
    func getCurrentType() -> String
    func getSectionType() -> ContactEditSectionType
    func updateType(type: String) -> Void
    func types() -> [String]
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


//email part
enum ContactEmailType : String {
    case Home = "Home"
    case Work = "Work"
    case Email = "Email"
    case Other = "Other"
    static let allValues = [Home.rawValue,
                            Work.rawValue,
                            Email.rawValue,
                            Other.rawValue] as [String]
}

final class ContactEditEmail: ContactEditTypeInterface {
    var origOrder : Int = 0
    var origType : String = ""
    var origEmail : String = ""
    var isNew : Bool = false
    
    var newOrder : Int = 0
    var newType : String = ""
    var newEmail : String = ""
    
    init(order: Int, type: String, email: String, isNew: Bool) {
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
    func getCurrentType() -> String {
        return newType
    }
    func getSectionType() -> ContactEditSectionType {
        return .emails
    }
    func updateType(type: String) -> Void {
        newType = type
    }
    
    func types() -> [String] {
        return ContactEmailType.allValues
    }
    
    //to
    func toContactEmail() -> ContactEmail {
        return ContactEmail(e: newEmail, t: newType)
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

class staticStrings {
    static let home = NSLocalizedString("Home", comment: "default vcard types")
    static let work = NSLocalizedString("Work", comment: "default vcard types")
    static let mobile = NSLocalizedString("Mobile", comment: "default vcard types")
    static let email = NSLocalizedString("Email", comment: "default vcard types")
    static let main = NSLocalizedString("Main", comment: "default vcard types")
    static let homefax = NSLocalizedString("Home Fax", comment: "default vcard types")
    static let workfax = NSLocalizedString("Work Fax", comment: "default vcard types")
    static let other = NSLocalizedString("Other", comment: "default vcard types")
    static let voice = NSLocalizedString("Voice", comment: "default vcard types")
    static let fax = NSLocalizedString("Fax", comment: "default vcard types")
    
}


//phone part
enum ContactPhoneType : String {
    case Home = "Home"
    case Work = "Work"
    case Mobile = "Mobile"
    case iPhone = "Email"
    case Main = "Main"
    case FHome = "Home Fax"
    case FWork = "Work Fax"
    case Other = "Other"
    static let allValues = [Home.rawValue,
                            Work.rawValue,
                            Mobile.rawValue,
                            iPhone.rawValue,
                            Main.rawValue,
                            FHome.rawValue,
                            FWork.rawValue,
                            Other.rawValue] as [String]
}
final class ContactEditPhone: ContactEditTypeInterface {
    var origOrder : Int = 0
    var origType : String = ""
    var origPhone : String = ""
    var isNew : Bool = false
    
    var newOrder : Int = 0
    var newType : String = ""
    var newPhone : String = ""
    
    init(order: Int, type: String, phone:String, isNew: Bool) {
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
    func getCurrentType() -> String {
        return newType
    }
    func getSectionType() -> ContactEditSectionType {
        return .cellphone
    }
    func updateType(type: String) -> Void {
        newType = type
    }
    func types() -> [String] {
        return ContactPhoneType.allValues
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

//address
enum ContactAddressType : String {
    case Home = "Home"
    case Work = "Work"
    case Other = "Other"
    static let allValues = [Home.rawValue,
                            Work.rawValue,
                            Other.rawValue] as [String]
}
final class ContactEditAddress: ContactEditTypeInterface {
    var origOrder : Int = 0
    var origType : String = ""
    var origPoxbox : String = ""
    var origStreet : String = ""
    var origLocality : String = ""
    var origRegion : String = ""
    var origPostal : String = ""
    var origCountry : String = ""
    var isNew : Bool = false
    
    var newOrder : Int = 0
    var newType : String = ""
    var newPoxbox : String = ""
    var newStreet : String = ""
    var newLocality : String = ""
    var newRegion : String = ""
    var newPostal : String = ""
    var newCountry : String = ""
    
    init(order: Int, type: String,
         pobox: String, street: String, locality: String,
         region: String, postal: String, country: String, isNew: Bool) {
        
        self.newOrder = order
        self.origOrder = self.newOrder
        self.newType = type
        self.newPoxbox = pobox
        self.newStreet = street
        self.newLocality = locality
        self.newRegion = region
        self.newPostal = postal
        self.newCountry = country
        
        self.isNew = isNew
        
        if !self.isNew {
            self.origType = self.newType
            self.origPoxbox = self.newPoxbox
            self.origStreet = self.newStreet
            self.origLocality = self.newLocality
            self.origRegion = self.newRegion
            self.origPostal = self.newPostal
            self.origCountry = self.newCountry
        }
    }
    
    convenience init(order: Int, type: String) {
        self.init(order: order, type: type, pobox: "", street: "", locality: "", region: "", postal: "", country: "", isNew: true)
    }
    
    //
    func getCurrentType() -> String {
        return newType
    }
    func getSectionType() -> ContactEditSectionType {
        return .home_address
    }
    func updateType(type: String) -> Void {
        newType = type
    }
    func types() -> [String] {
        return ContactAddressType.allValues
    }
    
    func fullAddress() -> String {
        var full : String = newPoxbox
        if full.isEmpty {
            full = newStreet
        } else {
            full += " "
            full += newStreet
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
            self.newLocality.isEmpty &&
            self.newRegion.isEmpty &&
            self.newPostal.isEmpty &&
            self.newCountry.isEmpty {
            return false
        }
        
        if  self.origType == self.newType &&
            self.origPoxbox == self.newPoxbox &&
            self.origStreet == self.newStreet &&
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
    
    init(type: InformationType, value: String) {
        self.infoType = type
        self.newValue = value
        self.isNew = true
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
enum ContactFieldType : String {
    case Home = "Home"
    case Work = "Work"
    case Other = "Other"
    static let allValues = [Home.rawValue,
                            Work.rawValue,
                            Other.rawValue] as [String]
}
final class ContactEditField: ContactEditTypeInterface {
    var origOrder : Int = 0
    var origType : String = ""
    var origField : String = ""
    var isNew : Bool = false
    
    var newOrder : Int = 0
    var newType : String = ""
    var newField : String = ""
    
    init(order: Int, type: String, field:String, isNew: Bool) {
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
    func getCurrentType() -> String {
        return newType
    }
    func getSectionType() -> ContactEditSectionType {
        return .custom_field
    }
    func updateType(type: String) -> Void {
        newType = type
    }
    func types() -> [String] {
        return ContactFieldType.allValues
    }
    
    func needsUpdate() -> Bool {
        if isNew && self.newField.isEmpty && self.newType.isEmpty {
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

