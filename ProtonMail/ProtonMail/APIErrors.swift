//
//  APIErrors.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/20/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

public class APIErrorCode {
    static public let responseOK = 1000
    
    static public let HTTP503 = 503
    static public let HTTP504 = 504
    
    static public let badParameter = 1
    static public let badPath = 2
    static public let unableToParseResponse = 3
    static public let badResponse = 4
    
    public struct AuthErrorCode {
        static public let credentialExpired = 10
        static public let credentialInvalid = 20
        static public let invalidGrant = 30
        static public let unableToParseToken = 40
        static public let localCacheBad = 50
        static public let networkIusse = 60
        static public let unableToParseAuthInfo = 70
        static public let authServerSRPInValid = 80
        static public let authUnableToGenerateSRP = 90
        static public let authUnableToGeneratePwd = 100
        static public let authInValidKeySalt = 110
        
        static public let Cache_PasswordEmpty = 0x10000001
    }
    
    static public let API_offline = 7001
    
    public struct UserErrorCode {
        static public let userNameExsit = 12011
        static public let currentWrong = 12021
        static public let newNotMatch = 12022
        static public let pwdUpdateFailed = 12023
        static public let pwdEmpty = 12024
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
    
    public class func apiServiceError(code: Int, localizedDescription: String, localizedFailureReason: String?, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(
            domain: APIServiceErrorDomain,
            code: code,
            localizedDescription: localizedDescription,
            localizedFailureReason: localizedFailureReason,
            localizedRecoverySuggestion: localizedRecoverySuggestion)
    }
    
    public class func badParameter(_ parameter: Any?) -> NSError {
        return apiServiceError(
            code: APIErrorCode.badParameter,
            localizedDescription: NSLocalizedString("Bad parameter", comment: "Description"),
            localizedFailureReason: String(format: NSLocalizedString("Bad parameter: %@", comment: "Description"), "\(String(describing: parameter))"))
    }
    
    public class func badPath(_ path: String) -> NSError {
        return apiServiceError(
            code: APIErrorCode.badPath,
            localizedDescription: NSLocalizedString("Bad path", comment: "Description"),
            localizedFailureReason: String(format: NSLocalizedString("Unable to construct a valid URL with the following path: %@", comment: "Description"), "\(path)"))
    }
    
    public class func badResponse() -> NSError {
        return apiServiceError(
            code: APIErrorCode.badResponse,
            localizedDescription: NSLocalizedString("Bad response", comment: "Description"),
            localizedFailureReason: NSLocalizedString("Can't not find the value from the response body", comment: "Description"))
    }
    
    public class func unableToParseResponse(_ response: Any?) -> NSError {
        let noObject = NSLocalizedString("<no object>", comment: "no object error, local only , this could be not translated!")
        return apiServiceError(
            code: APIErrorCode.unableToParseResponse,
            localizedDescription: NSLocalizedString("Unable to parse response", comment: "Description"),
            localizedFailureReason: String(format: NSLocalizedString("Unable to parse the response object:\n%@", comment: "Description"), "\(response ?? noObject)"))
    }
}

