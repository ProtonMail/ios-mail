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
    
    
    typealias AuthComplete = (task: NSURLSessionDataTask?, hasError : NSError?) -> Void
    
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
    
    struct GeneralResponse {
        static let errorCode = "Code"
        static let errorMsg = "Error"
        static let errorDesc = "ErrorDescription"
    }
    
    
    
    func auth(username: String, password: String, completion: AuthComplete?) {
        AuthRequest<AuthResponse>(username: username, password: password).call() { task, res , hasError in
            if hasError {
                completion?(task: task, hasError: NSError.authInvalidGrant())
            }
            else if res?.code == 1000 {
                let credential = AuthCredential(res: res)
                credential.storeInKeychain()
                completion?(task: task, hasError: nil)
            }
            else {
                completion?(task: task, hasError: NSError.authUnableToParseToken())
            }
            //            if self.isErrorResponse(response) {
            //
            //            } else if let authInfo = self.authInfoForResponse(response) {
            //
            //            } else if error == nil {
            //                completion?(nil, NSError.authUnableToParseToken())
            //            } else {
            //                completion?(nil, NSError.unableToParseResponse(response))
            //            }
        }
        
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
            let parameters = ["access_token" : authCredential.token ?? ""]
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
                "access_token": authCredential.token,
                "RefreshToken": authCredential.refreshToken,
                "GrantType": "refresh_token",
                "Scope": "full"]
            
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
            
            if authCredential.token == nil || authCredential.refreshToken == nil {
                completion?(nil, NSError.authCacheBad())
            }
            else
            {
                setApiVesion(1, appVersion: 1)
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
        
        self.init(accessToken: authInfo.accessToken, refreshToken: authInfo.refreshToken, userID: authInfo.userID, expiration: expiration, key : "", plain: authInfo.accessToken)
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
