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
enum UpdatePasswordError : ErrorType, CustomErrorVar {
    case InvalidUserName
    case InvalidModuls
    case CantHashPassword
    
    var code : Int {
        return 0x110000
    }
    
    var desc : String {
        return NSLocalizedString("Change Password")
    }
    
    var reason : String {
        return "Update failed"
    }
}





