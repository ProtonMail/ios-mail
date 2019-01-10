//
//  APIError+Auth.swift
//  ProtonMail - Created on 8/22/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
