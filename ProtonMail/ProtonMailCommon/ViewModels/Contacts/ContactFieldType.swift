//
//  ContactFieldType.swift
//  ProtonMail - Created on 12/29/17.
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

