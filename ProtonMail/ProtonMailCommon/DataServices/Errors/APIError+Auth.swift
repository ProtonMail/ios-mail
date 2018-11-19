//
//  APIError+Auth.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/22/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation



extension NSError {
    
    class func authCredentialInvalid() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.credentialInvalid,
            localizedDescription: LocalString._invalid_credential,
            localizedFailureReason: LocalString._the_authentication_credentials_are_invalid)
    }
    
    class func authInvalidGrant() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.invalidGrant,
            localizedDescription: LocalString._general_alert_title,
            localizedFailureReason: LocalString._authentication_failed_wrong_username_or_password)
    }
    
    class func internetError() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.networkIusse,
            localizedDescription: LocalString._general_alert_title,
            localizedFailureReason: LocalString._unable_to_connect_to_the_server)
    }
    
    class func authUnableToParseToken() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.unableToParseToken,
            localizedDescription: LocalString._unable_to_parse_token,
            localizedFailureReason: LocalString._unable_to_parse_authentication_token)
    }
    
    class func authUnableToParseAuthInfo() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.unableToParseAuthInfo,
            localizedDescription: LocalString._unable_to_parse_token,
            localizedFailureReason: LocalString._unable_to_parse_authentication_info)
    }
    
    class func authUnableToGeneratePwd() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.authUnableToGeneratePwd,
            localizedDescription: LocalString._invalid_password,
            localizedFailureReason: LocalString._unable_to_generate_hash_password)
    }
    
    class func authUnableToGenerateSRP() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.authUnableToGenerateSRP,
            localizedDescription: LocalString._srp_client,
            localizedFailureReason: LocalString._unable_to_create_srp_client)
    }
    
    class func authServerSRPInValid() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.unableToParseAuthInfo,
            localizedDescription: LocalString._srp_server,
            localizedFailureReason: LocalString._server_proofs_not_valid)
    }
    
    class func authInValidKeySalt() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.authInValidKeySalt,
            localizedDescription: LocalString._invalid_password,
            localizedFailureReason: LocalString._srp_single_password_keyslat_invalid)
    }
    
    class func authCacheBad() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.localCacheBad,
            localizedDescription: LocalString._unable_to_parse_token,
            localizedFailureReason: LocalString._unable_to_parse_cased_authentication_token)
    }
    
    class func authCacheLocked() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.authCacheLocked,
            localizedDescription: LocalString._app_is_locked,
            localizedFailureReason: LocalString._authentication_token_is_locked)
    }
    
    class func AuthCachePassEmpty() -> NSError {
        return apiServiceError(
            code: APIErrorCode.AuthErrorCode.Cache_PasswordEmpty,
            localizedDescription: LocalString._bad_auth_cache,
            localizedFailureReason: LocalString._local_cache_cant_find_mailbox_password)
    }
}
