//
//  SignUp+Error.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/22/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

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
            return LocalString._cant_get_a_moduls_id
        case .invalidModuls:
            return LocalString._cant_get_a_moduls
        case .cantHashPassword:
            return LocalString._invalid_hashed_password
        case .cantGenerateVerifier:
            return LocalString._cant_create_a_srp_verifier
        case .default:
            return LocalString._create_user_failed
        }
    }
}
