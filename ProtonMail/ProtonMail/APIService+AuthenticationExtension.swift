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
import Fabric
import Crashlytics


/// Auth extension
extension APIService {

    
    func auth(username: String, password: String, completion: AuthComplete?) {
        AuthRequest<AuthResponse>(username: username, password: password).call() { task, res, hasError in
            if hasError {
                if let error = res?.error {
                    if error.isInternetError() {
                        completion?(task: task, hasError: NSError.internetError())
                        return
                    } else {
                        if let detail = error.userInfo["com.alamofire.serialization.response.error.response"] as? NSHTTPURLResponse {
                            let code = detail.statusCode
                            if code != 200 {
                                completion?(task: task, hasError: error)
                                return
                            }
                        }
                    }
                }
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
        }
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
    func authRefresh(password:String, completion: AuthRefreshComplete?) {
        if let authCredential = AuthCredential.fetchFromKeychain() {
            AuthRefreshRequest<AuthResponse>(resfresh: authCredential.refreshToken).call() { task, res , hasError in
                if hasError {
                    
                    self.refreshTokenFailedCount += 1
                    
                    Answers.logCustomEventWithName("AuthRefreshRequest-Error",
                        customAttributes: [
                            "name": sharedUserDataService.username ?? "unknow",
                            "error": "\(res?.error)"])
                    
                    
                    if self.refreshTokenFailedCount > 10 {
                        PMLog.D("self.refreshTokenFailedCount == 10")
                    }
                    
                    completion?(task: task, auth: nil, hasError: NSError.authInvalidGrant())
                }
                else if res?.code == 1000 {
                    do {
                        authCredential.update(res)
                        try authCredential.setupToken(password)
                        authCredential.storeInKeychain()
                        
                        PMLog.D("\(authCredential.description)")
                        
                        self.refreshTokenFailedCount = 0
                    } catch let ex as NSError {
                        PMLog.D(ex)
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        completion?(task: task, auth: authCredential, hasError: nil)
                    }
                }
                else {
                    completion?(task: task, auth: nil, hasError: NSError.authUnableToParseToken())
                }
            }
        } else {
            completion?(task: nil, auth: nil, hasError: NSError.authCredentialInvalid())
        }
        
    }
}

extension AuthCredential {
    convenience init(authInfo: APIService.AuthInfo) {
        let expiration = NSDate(timeIntervalSinceNow: (authInfo.expiresId ?? 0))
        
        self.init(accessToken: authInfo.accessToken, refreshToken: authInfo.refreshToken, userID: authInfo.userID, expiration: expiration, key : "", plain: authInfo.accessToken, pwd: "")
    }
}

