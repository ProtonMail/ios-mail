//
//  ContactFieldType.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/29/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation




enum ContactFieldType {
    //raw value is the type
    case home
    case work
    case email
    case other
    
    //
    case phone
    case mobile
    case fax
    
    //
    case address
    
    //default
    case empty
    case custom(String)
    
    var rawValue : String {
        switch self {
        case .home:
            return "HOME"
        case .work:
            return "WORK"
        case .email:
            return "EMAIL"
        case .other:
            return "OTHER"
        case .phone:
            return "PHONE"
        case .mobile:
            return "MOBILE"
        case .fax:
            return "FAX"
        case .address:
            return "ADDRESS"
            
        //default
        case .empty:
            return ""
        case .custom(let value):
            return value
        }
    }
    
    //display title
    var title : String {
        switch self {
        case .home: //renamed to Personal
            return NSLocalizedString("Personal", comment: "default vcard types")
        case .work:
            return NSLocalizedString("Work", comment: "default vcard types")
        case .email:
            return NSLocalizedString("Email", comment: "default vcard types")
        case .other:
            return NSLocalizedString("Other", comment: "default vcard types")
            
        default:
            return self.rawValue
        }
    }
    
    var isCustom: Bool {
        switch self {
        case .custom( _ ):
            return true
        default:
            return false
        }
    }
    var isEmpty: Bool {
        switch self {
        case .empty:
            return true
        default:
            return false
        }
    }
}

extension ContactFieldType : Equatable {
    
}

extension ContactFieldType {

    static func get(raw: String) -> ContactFieldType {
        let uper = raw.uppercased()
        switch uper {
        case ContactFieldType.home.rawValue:
            return .home
        case ContactFieldType.work.rawValue:
            return .work
        case ContactFieldType.email.rawValue:
            return .email
        case ContactFieldType.other.rawValue:
            return .other
        case ContactFieldType.phone.rawValue:
            return .phone
        case ContactFieldType.mobile.rawValue:
            return .mobile
        case ContactFieldType.fax.rawValue:
            return .fax
        case ContactFieldType.address.rawValue:
            return .address
        case ContactFieldType.empty.rawValue:
            return .empty
        default:
            return ContactFieldType.custom(raw)
        }
    }
}

func ==(lhs: ContactFieldType, rhs: ContactFieldType) -> Bool {
    switch (lhs, rhs) {
    case (let .custom(lvalue), let .custom(rvalue)):
        return lvalue == rvalue
    case (.home, .home):
        return true
    case (.work, .work):
        return true
    case (.email, .email):
        return true
    case (.other, .other):
        return true
    case (.phone, .phone):
        return true
    case (.mobile, .mobile):
        return true
    case (.fax, .fax):
        return true
    case (.address, .address):
        return true
    case (.empty, .empty):
        return true
    default:
        return false
    }
}


extension ContactFieldType {
    //email part
    static let emailTypes : [ContactFieldType] = [ .email,
                                                   .home,
                                                   .work,
                                                   .other]
    
    static let phoneTypes : [ContactFieldType] = [ .phone,
                                                   .mobile,
                                                   .work,
                                                   .fax,
                                                   .other]
    
    static let addrTypes : [ContactFieldType] = [ .address,
                                                  .home,
                                                  .work,
                                                  .other]
    
    //custom field
    static let fieldTypes : [ContactFieldType] = [ .other ]
    
}


//
//class staticStrings {
//    static let home = NSLocalizedString("Home", comment: "default vcard types")
//    static let work = NSLocalizedString("Work", comment: "default vcard types")
//    static let mobile = NSLocalizedString("Mobile", comment: "default vcard types")
//    static let email = NSLocalizedString("Email", comment: "default vcard types")
//    static let main = NSLocalizedString("Main", comment: "default vcard types")
//    static let homefax = NSLocalizedString("Home Fax", comment: "default vcard types")
//    static let workfax = NSLocalizedString("Work Fax", comment: "default vcard types")
//    static let other = NSLocalizedString("Other", comment: "default vcard types")
//    static let voice = NSLocalizedString("Voice", comment: "default vcard types")
//    static let fax = NSLocalizedString("Fax", comment: "default vcard types")
//
//}

