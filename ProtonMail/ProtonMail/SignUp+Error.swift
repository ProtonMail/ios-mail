//
//  SignUp+Error.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/22/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation




// code start at 0x110200
enum SignUpCreateUserError : Int, ErrorType, CustomErrorVar {
    case InvalidModulsID = 0x110201
    case InvalidModuls = 0x110202
    case CantHashPassword = 0x110203
    case CantGenerateVerifier = 0x110204
    
    case Default = 0x110200
    
    var code : Int {
        return self.rawValue
    }
    
    var desc : String {
        return NSLocalizedString("Update Notification Email") //TODO:: check with jason for localization
    }
    
    var reason : String {
        switch self {
        case .InvalidModulsID:
            return NSLocalizedString("Can't get a Moduls ID!")
        case .InvalidModuls:
            return NSLocalizedString("Can't get a Moduls!")
        case .CantHashPassword:
            return NSLocalizedString("Invalid hashed password!")
        case .CantGenerateVerifier:
            return NSLocalizedString("Can't create a SRP verifier!")
        case .Default:
            return NSLocalizedString("Create user failed")
        }
    }
}
