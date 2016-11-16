//
//  UserDataService+Error.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/14/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation


let dataServiceDomain = NSError.protonMailErrorDomain("DataService")

extension NSError {
    
    class func CreateError(domain : String,
                           code: Int,
                           localizedDescription: String,
                           localizedFailureReason: String?, localizedRecoverySuggestion: String? = nil) -> NSError {
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
}


// code start at 0x110000
enum UpdatePasswordError : Int, ErrorType, CustomErrorVar {
    case InvalidUserName = 0x110001
    case InvalidModulsID = 0x110002
    case InvalidModuls = 0x110003
    case CantHashPassword = 0x110004
    case CantGenerateVerifier = 0x110005
    case CantGenerateSRPClient = 0x110006
    case InvalideAuthInfo = 0x110007
    
    // mailbox password part
    case CurrentPasswordWrong = 0x110008
    case NewNotMatch = 0x110009
    case PasswordEmpty = 0x110010
    case KeyUpdateFailed = 0x110011
    
    case Default = 0x110000
    
    var code : Int {
        return self.rawValue
    }
    
    var desc : String {
        return NSLocalizedString("Change Password") //TODO:: check with jason for localization
    }
    
    var reason : String {
        switch self {
        case .InvalidUserName:
            return NSLocalizedString("Invalid UserName!")
        case .InvalidModulsID:
            return NSLocalizedString("Can't get a Moduls ID!")
        case .InvalidModuls:
            return NSLocalizedString("Can't get a Moduls!")
        case .CantHashPassword:
            return NSLocalizedString("Invalid hashed password!")
        case .CantGenerateVerifier:
            return NSLocalizedString("Can't create a SRP verifier!")
        case .CantGenerateSRPClient:
            return NSLocalizedString("Can't create a SRP Client")
        case .InvalideAuthInfo:
            return NSLocalizedString("Can't get user auth info")
        case .CurrentPasswordWrong:
            return NSLocalizedString("The Password is wrong.")
        case .NewNotMatch:
            return NSLocalizedString("The new password not match.")
        case .PasswordEmpty:
            return NSLocalizedString("The new password can't empty.")
        case .KeyUpdateFailed:
            return NSLocalizedString("The private update failed.")
        case .Default:
            return NSLocalizedString("Password update failed")
        }
    }
}



