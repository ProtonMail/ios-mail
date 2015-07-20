//
//  APIErrors.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/20/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

class APIErrorCode {
    static let ResponseOK = 1000
    
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
