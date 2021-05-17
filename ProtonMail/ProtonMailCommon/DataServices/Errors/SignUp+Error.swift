//
//  SignUp+Error.swift
//  ProtonMail - Created on 12/22/16.
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


// code start at 0x110200
enum SignUpCreateUserError : Int, Error, CustomErrorVar {
    case invalidModulsID = 0x110201
    case invalidModuls = 0x110202
    case cantHashPassword = 0x110203
    case cantGenerateVerifier = 0x110204
    
    case `default` = 0x110200
    
    var code : Int {
        return self.rawValue
    }
    
    var desc : String {
        return LocalString._update_notification_email
    }
    
    var reason : String {
        switch self {
        case .invalidModulsID:
            return LocalString._cant_get_a_modulus_id
        case .invalidModuls:
            return LocalString._cant_get_a_modulus
        case .cantHashPassword:
            return LocalString._invalid_hashed_password
        case .cantGenerateVerifier:
            return LocalString._cant_create_a_srp_verifier
        case .default:
            return LocalString._create_user_failed
        }
    }
}
