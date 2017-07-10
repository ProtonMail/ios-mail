//
//  APIErrors.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/20/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

class APIErrorCode {
    static let responseOK = 1000
    
    static let HTTP503 = 503
    static let HTTP504 = 504
    
    static let badParameter = 1
    static let badPath = 2
    static let unableToParseResponse = 3
    static let badResponse = 4
    
    struct AuthErrorCode {
        static let credentialExpired = 10
        static let credentialInvalid = 20
        static let invalidGrant = 30
        static let unableToParseToken = 40
        static let localCacheBad = 50
        static let networkIusse = 60
        static let unableToParseAuthInfo = 70
        static let authServerSRPInValid = 80
        static let authUnableToGenerateSRP = 90
        static let authUnableToGeneratePwd = 100
        static let authInValidKeySalt = 110
        
        static let Cache_PasswordEmpty = 0x10000001
    }
    
    static let API_offline = 7001
    
    struct UserErrorCode {
        static let userNameExsit = 12011
        static let currentWrong = 12021
        static let newNotMatch = 12022
        static let pwdUpdateFailed = 12023
        static let pwdEmpty = 12024
    }
    
    struct SendErrorCode {
        static let draftBad = 70
    }
    
}

// localized
// extension NSError {
    
//     class func authCredentialExpired() -> NSError {
//         return apiServiceError(
//             code: APIErrorCode.AuthErrorCode.credentialExpired,
//             localizedDescription: NSLocalizedString("Token expired"),
//             localizedFailureReason: NSLocalizedString("The authentication token has expired."))
//     }
    
//     class func authCredentialInvalid() -> NSError {
//         return apiServiceError(
//             code: APIErrorCode.AuthErrorCode.credentialInvalid,
//             localizedDescription: NSLocalizedString("Invalid credential"),
//             localizedFailureReason: NSLocalizedString("The authentication credentials are invalid."))
//     }
    
//     class func authInvalidGrant() -> NSError {
//         return apiServiceError(
//             code: APIErrorCode.AuthErrorCode.invalidGrant,
//             localizedDescription: NSLocalizedString("Alert"),
//             localizedFailureReason: NSLocalizedString("Authentication Failed Wrong username or password"))
//     }
    
//     class func internetError() -> NSError {
//         return apiServiceError(
//             code: APIErrorCode.AuthErrorCode.networkIusse,
//             localizedDescription: NSLocalizedString("Alert"),
//             localizedFailureReason: NSLocalizedString("Unable to connect to the server"))
//     }
    
//     class func authUnableToParseToken() -> NSError {
//         return apiServiceError(
//             code: APIErrorCode.AuthErrorCode.unableToParseToken,
//             localizedDescription: NSLocalizedString("Unable to parse token"),
//             localizedFailureReason: NSLocalizedString("Unable to parse authentication token!"))
//     }
    
//     class func authCacheBad() -> NSError {
//         return apiServiceError(
//             code: APIErrorCode.AuthErrorCode.localCacheBad,
//             localizedDescription: NSLocalizedString("Unable to parse token"),
//             localizedFailureReason: NSLocalizedString("Unable to parse authentication token!"))
//     }
// }


//localized
extension NSError {
    
    class func userNameTaken() -> NSError {
        return apiServiceError(
            code: APIErrorCode.UserErrorCode.userNameExsit,
            localizedDescription: NSLocalizedString("Invalid UserName", comment: "Error"),
            localizedFailureReason: NSLocalizedString("The UserName have been taken.", comment: "Error Description"))
    }
}


// MARK: - NSError APIService extension

//localized
extension NSError {
    
    class func apiServiceError(code: Int, localizedDescription: String, localizedFailureReason: String?, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(
            domain: APIServiceErrorDomain,
            code: code,
            localizedDescription: localizedDescription,
            localizedFailureReason: localizedFailureReason,
            localizedRecoverySuggestion: localizedRecoverySuggestion)
    }
    
    class func badParameter(_ parameter: Any?) -> NSError {
        return apiServiceError(
            code: APIErrorCode.badParameter,
            localizedDescription: NSLocalizedString("Bad parameter", comment: "Description"),
            localizedFailureReason: String(format: NSLocalizedString("Bad parameter: %@", comment: "Description"), "\(parameter)"))
    }
    
    class func badPath(_ path: String) -> NSError {
        return apiServiceError(
            code: APIErrorCode.badPath,
            localizedDescription: NSLocalizedString("Bad path", comment: "Description"),
            localizedFailureReason: String(format: NSLocalizedString("Unable to construct a valid URL with the following path: %@", comment: "Description"), "\(path)"))
    }
    
    class func badResponse() -> NSError {
        return apiServiceError(
            code: APIErrorCode.badResponse,
            localizedDescription: NSLocalizedString("Bad response", comment: "Description"),
            localizedFailureReason: NSLocalizedString("Can't not find the value from the response body", comment: "Description"))
    }
    
    class func unableToParseResponse(_ response: Any?) -> NSError {
        let noObject = NSLocalizedString("<no object>", comment: "no object error, local only , this could be not translated!")
        return apiServiceError(
            code: APIErrorCode.unableToParseResponse,
            localizedDescription: NSLocalizedString("Unable to parse response", comment: "Description"),
            localizedFailureReason: String(format: NSLocalizedString("Unable to parse the response object:\n%@", comment: "Description"), "\(response ?? noObject)"))
    }
}

