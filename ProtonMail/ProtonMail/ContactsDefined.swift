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
    
    init(n_displayname:String) {
        self.newDisplayName = n_displayname
        self.isNew = true
    }
    init(n_displayname: String, isNew: Bool) {
        self.newDisplayName = n_displayname
        self.isNew = isNew
    }
    
    init(o_displayname : String) {
        self.origDisplayName = o_displayname
        self.newDisplayName = o_displayname
        self.isNew = false
    }
    
    func needsUpdate() -> Bool {
        if isNew {
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
    
    init(n_order: Int, n_type: String, n_email:String) {
        self.newType = n_type
        self.newOrder = n_order
        self.newEmail = n_email
        self.isNew = true
    }
    
    init(o_order: Int, o_type: String, o_email:String) {
        self.origOrder = o_order
        self.origType = o_type
        self.origEmail = o_email
        
        self.newOrder = o_order
        self.newType = o_type
        self.newEmail = o_email
        
        self.isNew = false
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
        if isNew {
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
    
    init(n_order: Int, n_type: String, n_phone:String) {
        self.newType = n_type
        self.newOrder = n_order
        self.newPhone = n_phone
        self.isNew = true
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
        if isNew {
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
    var origStreet : String = ""
    var isNew : Bool = false
    
    var newOrder : Int = 0
    var newType : String = ""
    var newStreet : String = ""
    
    init(n_order: Int, n_type: String, n_street:String) {
        self.newType = n_type
        self.newOrder = n_order
        self.newStreet = n_street
        self.isNew = true
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
    
    func needsUpdate() -> Bool {
        if isNew {
            return false
        }
        if origOrder == newOrder &&
            origType == newType &&
            origStreet == newStreet {
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
        if isNew {
            return false
        }
        if origValue == origValue {
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
    
    init(n_order: Int, n_type: String, n_field:String) {
        self.newType = n_type
        self.newOrder = n_order
        self.newField = n_field
        self.isNew = true
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
        if isNew {
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
    init(n_note:String) {
        self.newNote = n_note
        self.isNew = true
    }
    
    func needsUpdate() -> Bool {
        if isNew {
            return false
        }
        if origNote == newNote {
            return false
        }
        return true
    }
}

