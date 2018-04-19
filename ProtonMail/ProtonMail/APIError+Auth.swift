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
            localizedDescription: NSLocalizedString("Token expired", comment: "Error"),
            localizedFailureReason: NSLocalizedString("The authentication token has expired.", comment: "Description"))
    }
    
    class func authCredentialInvalid() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.credentialInvalid,
            localizedDescription: NSLocalizedString("Invalid credential", comment: "Error"),
            localizedFailureReason: NSLocalizedString("The authentication credentials are invalid.", comment: "Description"))
    }
    
    class func authInvalidGrant() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.invalidGrant,
            localizedDescription: LocalString._general_alert_title,
            localizedFailureReason: NSLocalizedString("Authentication Failed Wrong username or password", comment: "Description"))
    }
    
    class func internetError() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.networkIusse,
            localizedDescription: LocalString._general_alert_title,
            localizedFailureReason: NSLocalizedString("Unable to connect to the server", comment: "Description"))
    }
    
    class func authUnableToParseToken() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.unableToParseToken,
            localizedDescription: NSLocalizedString("Unable to parse token", comment: "Error"),
            localizedFailureReason: NSLocalizedString("Unable to parse authentication token!", comment: "Description"))
    }
    
    class func authUnableToParseAuthInfo() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.unableToParseAuthInfo,
            localizedDescription: NSLocalizedString("Unable to parse token", comment: "Error"),
            localizedFailureReason: NSLocalizedString("Unable to parse authentication info!", comment: "Description"))
    }
    
    class func authUnableToGeneratePwd() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.authUnableToGeneratePwd,
            localizedDescription: NSLocalizedString("Invalid Password", comment: "Error"),
            localizedFailureReason: NSLocalizedString("Unable to generate hash password!", comment: "Description"))
    }
    
    class func authUnableToGenerateSRP() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.authUnableToGenerateSRP,
            localizedDescription: NSLocalizedString("SRP Client", comment: "Error"),
            localizedFailureReason: NSLocalizedString("Unable to create SRP Client!", comment: "Description"))
    }
    
    class func authServerSRPInValid() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.unableToParseAuthInfo,
            localizedDescription: NSLocalizedString("SRP Server", comment: "Error"),
            localizedFailureReason: NSLocalizedString("Server proofs not valid!", comment: "Description"))
    }
    
    class func authInValidKeySalt() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.authInValidKeySalt,
            localizedDescription: NSLocalizedString("Invalid Password", comment: "Error"),
            localizedFailureReason: NSLocalizedString("Srp single password keyslat invalid!", comment: "Description"))
    }
    
    class func authCacheBad() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.localCacheBad,
            localizedDescription: NSLocalizedString("Unable to parse token", comment: "Error"),
            localizedFailureReason: NSLocalizedString("Unable to parse cased authentication token!", comment: "Description"))
    }
    
    
    class func AuthCachePassEmpty() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.Cache_PasswordEmpty,
            localizedDescription: NSLocalizedString("Bad auth cache", comment: "Error"),
            localizedFailureReason: NSLocalizedString("Local cache can't find mailbox password", comment: "Description"))
    }
}
