//
//  UserDataService+Error.swift
//  ProtonMail - Created on 11/14/16.
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
    
    case minimumLengthError = 0x110012
    
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
        case .minimumLengthError:
            return LocalString._password_needs_at_least_8_chars
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



