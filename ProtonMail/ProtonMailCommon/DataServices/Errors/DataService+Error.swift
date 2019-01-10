//
//  UserDataService+Error.swift
//  ProtonMail - Created on 11/14/16.
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


let dataServiceDomain = NSError.protonMailErrorDomain("DataService")

extension NSError {
    
    class func CreateError(_ domain : String,
                           code: Int,
                           localizedDescription: String,
                           localizedFailureReason: String?,
                           localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(
            domain: domain,
            code: code,
            localizedDescription: localizedDescription,
            localizedFailureReason: localizedFailureReason,
            localizedRecoverySuggestion: localizedRecoverySuggestion)
    }
}

protocol CustomErrorVar {
    var code : Int { get }
    
    var desc : String { get }
    
    var reason : String { get }
}

extension CustomErrorVar {
     func toError() -> NSError {
        return NSError.CreateError(dataServiceDomain,
                                   code: code,
                                   localizedDescription: desc,
                                   localizedFailureReason: reason)
    }
    
    var error : NSError {
        get {
            return self.toError()
        }
    }
}


// settings     0x110000
// pwds         0x110 000
// notify email 0x110 100

// code start at 0x110000
enum UpdatePasswordError : Int, Error, CustomErrorVar {
    case invalidUserName = 0x110001
    case invalidModulusID = 0x110002
    case invalidModulus = 0x110003
    case cantHashPassword = 0x110004
    case cantGenerateVerifier = 0x110005
    case cantGenerateSRPClient = 0x110006
    case invalideAuthInfo = 0x110007
    
    // mailbox password part
    case currentPasswordWrong = 0x110008
    case newNotMatch = 0x110009
    case passwordEmpty = 0x110010
    case keyUpdateFailed = 0x110011
    
    case `default` = 0x110000
    
    var code : Int {
        return self.rawValue
    }
    
    var desc : String {
        return LocalString._change_password
    }
    
    var reason : String {
        switch self {
        case .invalidUserName:
            return LocalString._error_invalid_username
        case .invalidModulusID:
            return LocalString._cant_get_a_moduls_id
        case .invalidModulus:
            return LocalString._cant_get_a_moduls
        case .cantHashPassword:
            return LocalString._invalid_hashed_password
        case .cantGenerateVerifier:
            return LocalString._cant_create_a_srp_verifier
        case .cantGenerateSRPClient:
            return LocalString._cant_create_a_srp_client
        case .invalideAuthInfo:
            return LocalString._cant_get_user_auth_info
        case .currentPasswordWrong:
            return LocalString._the_password_is_wrong
        case .newNotMatch:
            return LocalString._the_new_password_not_match
        case .passwordEmpty:
            return LocalString._the_new_password_cant_empty
        case .keyUpdateFailed:
            return LocalString._the_private_key_update_failed
        case .default:
            return LocalString._password_update_failed
        }
    }
}


// code start at 0x110100
enum UpdateNotificationEmailError : Int, Error, CustomErrorVar {
    case invalidUserName = 0x110101
    case cantHashPassword = 0x110102
    case cantGenerateVerifier = 0x110103
    case cantGenerateSRPClient = 0x110104
    case invalideAuthInfo = 0x110105
    
    case `default` = 0x110100
    
    var code : Int {
        return self.rawValue
    }
    
    var desc : String {
        return LocalString._update_notification_email
    }
    
    var reason : String {
        switch self {
        case .invalidUserName:
            return LocalString._error_invalid_username
        case .cantHashPassword:
            return LocalString._invalid_hashed_password
        case .cantGenerateVerifier:
            return LocalString._cant_create_a_srp_verifier
        case .cantGenerateSRPClient:
            return LocalString._cant_create_a_srp_client
        case .invalideAuthInfo:
            return LocalString._cant_get_user_auth_info
        case .default:
            return LocalString._password_update_failed
        }
    }
}



