//
//  APIService+AuthenticationExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

/// Auth extension
extension APIService {
    typealias AuthCredentialBlock = (AuthCredential?, NSError?) -> Void
    typealias AuthInfo = (accessToken: String?, expiresId: NSTimeInterval?, refreshToken: String?, userID: String?)
    
    struct AuthErrorCode {
        static let credentialExpired = 10
        static let credentialInvalid = 20
        static let invalidGrant = 30
        static let unableToParseToken = 40
        static let localCacheBad = 50
    }
    
    struct APIServicePath
    {
        //need path and version
    }
    
    struct Constants {
        // FIXME: These values would be obtainable by inspecting the binary code, but to make thins a little more difficult, we probably don't want to these values visible when the source code is distributed.  We will probably want to come up with a way to pass in these values as pre-compiler macros.  Swift doesn't support pre-compiler macros, but we have Objective-C and can still use them.  The values would be passed in by the build scripts at build time.  Or, these values could be cleared before publishing the code.
        static let clientID = "demoapp"
        static let clientSecret = "demopass"
        static let rediectURL = "https://protonmail.ch"
    }
    
    struct GeneralResponse {
        static let errorCode = "Code"
        static let errorMsg = "Error"
        static let errorDesc = "ErrorDescription"
    }
    
    //TODO:: need refacotr the api request structures
    struct AuthRequest {
        static let clientID = "ClientID"
        static let clientSecret = "ClientSecret"
        static let responseType = "ResponseType"
        static let userName = "Username"
        static let password = "Password"
        static let hashedPassword = "HashedPassword"
        static let grantType = "GrantType"
        static let redirectUrl = "RedirectURI"
        static let state = "State"
    }
    
    
    func authAuth(#username: String, password: String, completion: AuthCredentialBlock?) {
        let path = "/auth" + AppConstants.getDebugOption
        let parameters = [
            AuthRequest.clientID : Constants.clientID,
            AuthRequest.clientSecret : Constants.clientSecret,
            AuthRequest.responseType : "token",
            AuthRequest.userName : username,
            AuthRequest.password : password,
            AuthRequest.hashedPassword : "",
            AuthRequest.grantType : "password",
            AuthRequest.redirectUrl : Constants.rediectURL,
            AuthRequest.state : "\(NSUUID().UUIDString)"]
        
        let completionWrapper: CompletionBlock = { task, response, error in
            if self.isErrorResponse(response) {
                completion?(nil, NSError.authInvalidGrant())
            } else if let authInfo = self.authInfoForResponse(response) {
                let credential = AuthCredential(authInfo: authInfo)
                credential.storeInKeychain()
                completion?(credential, nil)
            } else if error == nil {
                completion?(nil, NSError.authUnableToParseToken())
            } else {
                completion?(nil, NSError.unableToParseResponse(response))
            }
        }
        request(method: .POST, path: path, parameters: parameters, authenticated: false, completion: completionWrapper)
    }
    
    func userCreate(user_name: String, pwd: String, email: String, receive_news: Bool, completion: AuthCredentialBlock?) {
        let path = "/users" + AppConstants.getDebugOption
        let parameters = [
            "client_id" : Constants.clientID,
            "client_secret" : Constants.clientSecret,
            "response_type" : "token",
            "grant_type" : "password",
            "redirect_uri" : "https://protonmail.ch",
            "state" : "\(NSUUID().UUIDString)",
            
            "username" : user_name,
            "password" : pwd,
            "email":email,
            "news":receive_news
        ]
        
        let completionWrapper: CompletionBlock = { task, response, error in
            if self.isErrorResponse(response) {
                completion?(nil, NSError.authInvalidGrant())
            } else if let authInfo = self.authInfoForResponse(response) {
                let credential = AuthCredential(authInfo: authInfo)
                
                credential.storeInKeychain()
                
                completion?(credential, nil)
            } else if error == nil {
                completion?(nil, NSError.authUnableToParseToken())
            } else {
                completion?(nil, NSError.unableToParseResponse(response))
            }
        }
        request(method: .POST, path: path, parameters: parameters, authenticated: false, completion: completionWrapper)
    }
    
    func authRevoke(completion: AuthCredentialBlock?) {
        if let authCredential = AuthCredential.fetchFromKeychain() {
            let path = "/auth/revoke"
            let parameters = ["access_token" : authCredential.accessToken]
            let completionWrapper: CompletionBlock = { _, _, error in
                completion?(nil, error)
                return
            }
            request(method: .POST, path: path, parameters: parameters, completion: completionWrapper)
        } else {
            completion?(nil, nil)
        }
    }

    func authRefresh(completion: AuthCredentialBlock?) {
        if let authCredential = AuthCredential.fetchFromKeychain() {
            let path = "/auth/refresh"
            
            let parameters = [
                "ClientID": Constants.clientID,
                "ResponseType": "token",
                "access_token": authCredential.accessToken,
                "RefreshToken": authCredential.refreshToken,
                "GrantType": "refresh_token"]
            
            let completionWrapper: CompletionBlock = { task, response, error in
                if let authInfo = self.authInfoForResponse(response) {
                    let credential = AuthCredential(authInfo: authInfo)
                    
                    credential.storeInKeychain()
                    
                    completion?(credential, nil)
                } else if self.isErrorResponse(response) {
                    completion?(nil, NSError.authInvalidGrant())
                } else if error == nil {
                    completion?(nil, NSError.authUnableToParseToken())
                } else {
                    completion?(nil, NSError.unableToParseResponse(response))
                }
            }
            
            if authCredential.accessToken == nil || authCredential.refreshToken == nil {
                completion?(nil, NSError.authCacheBad())
            }
            else
            {
                
                request(method: .POST, path: path, parameters: parameters, authenticated: false, completion: completionWrapper)
            }
        } else {
            completion?(nil, NSError.authCredentialInvalid())
        }
    }
    
    // MARK: - Private methods
    
    private func isErrorResponse(response: AnyObject!) -> Bool {
        if let dict = response as? NSDictionary {
            //TODO:: check Code == 1000 or now
            return dict[GeneralResponse.errorMsg] != nil
        }
        return false
    }
    
    private func authInfoForResponse(response: AnyObject!) -> AuthInfo? {
        if let response = response as? Dictionary<String,AnyObject> {
            let accessToken = response["AccessToken"] as? String
            let expiresIn = response["ExpiresIn"] as? NSTimeInterval
            let refreshToken = response["RefreshToken"] as? String
            let userID = response["Uid"] as? String
            
            let eventID = response["EventID"] as? String ?? ""
            
            lastUpdatedStore.lastEventID = eventID
            return (accessToken, expiresIn, refreshToken, userID)
        }
        return nil
    }
}

extension AuthCredential {
    convenience init(authInfo: APIService.AuthInfo) {
        let expiration = NSDate(timeIntervalSinceNow: (authInfo.expiresId ?? 0))
        
        self.init(accessToken: authInfo.accessToken, refreshToken: authInfo.refreshToken, userID: authInfo.userID, expiration: expiration)
    }
}


extension NSError {
    
    class func authCredentialExpired() -> NSError {
        return apiServiceError(
            code: APIService.AuthErrorCode.credentialExpired,
            localizedDescription: NSLocalizedString("Token expired"),
            localizedFailureReason: NSLocalizedString("The authentication token has expired."))
    }
    
    class func authCredentialInvalid() -> NSError {
        return apiServiceError(
            code: APIService.AuthErrorCode.credentialInvalid,
            localizedDescription: NSLocalizedString("Invalid credential"),
            localizedFailureReason: NSLocalizedString("The authentication credentials are invalid."))
    }
    
    class func authInvalidGrant() -> NSError {
        return apiServiceError(
            code: APIService.AuthErrorCode.invalidGrant,
            localizedDescription: NSLocalizedString("Invalid grant"),
            localizedFailureReason: NSLocalizedString("The supplied credentials are invalid."))
    }
    
    class func authUnableToParseToken() -> NSError {
        return apiServiceError(
            code: APIService.AuthErrorCode.unableToParseToken,
            localizedDescription: NSLocalizedString("Unable to parse token"),
            localizedFailureReason: NSLocalizedString("Unable to parse authentication token!"))
    }
    
    class func authCacheBad() -> NSError {
        return apiServiceError(
            code: APIService.AuthErrorCode.localCacheBad,
            localizedDescription: NSLocalizedString("Unable to parse token"),
            localizedFailureReason: NSLocalizedString("Unable to parse authentication token!"))
    }
}
