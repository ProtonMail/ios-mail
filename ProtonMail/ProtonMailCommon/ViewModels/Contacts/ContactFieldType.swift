//
//  ContactFieldType.swift
//  ProtonMail - Created on 12/29/17.
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

enum ContactFieldType {
    private static let allCases: [ContactFieldType] = [.home, .work, .email, .other, .phone, .mobile, .fax, .address, .url, .internet, .empty]
    
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

    init(raw: String) {
        switch raw {
        case "HOME":
            self = .home
        case "WORK":
            self = .work
        case "EMAIL":
            self = .email
        case "OTHER":
            self = .other
        case "PHONE":
            self = .phone
        case "MOBILE":
            self = .mobile
        case "FAX":
            self = .fax
        case "ADDRESS":
            self = .address
        case "URL":
            self = .url
        case "X-INTERNET", "INTERNET":
            self = .internet
        //default
        case "":
            self = .email
        default:
            self = .custom(raw)
        }
    }
    
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
            return LocalString._contacts_types_home_title
        case .work:
            return LocalString._contacts_types_work_title
        case .email:
            return LocalString._contacts_types_email_title
        case .other:
            return LocalString._contacts_types_other_title
        case .phone:
            return LocalString._contacts_types_phone_title
        case .mobile:
            return LocalString._contacts_types_mobile_title
        case .fax:
            return LocalString._contacts_types_fax_title
        case .address:
            return LocalString._contacts_types_address_title
        case .url:
            return LocalString._contacts_types_url_title
        case .internet:
            return LocalString._contacts_types_internet_title
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

