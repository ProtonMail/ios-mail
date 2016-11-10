//
//  APIError+Auth.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/22/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation



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
            localizedDescription: NSLocalizedString("Alert"),
            localizedFailureReason: NSLocalizedString("Authentication Failed Wrong username or password"))
    }
    
    class func internetError() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.networkIusse,
            localizedDescription: NSLocalizedString("Alert"),
            localizedFailureReason: NSLocalizedString("Unable to connect to the server"))
    }
    
    class func authUnableToParseToken() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.unableToParseToken,
            localizedDescription: NSLocalizedString("Unable to parse token"),
            localizedFailureReason: NSLocalizedString("Unable to parse authentication token!"))
    }
    
    class func authUnableToParseAuthInfo() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.unableToParseAuthInfo,
            localizedDescription: NSLocalizedString("Unable to parse token"),
            localizedFailureReason: NSLocalizedString("Unable to parse authentication info!"))
    }
    
    class func authUnableToGeneratePwd() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.authUnableToGeneratePwd,
            localizedDescription: NSLocalizedString("Invalid Password"),
            localizedFailureReason: NSLocalizedString("Unable to generate hash password!"))
    }
    
    class func authUnableToGenerateSRP() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.authUnableToGenerateSRP,
            localizedDescription: NSLocalizedString("SRP Client"),
            localizedFailureReason: NSLocalizedString("Unable to create SRP Client!"))
    }
    
    class func authServerSRPInValid() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.unableToParseAuthInfo,
            localizedDescription: NSLocalizedString("SRP Server"),
            localizedFailureReason: NSLocalizedString("Server proofs not valid!"))
    }
    
    class func authInValidKeySalt() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.authInValidKeySalt,
            localizedDescription: NSLocalizedString("Invalid Password"),
            localizedFailureReason: NSLocalizedString("Srp single password keyslat invalid!"))
    }
    
    class func authCacheBad() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.localCacheBad,
            localizedDescription: NSLocalizedString("Unable to parse token"),
            localizedFailureReason: NSLocalizedString("Unable to parse cased authentication token!"))
    }
    
    
    class func AuthCachePassEmpty() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.Cache_PasswordEmpty,
            localizedDescription: NSLocalizedString("Bad auth cache"),
            localizedFailureReason: NSLocalizedString("Local cache can't find mailbox password"))
    }
}
