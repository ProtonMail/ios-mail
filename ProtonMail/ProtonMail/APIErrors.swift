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
    }
    
    struct UserErrorCode {
        static let userNameExsit = 12011
        static let currentWrong = 12021
        static let newNotMatch = 12022
        static let pwdUpdateFailed = 12023
        static let pwdEmpty = 12024
    }
    
    struct ErrorCode {

    }
}



extension NSError {
    
    class func authCredentialExpired() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.credentialExpired,
            localizedDescription: NSLocalizedString("Token expired"),
            localizedFailureReason: NSLocalizedString("The authentication token has expired."))
    }
    
    class func authCredentialInvalid() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.credentialInvalid,
            localizedDescription: NSLocalizedString("Invalid credential"),
            localizedFailureReason: NSLocalizedString("The authentication credentials are invalid."))
    }
    
    class func authInvalidGrant() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.invalidGrant,
            localizedDescription: NSLocalizedString("Invalid grant"),
            localizedFailureReason: NSLocalizedString("The supplied credentials are invalid."))
    }
    
    class func authUnableToParseToken() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.unableToParseToken,
            localizedDescription: NSLocalizedString("Unable to parse token"),
            localizedFailureReason: NSLocalizedString("Unable to parse authentication token!"))
    }
    
    class func authCacheBad() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.localCacheBad,
            localizedDescription: NSLocalizedString("Unable to parse token"),
            localizedFailureReason: NSLocalizedString("Unable to parse authentication token!"))
    }
}



extension NSError {
    
    class func userNameTaken() -> NSError {
        return apiServiceError(
            code: APIErrorCode.UserErrorCode.userNameExsit,
            localizedDescription: NSLocalizedString("Invalid UserName"),
            localizedFailureReason: NSLocalizedString("The UserName have been taken."))
    }
    
    class func currentPwdWrong() -> NSError {
        return apiServiceError(
            code: APIErrorCode.UserErrorCode.currentWrong,
            localizedDescription: NSLocalizedString("Change Password"),
            localizedFailureReason: NSLocalizedString("The Password is wrong."))
    }
    
    class func newNotMatch() -> NSError {
        return apiServiceError(
            code: APIErrorCode.UserErrorCode.newNotMatch,
            localizedDescription: NSLocalizedString("Change Password"),
            localizedFailureReason: NSLocalizedString("The new password not match"))
    }
    
    class func pwdCantEmpty() -> NSError {
        return apiServiceError(
            code: APIErrorCode.UserErrorCode.pwdEmpty,
            localizedDescription: NSLocalizedString("Change Password"),
            localizedFailureReason: NSLocalizedString("The new password can't empty"))
    }
}


// MARK: - NSError APIService extension

extension NSError {
    
    class func apiServiceError(#code: Int, localizedDescription: String, localizedFailureReason: String?, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(
            domain: APIServiceErrorDomain,
            code: code,
            localizedDescription: localizedDescription,
            localizedFailureReason: localizedFailureReason,
            localizedRecoverySuggestion: localizedRecoverySuggestion)
    }
    
    class func badParameter(parameter: AnyObject?) -> NSError {
        return apiServiceError(
            code: APIErrorCode.badParameter,
            localizedDescription: NSLocalizedString("Bad parameter"),
            localizedFailureReason: NSLocalizedString("Bad parameter: \(parameter)"))
    }
    
    class func badPath(path: String) -> NSError {
        return apiServiceError(
            code: APIErrorCode.badPath,
            localizedDescription: NSLocalizedString("Bad path"),
            localizedFailureReason: NSLocalizedString("Unable to construct a valid URL with the following path: \(path)"))
    }
    
    class func badResponse() -> NSError {
        return apiServiceError(
            code: APIErrorCode.badResponse,
            localizedDescription: NSLocalizedString("Bad response"),
            localizedFailureReason: NSLocalizedString("Can't not find the value from the response body"))
    }
    
    class func unableToParseResponse(response: AnyObject?) -> NSError {
        let noObject = NSLocalizedString("<no object>")
        
        return apiServiceError(
            code: APIErrorCode.unableToParseResponse,
            localizedDescription: NSLocalizedString("Unable to parse response"),
            localizedFailureReason: NSLocalizedString("Unable to parse the response object:\n\(response ?? noObject)"))
    }
}

