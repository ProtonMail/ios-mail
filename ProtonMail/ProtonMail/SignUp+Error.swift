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
        return NSLocalizedString("Update Notification Email") //TODO:: check with jason for localization
    }
    
    var reason : String {
        switch self {
        case .invalidModulsID:
            return NSLocalizedString("Can't get a Moduls ID!")
        case .invalidModuls:
            return NSLocalizedString("Can't get a Moduls!")
        case .cantHashPassword:
            return NSLocalizedString("Invalid hashed password!")
        case .cantGenerateVerifier:
            return NSLocalizedString("Can't create a SRP verifier!")
        case .default:
            return NSLocalizedString("Create user failed")
        }
    }
}
