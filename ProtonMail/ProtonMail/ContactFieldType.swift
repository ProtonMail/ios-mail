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
    
    //
    case url
    
    //custom
    case internet
    
    //default
    case empty
    case custom(String)
    
    var rawString : String {
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
        case .url:
            return "URL"
        case .internet:
            return "X-INTERNET"
        //default
        case .empty:
            return ""
        case .custom(let value):
            return value
        }
    }
    
    var vcardType : String {
        switch self {
        case .home:
            return "HOME"
        case .work:
            return "WORK"
        case .other:
            return "OTHER"
        case .mobile:
            return "MOBILE"
        case .fax:
            return "FAX"
        case .internet:
            return "x-internet"
        case .email, .address, .phone, .empty, .url:
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
        case .phone:
            return NSLocalizedString("Phone", comment: "default vcard types")
        case .mobile:
            return NSLocalizedString("Mobile", comment: "default vcard types")
        case .fax:
            return NSLocalizedString("Fax", comment: "default vcard types")
        case .address:
            return NSLocalizedString("Address", comment: "default vcard types")
        case .url:
            return NSLocalizedString("URL", comment: "default vcard types")
        case .internet:
            return NSLocalizedString("Internet", comment: "default vcard types")
        default:
            return self.rawString
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
        case ContactFieldType.home.rawString:
            return .home
        case ContactFieldType.work.rawString:
            return .work
        case ContactFieldType.email.rawString:
            return .email
        case ContactFieldType.other.rawString:
            return .other
        case ContactFieldType.phone.rawString:
            return .phone
        case ContactFieldType.mobile.rawString:
            return .mobile
        case ContactFieldType.fax.rawString:
            return .fax
        case ContactFieldType.address.rawString:
            return .address
        case ContactFieldType.empty.rawString:
            return .empty
        case ContactFieldType.internet.rawString:
            return .internet
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
    
    static let urlTypes : [ContactFieldType] = [ .url,
                                                 .home,
                                                 .work,
                                                 .other]
    
    //custom field
    static let fieldTypes : [ContactFieldType] = [ .other ]
    
}

